-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local wet_html=require("wetgenes.html")

local dat=require("wetgenes.www.any.data")

local users=require("wetgenes.www.any.users")

local img=require("wetgenes.www.any.img")
local sys=require("wetgenes.www.any.sys")

local log=require("wetgenes.www.any.log").log -- grab the func from the package

local wstr=require("wetgenes.string")
local wet_string=wstr
local trim=wet_string.trim
local str_split=wet_string.str_split
local serialize=wet_string.serialize

local json=require("wetgenes.json")

local d_sess=require("dumid.sess")
local d_users=require("dumid.users")
local d_acts=require("dumid.acts")

-- require all the module sub parts
local html=require("hoe.html")
local players=require("hoe.players")
local rounds=require("hoe.rounds")
--local trades=require("hoe.trades")
local fights=require("hoe.fights")
local acts=require("hoe.acts")
local feats=require("hoe.feats")
local alerts=require("hoe.alerts")


local blog=require("blog")
local comments=require("note.comments")
local profile=require("profile")


local function cleanfloor(n)
	n = math.floor(tonumber(n or 0) or 0)
	if n~=n then n=0 end -- check for nan
	return n
end

local footer_data={
	app_name="hoe-house",
	app_link="http://code.google.com/p/aelua/wiki/AppHoeHouse",
}

module("hoe")

-----------------------------------------------------------------------------
--
-- create a main hoe state table
-- this can contain cached round and player info as well as srv
-- so for hoe functions we can pass this around rather than srv directly
-- this is a bad idea :) future apps will use srv and add fields rather than
-- wrapping srv into another value like this.
--
-----------------------------------------------------------------------------
function create(srv)

local sess,user=d_sess.get_viewer_session(srv)

	local H={}
	
	H.user=user
	H.sess=sess
	H.srv=srv
	H.slash=srv.url_slash[ srv.url_slash_idx ]
	srv.H=H
		
	H.get=function(a,b) -- get some html
		b=b or {}
		b.srv=srv
		b.H=H
		local r=wet_html.get(html,a,b)
		b.srv=nil
		b.H=nil
		return r
	end
	
	H.put=function(a,b) -- put some html
		srv.put(H.get(a,b))
	end
	
	H.arg=function(i) return srv.url_slash[ srv.url_slash_idx + i ]	end -- get an arg from the url
	
	H.page_admin=--[[( users.core.user and users.core.user.admin) or]](srv.is_admin(H.user)) -- page admin flag
		
	return H

end


-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-- do not cache the srv param localy, make sure it cascades around
--
-----------------------------------------------------------------------------
function serv(srv)

	local H=create(srv)
	H.srv.crumbs[#H.srv.crumbs+1]={url="/",title="Hoe House",link="Home",}
	
	if H.slash=="api" then
		return serv_api(srv)
	elseif H.slash=="cron" then
		return serv_cron(srv)
	end
		
	local put=H.put
	local roundid=tonumber(H.slash or 0) or 0
	if roundid>0 then -- load a default round from given id
		H.round=rounds.get(srv,roundid)
	end
	
	if H.round then -- we have a round, let them handle everything
		H.url_base=srv.url_base..H.round.key.id.."/"

		H.energy_frac=(H.srv.time/H.round.cache.timestep)
		H.energy_frac=H.energy_frac-math.floor(H.energy_frac) -- fractional amount of energy we have
		H.energy_step=H.round.cache.timestep

		local wart=alerts.alerts_to_html(srv,alerts.get_alerts(srv)) -- display some alerts? (no round)
		if wart then H.srv.alerts_html=(H.srv.alerts_html or "")..wart end
	
		return serv_round(srv)
	end
	
	local wart=alerts.alerts_to_html(srv,alerts.get_alerts(srv)) -- display some alerts? (no round)
	if wart then H.srv.alerts_html=(H.srv.alerts_html or "")..wart end
	
	local blog_html,blog_css=blog.recent_posts(srv,{num=5,over="/frontpage"})

	H.srv.set_mimetype("text/html; charset=UTF-8")
	put("header",{css=blog_css,title="Welcome to the hoe house!"})
	
-- ask which round

	local list=rounds.list(srv)
	put("round_row_header",{})
	for i=1,#list do local v=list[i]
		put("round_row",{round=v.cache})		
	end
	put("round_row_footer",{})
	
	put(blog_html)
	
	put("about",{})	
	
	local list=rounds.list(srv,{state="over"})
	put("old_round_row_header",{})
	for i=1,#list do local v=list[i]
		put("old_round_row",{round=v.cache})		
	end
	put("old_round_row_footer",{})
	
	put("footer",footer_data)
	
end



-----------------------------------------------------------------------------
--
-- basic serv when we are dealing with an existing round
--
-----------------------------------------------------------------------------
function serv_round(srv)
local H=srv.H

local put=H.put
	
	H.srv.crumbs[#H.srv.crumbs+1]={url=H.url_base,title="Round "..H.round.key.id,link="Round "..H.round.key.id,}
	
	H.cmd_request=nil

	H.user_data_name=(H.srv.flavour or "").."_hoe_"..H.round.key.id -- unique data name for this round

	if H.sess and H.user then -- we have a session and user
	
		local c=H.sess.cache
		
		c.hoeplayer=c.hoeplayer or {}
		
		if c.hoeplayer[H.round.key.id] then -- we have an id
		
			if c.hoeplayer[H.round.key.id]==0 then -- none
				H.player=nil
			else
				H.player=players.get(srv,c.hoeplayer[H.round.key.id])
			end
		
		else -- session needs fixing to link to player
					
			H.player=players.fix_session(srv,H.sess,H.round.key.id,H.user.key.id)
		end
		
--[[
		local user_data=H.user.cache[H.user_data_name]

		if user_data then -- we already have data, so use it
			H.player=players.get(H,user_data.player_id)
		end
]]
		
		if not H.player then -- no player in this round
		
			if H.round.cache.state=="active" then -- viewing an active round so sugest a join
			
				H.cmd_request="join"
				
			end
		end
	
	else -- no user so suggest they login
	
			H.cmd_request="login"
	
	end
	
	local cmd=H.arg(1)

	if cmd=="do" then -- perform a basic action with mild security
	
		local id=H.arg(2)
		local dat=d_acts.get(srv,H.user,id)
		
		if dat then
		
			if dat.check==H.user_data_name then -- good data
			
				if dat.cmd=="join" then -- join this round
			
					players.join(srv,H.user)
					players.fix_session(srv,H.sess,H.round.key.id,H.user.key.id)
					H.srv.redirect(H.url_base) -- simplest just to redirect at this point
					return true

				end
			end
		end
	end
	
-- functions for each special command	
	local cmds={
		list=	serv_round_list,
		work=	serv_round_work,
		shop=	serv_round_shop,
		profile=serv_round_profile,
		fight=	serv_round_fight,
--		trade=	serv_round_trade,
		acts=	serv_round_acts,
	}
	local f=cmds[ string.lower(cmd or "") ]
	if f then return f(srv) end

-- or display base menu

	H.srv.set_mimetype("text/html; charset=UTF-8")
	put("header",{})
	put("player_bar",{player=H.player and H.player.cache})
	
	if H.cmd_request=="join" then
		put("request_join",{act=d_acts.put(srv,H.user,{cmd="join",check=H.user_data_name})})
	elseif H.cmd_request=="login" then
		put("request_login",{})
	end
	
	put("hoe_menu_items",{})
	
	local a=acts.list(srv,{ dupe=0 , private=0 , limit=5 , offset=0 })
	if a then
		for i=1,#a do local v=a[i]
			local s=acts.plate(srv,v,"html")
			put("profile_act",{act=v.cache,html=s})
		end
	end
	
	

-- each round gets comments on its main page

	local srv=H.srv
	local url=H.srv.url_base
	if url:sub(-1)=="/" then url=url:sub(1,-2) end -- trim any trailing /
	local posts={} -- remove any gunk from the posts input
	-- check if this post probably came from this page before allowing post params
	if srv.method=="POST" and srv:check_referer(url) then
		for i,v in pairs(srv.posts) do
			posts[i]=v
		end
	end
	if posts.submit then posts.submit=trim(posts.submit) end

	comments.build(H.srv,{
		url="/hoe/"..H.round.key.id,
		title="round "..H.round.key.id,
		posts=posts,
		get=H.get,
		put=H.put,
		sess=H.sess,
		user=H.user,
		})



	put("footer",footer_data)
	
end


-----------------------------------------------------------------------------
--
-- list users
--
-----------------------------------------------------------------------------
function serv_round_list(srv)
local H=srv.H

local put=H.put

	H.srv.crumbs[#H.srv.crumbs+1]={url=H.url_base.."list/",title="list",link="list",}

	H.srv.set_mimetype("text/html; charset=UTF-8")
	put("header",{})
	put("player_bar",{player=H.player and H.player.cache})
	
	local page={} -- this sort of dumb paging should be fine for now? bad for appengine though
	page.show=0
	page.size=50
	page.next=page.size
	page.prev=0
	
	if H.srv.gets.off then
		page.show=math.floor( tonumber(H.srv.gets.off) or 0)
	end
	if page.show<0 then page.show=0 end	-- no negative offsets going in
	
	local list=players.list(srv,{limit=page.size,offset=page.show})
	
	page.next=page.show+page.size
	page.prev=page.show-page.size
	if page.prev<0 then page.prev=0 end -- and prev does not go below 0 either	
	if list and (#list < page.size) then page.next=0 end -- looks last page so set to 0
	
	local ending="@id.wetgenes.com"
	local endlen=string.len(ending)
	local c=10
	put("player_row_header",{url=H.srv.url,page=page})
	local topscore=1
	for i=1,#list do local v=list[i]
		local crowns=""
		local c=0
		if page.show==0 then
			if i==1 then
				topscore=v.cache.score
				if topscore<1 then topscore=1 end -- sane
				c=5
			else
				c=math.floor(5*v.cache.score/topscore)
			end
			if c>5 then c=5 end -- sane
			if c<0 then c=0 end -- sane
			if c>0 then
				if string.sub(v.cache.email,-endlen)==ending then
					crowns="+"..c
				end
			end
		end
		local profile=d_users.get_profile_link(v.cache.email) or ""
		put("player_row",{player=v.cache,idx=i+page.show,crowns=crowns,profile=profile})
	end
	put("player_row_footer",{url=H.srv.url,page=page})
		
	put("footer",footer_data)
	
end



-----------------------------------------------------------------------------
--
-- work hoes
--
-----------------------------------------------------------------------------
function serv_round_work(srv)
local H=srv.H

local put=H.put

	local url=H.url_base.."work"
	H.srv.crumbs[#H.srv.crumbs+1]={url=H.url_base.."work/",title="work",link="work",}
	
	local posts={} -- remove any gunk from the posts input
	-- check if this post probably came from this page before allowing post params
	if H.srv.method=="POST" and H.srv:check_referer(url) then
		for i,v in pairs(H.srv.posts) do
			posts[i]=string.gsub(v,"[^%w%p ]","") -- sensible characters only please
		end
	end
	if H.round.cache.state~="active" then posts={} end -- no actions unless round is active

	local result
	local payout
	local xwork=1
	
	if H.player and posts.payout then
		payout=cleanfloor(posts.payout)
		if payout<0 then payout=0 end
		if payout>100 then payout=100 end
		
		result={}
		result.energy=0
		result.hoes=0
		result.bros=0
		result.bux=0
		result.gloves=0
		
		local total=0
		
		local p=H.player.cache
		
		local rep=1
		if posts.x then
			rep=cleanfloor(posts.x)
			rep=cleanfloor(rep)
		end
		if rep>p.energy then rep=p.energy end -- do not try and work too many times
		if rep<1 then rep=1 end
		if rep>50 then rep=50 end
		xwork=rep


		for i=1,rep do -- repeat a few times, yes this makes for bad integration...
			result.energy=result.energy-1

			local houses=tonumber(p.houses)
			local gloves=tonumber(p.gloves)+result.gloves
			local hoes=tonumber(p.hoes)+result.hoes
					
			local crowd=hoes/(houses*50) -- how much space we have for hoes, 0 is empty and 1 is full
			local pay=payout/100
			local mypay=1-pay
			
			local gain=(1-(crowd/2)) -- 1.0 when empty , 0.5 when full , and 0.0 when bursting
			if gain<0 then gain=0 end
			gain = gain * pay * 1.0 -- also adjust by payout 
			
			local loss=(crowd) * mypay

			local tbux=math.floor((50 + 450*math.random()) * hoes) -- how much is earned
			local tgloves=math.floor(tbux/500)
			if gloves<tgloves then -- too few gloves
				result.gloves=result.gloves-gloves
				tbux=tbux*1.25		-- make moe money
			else -- we have enough gloves
				result.gloves=result.gloves-tgloves
				loss=loss*0.8		-- keep moe hoes
			end
			local bux=math.floor(tbux * mypay) -- how much we keep
			result.bux=result.bux+bux
			total=total+tbux

			if math.random() < gain then -- we gain a new hoe
				result.hoes=result.hoes+1
				if math.random() < gain then -- we also gain a new bro
					result.bros=result.bros+1
				end
			end
			
			if math.random() < loss then -- we lose a hoe
				result.hoes=result.hoes-1
			end
			
		end
		
		local r=players.update_add(srv,H.player,result)
		if r then
			H.player=r
			result.total_bux=total
		else
			result=nil -- failed, no energy?
		end
	end

	H.srv.set_mimetype("text/html; charset=UTF-8")
	put("header",{})
	put("player_bar",{player=H.player and H.player.cache})
	
	if result then
		put("player_work_result",{result=result,xwork=xwork or 1})
	end
	
	if H.player then
		put("player_work_form",{payout=payout or 50,xwork=xwork or 1})
	else
		put("player_needed",{})
	end
	
	put("footer",footer_data)
	
end

-----------------------------------------------------------------------------
--
-- shop
--
-----------------------------------------------------------------------------
function serv_round_shop(srv)
local H=srv.H

	local put=H.put
	local url=H.url_base.."shop"
	H.srv.crumbs[#H.srv.crumbs+1]={url=H.url_base.."shop/",title="shop",link="shop",}
		
	local posts={} -- remove any gunk from the posts input
	-- check if this post probably came from this page before allowing post params
	if H.srv.method=="POST" and H.srv:check_referer(url) then
		for i,v in pairs(H.srv.posts) do
			posts[i]=string.gsub(v,"[^%w%p ]","") -- sensible characters only please
		end
	end
	if H.round.cache.state~="active" then posts={} end -- no actions unless round is active
	
	local cost={}
		
	if H.player then -- must be logged in
	
		local function workout_cost()
			cost.houses=50000 * H.player.cache.houses
			cost.bros=1000 + (1 * H.player.cache.bros)
			cost.gloves=1
			cost.sticks=10
			cost.manure=100
		end
		workout_cost()
		
		local result
		if H.player and posts.houses then	-- attempt to buy
		
			local by={}
			by.houses=cleanfloor(posts.houses)
			by.bros=cleanfloor(posts.bros)
			by.gloves=cleanfloor(posts.gloves)
			by.sticks=cleanfloor(posts.sticks)
			by.manure=cleanfloor(posts.manure)
			for i,v in pairs(by) do
				v=math.floor(v)
				if v<0 then v=0 end
				by[i]=v
			end
			if by.houses>2  then by.houses=2  end -- may only buy 2 houses at a time
			if by.bros>1000 then by.bros=1000 end -- may only buy 1000 bros at a time
			by.bux=0
			for i,v in pairs(cost) do
				if by[i] then
					by.bux=by.bux-(v*by[i]) -- cost to purchase
				end
			end
			if H.player.cache.bux + by.bux < 0 then -- not enough cash
				result=by
				result.fail="bux"
			else
				local r=players.update_add(srv,H.player,by)
				if r then
					H.player=r
					workout_cost()
					result=by
				else
					result=nil -- failed, but do not report?
				end
			end
		end
		
	end
	
	H.srv.set_mimetype("text/html; charset=UTF-8")
	put("header",{})
	put("player_bar",{player=H.player and H.player.cache})
	
	if result then
		put("player_shop_result",{result=result})
	end
	
	if H.player then
		put("player_shop_form",{cost=cost})
	else
		put("player_needed",{})
	end
		
	put("footer",footer_data)

end

-----------------------------------------------------------------------------
--
-- profile
--
-----------------------------------------------------------------------------
function serv_round_profile(srv)
local H=srv.H

	local put=H.put
	local url=H.url_base.."profile"
	H.srv.crumbs[#H.srv.crumbs+1]={url=H.url_base.."profile/",title="profile",link="profile",}
	
	local posts={} -- remove any gunk from the posts input
	-- check if this post probably came from this page before allowing post params
	if H.srv.method=="POST" and H.srv:check_referer(url) then
		for i,v in pairs(H.srv.posts) do
			posts[i]=string.gsub(v,"[^%w%p ]","") -- sensible characters only please
		end
	end
	if H.round.cache.state~="active" then posts={} end -- no actions unless round is active
	
	if H.player and (posts.name or posts.shout) then
		local by={}
		
		if posts.do_name and posts.name and posts.name~=H.player.cache.name then
			local s=posts.name
			if string.len(s) > 20 then s=string.sub(s,1,20) end
			s=trim(s) -- no leading or trailing spaces
			if string.len(s) < 2 then s="DumDum" end
			by.name=wet_html.esc(s)
			by.energy=-1				-- costs one energy to change your name
		end

		if posts.do_shout and posts.shout then
			local s=posts.shout		
			if string.len(s) > 100 then s=string.sub(s,1,100) end		
			by.shout=wet_html.esc(s)
			if ( H.player.cache.lastshout or 0 ) + 60 < os.time() then -- not too often
				by.lastshout=os.time() - ( H.player.cache.lastshout or 0 )
			end
		end
		
		local r=players.update_add(srv,H.player,by)
		if r then
			if by.name then -- name change, log it in the actions
				acts.add_namechange(srv,{
					actor1 = H.player.key.id ,
					name1  = H.player.cache.name ,
					name2  = r.cache.name ,
					})
			end
			if by.shout and by.lastshout then -- shout change, log it in the actions, if not spammy
				acts.add_shout(srv,{
					actor1 = H.player.key.id ,
					name1  = H.player.cache.name ,
					shout  = by.shout ,
					})
			end
			H.player=r
		end
	end

	local view=tonumber(H.arg(2) or 0) or 0
	if view<=0 then view=nil end
	if view then
		view=players.get(srv,view)
		if view then
			if view.cache.round_id~=H.round.key.id then view=nil end -- check that player belongs to this round
		end
	end

	H.srv.set_mimetype("text/html; charset=UTF-8")
	put("header",{})
	put("player_bar",{player=H.player and H.player.cache})
	
	local a
	if view and view.cache then 
		put("player_profile",{player=view.cache,edit=false,fight=true})
		put(profile.get_profile_html(H.srv,view.cache.email))
		a=acts.list(srv,{ owner=view.cache.id , private=0 , limit=20 , offset=0 })

	elseif H.player then
		put("player_profile",{player=H.player.cache,edit=true})
		put(profile.get_profile_html(H.srv,H.player.cache.email))
		a=acts.list(srv,{ owner=H.player.key.id , limit=20 , offset=0 })
	end
	
	if a then
		put("profile_acts_header")
		for i=1,#a do local v=a[i]
			local s=acts.plate(srv,v,"html")
			put("profile_act",{act=v.cache,html=s})
		end
		put("profile_acts_footer")
		put([[
<script language="javascript" type="text/javascript">
	$(function(){
		$(".wetnote_comment_text a").autoembedlink({width:460,height:345});
	});
</script>
]])
		end
	
	
	put("footer",footer_data)

end

-----------------------------------------------------------------------------
--
-- fight
--
-----------------------------------------------------------------------------
function serv_round_fight(srv)
local H=srv.H

	local put,get=H.put,H.get
	local url=H.url_base.."fight"
	H.srv.crumbs[#H.srv.crumbs+1]={url=H.url_base.."fight/",title="fight",link="fight",}

	local posts={} -- remove any gunk from the posts input
	-- check if this post probably came from this page before allowing post params
	if H.srv.method=="POST" and H.srv:check_referer(url) then
		for i,v in pairs(H.srv.posts) do
			posts[i]=string.gsub(v,"[^%w%p ]","") -- sensible characters only please
		end
	end
	if H.round.cache.state~="active" then posts={} end -- no actions unless round is active
	
	local player=H.player
	local victim=tonumber(H.arg(2) or 0) or 0
	if victim<=0 then victim=nil end
	if victim then
		victim=players.get(srv,victim)
		if victim then
			if victim.cache.round_id~=H.round.key.id then victim=nil end -- check that player belongs to this round
		end
	end
	if victim and player and victim.key.id==player.key.id then victim=nil end -- cannot attack self
	
	local result
	if posts.victim and victim then
		if cleanfloor(posts.victim)~=victim.key.id then victim=nil end
		if victim and player then 
		
			local shout=""
			if posts.shout then
				local s=posts.shout or ""
				if string.len(s) > 100 then s=string.sub(s,1,100) end
				shout=wet_html.esc(s)
			end
					
			if posts.attack == "arson" then -- perform a robery
			
				local fight=fights.create_arson(srv,player,victim) -- prepare fight
				fight.cache.shout=shout -- include shout in fight data, so it can be saved to db
				
				-- apply the results, first remove energy from the player
				
				if players.update_add(srv,player,{
							energy=-fight.cache.energy,
							houses=fight.cache.sides[1].result.houses}) then -- edit the energy
						
					if players.update_add(srv,victim,fight.cache.sides[2].result) then -- things went ok

						if players.update_add(srv,player,fight.cache.sides[1].result) then -- things went ok
	
							fights.put(srv,fight) -- save this fight to db
						
							local a=acts.add_arson(srv,{
								actor1  = player.key.id ,
								name1   = player.cache.name ,
								actor2  = victim.key.id ,
								name2   = victim.cache.name ,
								shout   = shout,
								},fight)

							result=get("fight_result",{html=acts.plate(srv,a,"html")})
							
							player=players.get(srv,player)
							victim=players.get(srv,victim)
						end
						
					end
					
				end
				
			elseif posts.attack == "rob" then -- perform a robery
			
				local fight=fights.create_robbery(srv,player,victim) -- prepare fight
				fight.cache.shout=shout -- include shout in fight data, so it can be saved to db
				
				-- apply the results, first remove energy from the player
				
				if players.update_add(srv,player,{energy=-fight.cache.energy}) then -- edit the energy
				
					if players.update_add(srv,victim,fight.cache.sides[2].result) then -- things went ok

						if players.update_add(srv,player,fight.cache.sides[1].result) then -- things went ok
	
							fights.put(srv,fight) -- save this fight to db
						
							local a=acts.add_rob(srv,{
								actor1  = player.key.id ,
								name1   = player.cache.name ,
								actor2  = victim.key.id ,
								name2   = victim.cache.name ,
								shout   = shout,
								},fight)

							result=get("fight_result",{html=acts.plate(srv,a,"html")})
							
							player=players.get(srv,player)
							victim=players.get(srv,victim)
						end
						
					end
				end
				
			elseif posts.attack == "party" then -- perform a party
			
				local fight=fights.create_party(srv,player,victim) -- prepare fight
				fight.cache.shout=shout -- include shout in fight data, so it can be saved to db
				
				-- apply the results, first remove energy from the player
				
				if players.update_add(srv,player,{energy=-fight.cache.energy}) then -- edit the energy
				
					if players.update_add(srv,victim,fight.cache.sides[2].result) then -- things went ok

						if players.update_add(srv,player,fight.cache.sides[1].result) then -- things went ok
	
							fights.put(srv,fight) -- save this fight to db
						
							local a=acts.add_party(srv,{
								actor1  = player.key.id ,
								name1   = player.cache.name ,
								actor2  = victim.key.id ,
								name2   = victim.cache.name ,
								shout   = shout,
								},fight)

							result=get("fight_result",{html=acts.plate(srv,a,"html")})
							
							player=players.get(srv,player)
							victim=players.get(srv,victim)
						end
						
					end
				end
				
			end
		end
	end
	
	H.srv.set_mimetype("text/html; charset=UTF-8")
	put("header",{})
	put("player_bar",{player=H.player and H.player.cache})
	
	if result then
		put(result)
	end

	if player and victim then
	
		local tab={ url=url.."/"..victim.key.id , player=player.cache, victim=victim.cache}
		put("fight_header",tab)
		
		local fight=fights.create_robbery(srv,player,victim)				
		tab.fight=fight.cache
		put("fight_rob_preview",tab)
		
		local fight=fights.create_arson(srv,player,victim)
		tab.fight=fight.cache
		put("fight_arson_preview",tab)
		
		local fight=fights.create_party(srv,player,victim)
		tab.fight=fight.cache
		put("fight_party_preview",tab)
		
		put("fight_footer",tab)
		
	else
	
		local page={} -- this sort of dumb paging should be fine for now? bad for appengine though
		page.show=0
		page.size=50
		page.next=page.size
		page.prev=0
		
		if H.srv.gets.off then
			page.show=math.floor( tonumber(H.srv.gets.off) or 0)
		end
		if page.show<0 then page.show=0 end	-- no negative offsets going in
		
		local list=players.list(srv,{limit=page.size,offset=page.show})
		
		page.next=page.show+page.size
		page.prev=page.show-page.size
		if page.prev<0 then page.prev=0 end -- and prev does not go below 0 either	
		if list and (#list < page.size) then page.next=0 end -- looks last page so set to 0
		
		put("player_row_header",{url=H.srv.url,page=page})
		for i=1,#list do local v=list[i]
			local profile=d_users.get_profile_link(v.cache.email) or ""
			v.cache.shout=""
			if player then
				local f={}			
				f[1]=fights.create_robbery(srv,player,v).cache
				f[2]=fights.create_arson(srv,player,v).cache
				f[3]=fights.create_party(srv,player,v).cache

				f[4]=fights.create_robbery(srv,v,player).cache
				f[5]=fights.create_arson(srv,v,player).cache
				f[6]=fights.create_party(srv,v,player).cache

				local fmt=string.format
				v.cache.shout=
[[<a href="]]..url..[[/]]..v.cache.id..[[">
R: ]]..fmt("%02d",f[1].percent)..[[% (]]..fmt("%02d",f[4].percent)..[[%) S: ]]..html.num_to_thousands(v.cache.sticks)..[[<br/>
A: ]]..fmt("%02d",f[2].percent)..[[% (]]..fmt("%02d",f[5].percent)..[[%) S: ]]..html.num_to_thousands(v.cache.sticks)..[[<br/>
P: ]]..fmt("%02d",f[3].percent)..[[% (]]..fmt("%02d",f[6].percent)..[[%) M: ]]..html.num_to_thousands(v.cache.manure)..[[</a>]]

			end
			put("player_row",{player=v.cache,idx=i+page.show,crowns="",profile=profile})
		end
		put("player_row_footer",{url=H.srv.url,page=page})

	end
		
	put("footer",footer_data)

end





-----------------------------------------------------------------------------
--
-- acts
--
-----------------------------------------------------------------------------
function serv_round_disabled(srv)
local H=srv.H

	local put,get=H.put,H.get

	H.srv.set_mimetype("text/html; charset=UTF-8")
	put("header",{})
	put("player_bar",{player=H.player and H.player.cache})
	put("<h1>DISABLED</h1>")
	put("footer",footer_data)
end

-----------------------------------------------------------------------------
--
-- acts
--
-----------------------------------------------------------------------------
function serv_round_acts(srv)
local H=srv.H

	local put,get=H.put,H.get
	local url=H.url_base.."acts"
	H.srv.crumbs[#H.srv.crumbs+1]={url=H.url_base.."acts/",title="acts",link="acts",}

	local posts={} -- remove any gunk from the posts input
	-- check if this post probably came from this page before allowing post params
	if H.srv.method=="POST" and H.srv:check_referer(url) then
		for i,v in pairs(H.srv.posts) do
			posts[i]=string.gsub(v,"[^%w%p ]","") -- sensible characters only please
		end
	end
	if H.round.cache.state~="active" then posts={} end -- no actions unless round is active
	
	H.srv.set_mimetype("text/html; charset=UTF-8")
	put("header",{})
	put("player_bar",{player=H.player and H.player.cache})
	
	put("acts_header",{url=url})
	
	local tt={ dupe=0 , private=0 , limit=20 , offset=0 }
	local tail=H.arg(2)
	if tail=="chat" then
		tt.type="chat"
--	elseif tail=="trade" then
--		tt.type="trade"
	elseif tail=="fight" then
		tt.type="fight"
	end
	local off=math.floor( tonumber(H.srv.gets.off) or 0)
	if off<0 then off=0 end		
	tt.offset=off
	local a=acts.list(srv,tt)
	if a then
		for i=1,#a do local v=a[i]
			local s=acts.plate(srv,v,"html")
			put("profile_act",{act=v.cache,html=s})
		end
	end
	
	local this_url=url
	if tt.type then this_url=this_url.."/"..tt.type end
	
	local tt_prev=tt.offset-tt.limit
	local tt_next=tt.offset+tt.limit
	
-- clamp offsets to prevent search engines going crazy
	if tt_prev<0 then tt_prev=0 end -- and prev does not go below 0 either	
	if (a and #a or 0 ) < tt.limit then tt_next=0 end -- looks last page so set to 0
	
	put("acts_footer",{url=this_url,prev_off=tt_prev,next_off=tt_next})
		
	put("footer",footer_data)

end



-----------------------------------------------------------------------------
--
-- base api
--
-----------------------------------------------------------------------------
function serv_api(srv)
local H=srv.H
	local put,get=H.put,H.get
	
	local cmd=H.arg(1)
	
	local jret={}
	
	jret.result="ERROR"
	
	if cmd=="tops" then
	
		local round=rounds.get_active(srv) -- get active round
		if round then
			jret.active=feats.get_top_players(srv,round.key.id)
			jret.result="OK"
		end
		
		local round=rounds.get_last(srv) -- get last round		
		if round then
			jret.last=feats.get_top_players(srv,round.key.id)
			jret.result="OK"
		end
--[[
		local round=rounds.get_speed(H) -- get speed round
		if round then
			jret.speed=feats.get_top_players(H,round.key.id)
			jret.result="OK"
		end
]]
	end
	
	H.srv.set_mimetype("text/plain; charset=UTF-8")
	put(json.encode(jret))
end


-----------------------------------------------------------------------------
--
-- base cron
--
-----------------------------------------------------------------------------
function serv_cron(srv)
local H=srv.H
	local put,get=H.put,H.get
	
	local cmd=H.arg(1)
	
-- check we have admin
-- turns out cron jobs do not get real admin
-- so we have to use web.xml to admin lock this page
-- how sucky, can we have a cron user please...
--[[
	if not H.page_admin then -- can not view this page
	
		H.srv.set_mimetype("text/plain; charset=UTF-8")
		H.srv.put("Admin required to view this page\n")
		return
	end
]]
		
	H.srv.set_mimetype("text/plain; charset=UTF-8")
	H.srv.put("Performing cron "..H.srv.time.."\n")
	
	
--	local numof_fastrounds=0
	
	local list=rounds.list(srv)
	
	for i,v in ipairs(list) do	
	
		rounds.check(srv,v)
		
		H.srv.put("checking round "..v.key.id.."\n")
		
		if v.cache.state ~= v.props.state then -- we should update		
			if v.props.state=="active" and v.cache.state=="over" then
				if rounds.update(srv,v,function(srv,e)
					if e.props.state=="active" then e.cache.state="over" return true end -- change state
					return false
				end) then
					H.srv.put("round "..v.key.id.." marked as over\n")
					v.cache.state="over" -- patch for later
				else
					H.srv.put("round "..v.key.id.." update failed\n")
				end
			end
		end
		
--[[
		if v.cache.timestep < 300 then -- a fast round is any tick less than 5 minutes
			numof_fastrounds=numof_fastrounds+1
		end
]]
		
		if v.cache.state=="active" then -- pulse the trades
			H.round=v -- think about this round
--			trades.pulse(srv)
		end
		
	end
	
	local d=os.date("*t")
		
	if #list==0 then -- when all rounds are over, create a new default active round
	
		H.srv.put("there are no active rounds\n")

		if d.hour==0 then -- start a new one but only within the first hour of the day
		
			local r=rounds.create(srv)
			rounds.put(srv,r)
			H.srv.put("created new round "..r.key.id.."\n")
			
		end
	end
	
--[[
	if numof_fastrounds==0 then -- check if we should create a new fastround

		H.srv.put("there are no active fast rounds\n")
		
		H.srv.put( "STARS ARE ALIGNED TO ".. d.wday .. " : ".. d.hour .." : ".. d.min .."\n" )
	
		if d.wday==7 and d.hour==22 and d.min<30 then -- start a new one only within the first halfhour of X
			local r=rounds.create(H)
			r.cache.timestep = 1 -- super fast game
			r.cache.max_energy = 999 -- super energy store
			r.cache.endtime=H.srv.time+(r.cache.timestep*4032) -- same number of ticks as default game
			rounds.put(H,r)
			H.srv.put("created new speed round "..r.key.id.."\n")
		end
	end
]]

end
