-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local wet_html=require("wetgenes.html")
local json=require("wetgenes.json")

local dat=require("wetgenes.www.any.data")

local users=require("wetgenes.www.any.users")

local img=require("wetgenes.www.any.img")

local log=require("wetgenes.www.any.log").log -- grab the func from the package

local wstr=require("wetgenes.string")
local wet_string=wstr
local str_split=wet_string.str_split
local serialize=wet_string.serialize


-- require all the module sub parts
local html  =require("hoe.html")


-- manage rounds
-- not only may there be many rounds active at once
-- information may still be requested about rounds that have finished

module("hoe.rounds")
local _M=require(...)

default_props=
{

}

default_cache=
{
}

--------------------------------------------------------------------------------
--
-- serving flavour can be used to create a subgame of a certain flavour
-- make sure we incorporate flavour into the name of our stored data types
--
--------------------------------------------------------------------------------
function kind(H)
	local H=srv and srv.H
	if not H then return "hoe.round" end
	if not H.srv.flavour or H.srv.flavour=="hoe" then return "hoe.round" end
	return H.srv.flavour..".hoe.round"
end

--------------------------------------------------------------------------------
--
-- Create a new round filled with initial default data
--
--------------------------------------------------------------------------------
--[[
function create(H)

	local ent={}
	
	ent.key={kind=kind(H)} -- we will not know the key id until after we save
	ent.props={}
		
	local p=ent.props
	
	p.created=H.srv.time
	p.updated=H.srv.time
	
	p.timestep=300 -- 60*10 -- a 10 minute tick, gives 144 ticks a day
	
	p.endtime=H.srv.time+(p.timestep*4032) -- default game end after about a month of standard ticks
	-- setting the tick to 1 second gets us the same amount of game time in about 1 hour
	
	p.max_energy=500	-- maximum amount of energy a player can have at once
						-- energy never, under any cirumstances goes over this number
	
	p.state="active" -- a new round starts as active
	
	p.players=0 -- number of players in this round
	
	dat.build_cache(ent) -- this just copies the props across
	
-- these are json only vars, which just means you cannot query them
	local c=ent.cache
	

	return check(H,ent)
end
]]
--------------------------------------------------------------------------------
--
-- check that a round has initial data and set any missing defaults
-- this function handles live updates to old data read from database
-- use the created or updated time stamp as version test if really necesary
-- but it is better to just look at what data is available rather than version test
--
--------------------------------------------------------------------------------
function check(srv,ent)
local H=srv.H

	local c=ent.cache
	
	if c.endtime<H.srv.time then -- round has ended
		if c.state~="over" then
			c.state="over"
		end
	end
	
	c.tradewait=math.floor(12*12*c.timestep) -- 12 hours with default 5min timestep
	
	return ent
end


--------------------------------------------------------------------------------
--
-- Save a round to database
-- this builds its data from the cache
-- so consider the props read only, they should all be copied into the cache anyhow
--
--------------------------------------------------------------------------------
--[[
function put(H,ent,t)

	t=t or dat -- use transaction?

	dat.build_props(ent)
	local ks=t.put(ent)
	
	if ks then
		ent.key=dat.keyinfo( ks ) -- update key with new id
		dat.build_cache(ent)
	end

	return ks -- return the keystring which is an absolute name
end
]]

--------------------------------------------------------------------------------
--
-- Load a round from database
--
--------------------------------------------------------------------------------
--[[
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
]]
--------------------------------------------------------------------------------
--
-- Load a list of rounds from database
--
--------------------------------------------------------------------------------
function list(srv,opts)
local H=srv.H
opts=opts or {}

	local list={}
	
	local q={
		kind=kind(srv),
		limit=opts.limit or 10,
		offset=0,
		}
	q[#q+1]={"filter","state","==",opts.state or "active"}
	if opts.timestep then
		q[#q+1]={"filter","timestep","==",opts.timestep or 600}
	end
	q[#q+1]={"sort","updated","DESC"}
		
	local ret=dat.query(q)
		
	for i=1,#ret.list do local v=ret.list[i]
		dat.build_cache(v)
	end

	return ret.list
end

--------------------------------------------------------------------------------
--
-- find current active round, the one we really really care about.
--
--------------------------------------------------------------------------------
function get_active(srv)
	return (list(srv,{state="active",timestep=300,limit=1})[1])
end
function get_last(srv)
	return (list(srv,{state="over",timestep=300,limit=1})[1]) -- need to fix this at start of next round
end
function get_speed(srv)
	return (list(srv,{state="over",timestep=1,limit=1})[1])
end

--------------------------------------------------------------------------------
--
-- inc the number of players in this round
-- this may get out pf sync and need to be recalculated
--
--------------------------------------------------------------------------------
function inc_players(srv,id)
local H=srv.H
	id=id or H.round.key.id -- use this round?
	
	return update(srv,id,function(srv,e)
		e.cache.players=(e.cache.players or 0)+1
		return true
	end)
end


--------------------------------------------------------------------------------
--
-- dec the number of players in this round
-- this may get out pf sync and need to be recalculated
--
--------------------------------------------------------------------------------
function dec_players(srv,id)
local H=srv.H
	id=id or H.round.key.id -- use this round?
	
	return update(srv,id,function(srv,e)
		e.cache.players=(e.cache.players or 0)-1
		if e.cache.players<0 then e.cache.players=0 end
		return true
	end)
	
end

--------------------------------------------------------------------------------
--
-- get - update - put
--
-- f must be a function that changes the entity.cache and returns true on success
-- id can be an id or an entity table from which we will get the id
--
--------------------------------------------------------------------------------
--[[
function update(H,id,f)
	if type(id)=="table" then id=id.key.id end -- can turn an entity into an id
	for retry=1,10 do
		local t=dat.begin()
		local e=get(H,id,t)
		if e then
			e.cache.updated=H.srv.time
			if not f(H,e) then t.rollback() return false end -- callback says fail
			check(H,e) -- keep everything valid
			if put(H,e,t) then -- entity put ok
				if t.commit() then -- success
					return e -- return the adjusted entity
				end
			end
		end
		t.rollback() -- undo everything ready to try again
	end
end
]]



dat.set_defs(_M) -- create basic data handling funcs

dat.setup_db(_M) -- make sure DB exists and is ready





