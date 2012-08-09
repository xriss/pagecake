--[[
local json=require("wetgenes.json")

local wet_html=require("wetgenes.html")

local dat=require("wetgenes.www.any.data")
local cache=require("wetgenes.www.any.cache")

local users=require("wetgenes.www.any.users")

local img=require("wetgenes.www.any.img")

local log=require("wetgenes.www.any.log").log -- grab the func from the package

local wet_string=require("wetgenes.string")
local str_split=wet_string.str_split
local serialize=wet_string.serialize


-- require all the module sub parts
local html  =require("hoe.html")
local rounds=require("hoe.rounds")
local players=require("hoe.players")
local acts=require("hoe.acts")



local os=os
local math=math
local string=string
local table=table

local ipairs=ipairs
local pairs=pairs
local tostring=tostring
local tonumber=tonumber
local type=type

-- manage trades

-- players can offer up trades, at which point their assets are removed from play
-- then any other player can play the price at which point they get the asset
-- and the original player gets the price they asked for
-- in order to stop transfers, you are not allowed to buy anything but the cheapest deal.
-- This means that you may not choose to pay a few million bux for one hoe sold by a friend
-- you can offer 100hoes for one bux, but the deal will be first come first served
-- anyone can take it and probably will

module("hoe.trades")

--------------------------------------------------------------------------------
--
-- serving flavour can be used to create a subgame of a differnt flavour
-- make sure we incorporate flavour into the name of our stored data types
--
--------------------------------------------------------------------------------
function kind(H)
	if not H.srv.flavour or H.srv.flavour=="hoe" then return "hoe.trade" end
	return H.srv.flavour..".hoe.trade"
end

--------------------------------------------------------------------------------
--
-- Create a new local offer in H.round filled with initial data
--
--------------------------------------------------------------------------------
function create(H)

	local ent={}
	
	ent.key={kind=kind(H)} -- we will not know the key id until after we save
	ent.props={}
	
	local p=ent.props
	
	p.round_id=H.round.key.id
	
	p.created=H.srv.time
	p.updated=H.srv.time
	
	p.player=0 -- the id of the player making this offer
	p.buyer=0 -- the id of the player who bought this, or 0 if not bought yet
		
	--offering
	p.offer="hoes"	-- the item being offerd
	p.count=0		-- the number(integer) of items offered (may not be 0)
	
	--seeking
	p.seek="bux"	-- the item wanted in payment
	p.cost=0		-- the number(integer) of items needed per single item (may not be 0)
	
	p.price=0		-- this is the full price which is count*cost or count/cost
	
	dat.build_cache(ent) -- this just copies the props across
	
-- these are json only vars
	local c=ent.cache

	return check(H,ent)
end

--------------------------------------------------------------------------------
--
-- check that a trade has initial data and set any missing defaults
-- the second return value is false if this is not a valid entity
--
--------------------------------------------------------------------------------
function check(H,ent)

	local ok=true

	local r=H.round.cache
	local c=ent.cache
	
-- how long to sit in limbo for?

	c.limbo=c.limbo or math.random( 2*12*H.round.cache.timestep , 24*12*H.round.cache.timestep ) 
	

-- check?
	if c.price<=0 then ok=false end
	if c.count<=0 then ok=false end
	if c.cost <=0 then ok=false end
	
	return ok and ent
end

--------------------------------------------------------------------------------
--
-- Save a trade to database
--
-- update the cache, this will copy it into props
--
--------------------------------------------------------------------------------
function put(H,ent,t)

	t=t or dat -- use transaction?

	local _,ok=check(H,ent) -- check that this is valid to put
	if not ok then return nil end

	dat.build_props(ent)
	local ks=t.put(ent)
	
	if ks then
		ent.key=dat.keyinfo( ks ) -- update key with new id
		dat.build_cache(ent)
	end

	return ks -- return the keystring which is an absolute name
end


--------------------------------------------------------------------------------
--
-- Load a trade from database, pass in id or entity
-- the props will be copied into the cache
--
--------------------------------------------------------------------------------
function get(H,id,t)

	local ent=id
	
	if type(ent)~="table" then -- get by id
		ent=create(H)
		ent.key.id=id
	end
	
	t=t or dat -- use transaction?
	
	if not t.get(ent) then return nil end	
	dat.build_cache(ent)
	
	return check(H,ent)
end

--------------------------------------------------------------------------------
--
-- change a trade by a table, each value present is set
--
--------------------------------------------------------------------------------
function update_set(H,id,by)

	local f=function(H,p)
		for i,v in pairs(by) do
			p[i]=v
		end
		return true
	end		
	return update(H,id,f)	
end

--------------------------------------------------------------------------------
--
-- get - update - put
--
-- f must be a function that changes the trade.cache and returns true on success
-- id can be an id or an entity from which we will get the id
--
--------------------------------------------------------------------------------
function update(H,id,f)

	if type(id)=="table" then id=id.key.id end -- can turn an entity into an id
		
	for retry=1,10 do
		local mc={}
		local t=dat.begin()
		local e=get(H,id,t)
		if e then
			what_memcache(H,e,mc) -- the original values
			if not f(H,e.cache) then t.rollback() return false end -- hard fail
			check(H,e) -- keep consistant
			if put(H,e,t) then -- entity put ok
				if t.commit() then -- success
					what_memcache(H,e,mc) -- the new values
					fix_memcache(H,mc) -- change any memcached values we just adjusted
					return e -- return the adjusted entity
				end
			end
		end
		t.rollback() -- undo everything ready to try again
	end
	
end


--------------------------------------------------------------------------------
--
-- given an entity return or update a list of cache keys we should recalculate
-- this list is a name->bool lookup
--
--------------------------------------------------------------------------------
function what_memcache(H,ent,mc)

	local mc=mc or {} -- can supply your own result table for merges
	
	local c=ent.cache
	
	local sb="kind="..kind(H).."&round="..(H.round.key.id).."&find=cheapest&offer="..c.offer.."&seek="..c.seek
	mc[ sb.."&reverse=false" ] =true
	mc[ sb.."&reverse=true" ] =true

	return mc
end

--------------------------------------------------------------------------------
--
-- fix the memcache items previously produced by what_memcache
-- probably best just to delete them so they will automatically get rebuilt
--
--------------------------------------------------------------------------------
function fix_memcache(H,mc)

	for n,b in pairs(mc) do
		cache.del(srv,n)
	end
end

--------------------------------------------------------------------------------
--
-- find the best trade, given these options
--
-- you may only buy the best trade and its a first in first out 
-- so this will take a few couple of querys to get back a single entity
--
--------------------------------------------------------------------------------
function find_cheapest(H,opts,t)
local reverse=false
	opts=opts or {} -- stop opts from being nil
	if not ( opts.offer and opts.seek ) then return nil end -- really need these opts
	
	if type(opts.reverse)=="string" then -- this could be a string rather than a bool
		if opts.reverse=="true" then reverse=true end
	else
		reverse=opts.reverse
	end

	-- a unique keyname for this query
	local cachekey="kind="..kind(H).."&round="..(H.round.key.id).."&find=cheapest&offer="..opts.offer.."&seek="..opts.seek.."&reverse="..(reverse and "true" or "false")
	
	local r=cache.get(H.srv,cachekey) -- do we already know the answer?

	if not r then -- get the answer
	
		t=t or dat -- transactions shouldnt be used anyhow?
		
		local q={
			kind=kind(H),
			limit=1,
			offset=0,
				{"filter","round_id","==",H.round.key.id},
				{"filter","buyer","==",0}, -- must be available to buy
				{"filter","offer","==",opts.offer},
				{"filter","seek","==",opts.seek},
			}
		
		if reverse then
				q[#q+1]={"sort","cost","DESC"} -- we want the most expensive
--				q[#q+1]={"sort","count","ASC"} -- then we want the smallest amount
				q[#q+1]={"sort","count","DESC"} -- then we want the largest quantity
--				q[#q+1]={"sort","created","ASC"} -- and we want the oldest so FIFO	
				q[#q+1]={"sort","created","DESC"} -- then we want the newest, to make it easy to cockblock
		else
				q[#q+1]={"sort","cost","ASC"} -- we want the cheapest
--				q[#q+1]={"sort","count","ASC"} -- then we want the smallest amount
				q[#q+1]={"sort","count","DESC"} -- then we want the largest quantity
--				q[#q+1]={"sort","created","ASC"} -- and we want the oldest so FIFO	
				q[#q+1]={"sort","created","DESC"} -- then we want the newest, to make it easy to cockblock
		end
			
			
		r=t.query(q)
		cache.put(H.srv,cachekey,r,1*60) -- save this (possibly random) result for 1 min
	
	end
	
	local best=r.list[1]

	if best then
		dat.build_cache(best)
	end
	
	return best
end

--------------------------------------------------------------------------------
--
-- find the active trades, belonging to a user
--
--------------------------------------------------------------------------------
function find_mine(H,opts,t)
local reverse=false
	opts=opts or {} -- stop opts from being nil
	if not ( opts.player ) then return nil end -- really need these opts
		
	t=t or dat -- transactions shouldnt be used anyhow?
	
	local q={
		kind=kind(H),
		limit=1000, -- there are probably not 1000
		offset=0,
			{"filter","round_id","==",H.round.key.id},
			{"filter","player","==",opts.player},
		}
		
	if opts.active then
		q[#q+1]={"filter","buyer","==",0} -- available to buy?
	elseif opts.complete then
		q[#q+1]={"filter","buyer","!=",0} -- already bought?
	end
	
	local r=t.query(q)
	
	for i=1,#r.list do local v=r.list[i]
		dat.build_cache(v)
	end
	
	return r.list	
end


--------------------------------------------------------------------------------
--
-- check and satisfy or remove trades of the current round
--
--------------------------------------------------------------------------------
function pulse(H)
local valid_trades={
	{"houses","hoes",min=5,max=50,},
	{"hoes","bros",min=40,max=1000,},
	{"bros","bux",min=1000,max=10000,},
}

	for i,v in ipairs(valid_trades) do
		local best={}
		best[1]=find_cheapest(H,{offer=v[1],seek=v[2],reverse=false}) -- get the best trade
		best[2]=find_cheapest(H,{offer=v[2],seek=v[1],reverse=true}) -- get the best reverse trade
		
		H.srv.put("checking "..v[1].." for "..v[2].."\n")
		
		if best[1] then
			local c=best[1].cache
			H.srv.put(c.player.." is selling "..c.count.." for "..c.cost.."\n")
			local need=c.count
			if best[1]=="houses" then need=need+1 end -- must keep 1 house
			
			local p=players.get(H,c.player)
			
			if p.cache[ best[1].cache.offer ] < need then -- not enough?
				H.srv.put("canceling "..c.player.." trade due to lack of funds\n")
				update_set(H,best[1],{buyer=-1}) -- cancel it
				best[1]=nil
			end
			
		end
		if best[2] then
			local c=best[2].cache
			H.srv.put(c.player.." is buying "..(c.count/c.cost).." for "..c.cost.."\n")
			local need=c.count
			if best[2]=="houses" then need=need+1 end -- must keep 1 house

			local p=players.get(H,c.player)

			if p.cache[ best[2].cache.offer ] < need then -- not enough?
				H.srv.put("canceling "..c.player.." trade due to lack of funds\n")
				update_set(H,best[2],{buyer=-1}) -- cancel it
				best[2]=nil			
			end
			
		end
		
		
		local timeon=true -- are trades out of limbo?
		
		local twait=H.round.cache.tradewait

		if best[1] then
			if math.floor(os.time()-best[1].cache.created) < twait then
				timeon=false
			end
		end
		if best[2] then
			if math.floor(os.time()-best[2].cache.created) < twait then
				timeon=false
			end
		end
		
		
		if timeon and best[1] and best[2] then -- wealready checked that both parties have the goods so now we check if they will deal
			if best[1].cache.cost <= best[2].cache.cost then
			
				H.srv.put("performing deal\n")
				
				local count=best[1].cache.count -- start with number needed by trade 2
				local cost=math.floor( ( best[1].cache.cost + best[2].cache.cost ) / 2 ) -- we meet halfway on price
				local price=count*cost
				
-- work out how many we will actually exchange, it wil satisfy one of the trades, possibly both

				local count2=math.floor(best[2].cache.count/best[2].cache.cost) -- number needed by trade 2


				if count<count2 then --trade1 is satisfied, trade2 is just reduced

					H.srv.put("trade1 is satisfied, trade2 is just reduced\n")
				
					update_set(H,best[1],{buyer=best[2].cache.player , cost=cost , price = price , count=count })
					
					local up={}
					up.price= (count2-count)
					up.count= up.price*best[2].cache.cost
					update_set(H,best[2],up)
				
				elseif count2<count then --trade2 is satisfied, trade1 is just reduced
				
					H.srv.put("trade2 is satisfied, trade1 is just reduced\n")
					
					local up={}
					up.count=count-count2
					up.price=up.count*best[1].cache.cost
					update_set(H,best[1],up)
					
					update_set(H,best[2],{buyer=best[1].cache.player , cost=cost , count=price , price=count })


				else -- both trades are satisfied, one of them will get marked as a dupe/deleted ?

					H.srv.put("both trades are satisfied, one of them will get marked as a dupe/deleted\n")

					update_set(H,best[1],{buyer=best[2].cache.player , cost=cost , price=price , count=count })
					update_set(H,best[2],{buyer=-1}) -- cancel it

				end

-- update players stats by exchanging value

				local adjust={}
				adjust[ v[1] ]=-count;
				adjust[ v[2] ]=price;
				players.update_add(H,best[1].cache.player,adjust) -- exchange
				adjust[ v[1] ]=count;
				adjust[ v[2] ]=-price;
				players.update_add(H,best[2].cache.player,adjust) -- exchange
				
-- log the trade
				local seller=players.get(H,best[1].cache.player) -- get sellers name
				local buyer=players.get(H,best[2].cache.player) -- get buyers name

				acts.add_trade(H,{
					actor1 = seller.key.id ,
					name1  = seller.cache.name ,
					actor2 = buyer.key.id ,
					name2  = buyer.cache.name ,
					offer  = v[1],
					seek   = v[2],
					count  = count,
					cost   = cost,
					price  = price,
					})

			end
		end
	end
end

]]

