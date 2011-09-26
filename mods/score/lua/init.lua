
local wet_html=require("wetgenes.html")
local replace=wet_html.replace

local sys=require("wetgenes.aelua.sys")

local json=require("wetgenes.json")
local dat=require("wetgenes.aelua.data")

local users=require("wetgenes.aelua.users")

local log=require("wetgenes.aelua.log").log -- grab the func from the package

local wet_string=require("wetgenes.string")
local trim=wet_string.trim
local str_split=wet_string.str_split
local serialize=wet_string.serialize
local macro_replace=wet_string.macro_replace

local wet_waka=require("wetgenes.waka")
local d_sess =require("dumid.sess")
local d_users=require("dumid.users")

-- require all the module sub parts
local html=require("score.html")

local waka=require("waka")
local note=require("note")

local scores=require("score.scores")

local wakapages=require("waka.pages")
local comments=require("note.comments")

local math=math
local string=string
local table=table
local os=os

local ipairs=ipairs
local pairs=pairs
local tostring=tostring
local tonumber=tonumber
local type=type
local pcall=pcall
local loadstring=loadstring


-- opts
local opts_mods_score=(opts and opts.mods and opts.mods.score) or {}

module("score")

local function make_get_put(srv)
	local get=function(a,b)
		b=b or {}
		b.srv=srv
		return wet_html.get(html,a,b)
	end
	return  get , function(a,b) srv.put(get(a,b)) end
end

-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-----------------------------------------------------------------------------
function serv(srv)
local sess,user=d_sess.get_viewer_session(srv)
local get,put=make_get_put(srv)
	
	local url=srv.url_base
	if url:sub(-1)=="/" then url=url:sub(1,-2) end -- trim any trailing /

-- this is the base url we use for comments
	local t={""}
	for i=4,srv.url_slash_idx-1 do
		t[#t+1]=srv.url_slash[i]
	end
	local baseurl=table.concat(t,"/")

-- handle posts cleanup
	local posts={} -- remove any gunk from the posts input
	-- check if this post probably came from this page before allowing post params
	if srv.method=="POST" and srv.headers.Referer and string.sub(srv.headers.Referer,1,string.len(url))==url then
		for i,v in pairs(srv.posts) do
			posts[i]=v
		end
	end
	if posts.submit then posts.submit=trim(posts.submit) end
	for n,v in pairs(srv.uploads) do
		posts[n]=v
	end

-- need the base wiki page, for style yo

	local gamename=nil

	local pageopts={
		flame="on",
	}
	srv.pageopts=pageopts -- keep the page options here
	
	local crumbs={ {url="/",text="Home"} , {url="/score",text="score"} }
	srv.crumbs=crumbs

	
	local cmd=srv.url_slash[srv.url_slash_idx+0]
	
	if cmd=="submit" then -- a special place
	

-- we are logged in, do simple score check and then either update a score or make a new one (you only get one score)

		local day=math.floor(srv.time/(60*60*24))
		local score=math.floor( tonumber(srv.gets.score or 0) or 0)
		local dumb=math.floor( tonumber(srv.gets.dumb or 0) or 0)
		local game=tostring(srv.gets.game) or ""

		if not user then-- must be logged in so go login and come back here later
			return srv.redirect("/dumid/login/?continue="..wet_html.url_esc(srv.url.."?game="..(game).."&score="..score.."&dumb="..dumb))
		end
		
		for i,v in ipairs(opts_mods_score.games or {}) do
		
			if v==game then -- a valid name

				gamename=v
				
			end
		end
--log(gamename)
		if gamename and (dumb==score*day) then --ok then, try and submit or update a score
--log(score)

			local userid=user.cache.id
			local icon=d_users.get_avatar_url(user.cache,50,50)
			local _,link=d_users.get_profile_link(user.cache.id)
			local name=user.cache.name
		
			list=scores.list(srv,{game=gamename,limit=1,owner=userid})
			
			if list[1] then -- update this score only if we scored better
			
				if list[1].cache.score < score then -- okeee update
				
					scores.update(srv,list[1],function(srv,e)
						local c=e.cache
						c.ip=srv.ip
						c.score=score
						return true
					end)
				
				end
				
			else -- add our score then

				local e=scores.create(srv)
				local c=e.cache
				
				c.owner=userid
				c.game=gamename
				c.name=name
				c.score=score
				c.ip=srv.ip
				c.owner_icon=icon
				c.owner_link=link
				
				scores.put(srv,e)
			
			end
			
		end
		
		if gamename then
			return srv.redirect("/score/"..gamename)
		else
			return srv.redirect("/score")
		end
		
	end
	
	
	for i,v in ipairs(opts_mods_score.games or {}) do
	
		if v==cmd then -- a valid name

			gamename=v
			
		end
	end
	
	local list={}
	
	if gamename then
	
		list=scores.list(srv,{game=gamename,limit=32,sort="score"})
		
	end
	

	local refined	
	local url_local="/score"
	if gamename then 
		url_local="/score/"..gamename
		refined=wakapages.load(srv,"/score/"..gamename)[0]
	else
		refined=wakapages.load(srv,"/score")[0]
	end


	local css=refined and refined.css

	
	local html_head
	if refined.html_head then html_head=get(refined.html_head,refined) end
	
	srv.set_mimetype("text/html; charset=UTF-8")
	put("header",{title=title,css=css,extra=html_head})

	if refined then
		
		local scores={}
		refined.scores=scores
		
		for i,v in ipairs(list) do
			local s={}
			local c=v.cache
			c.rank=i
			scores[#scores+1]=c
		end
		
		scores.plate="plate_score"
		
		put(macro_replace(refined.plate or "{body}",refined))

	end

	if pageopts.flame=="on" then -- add comments to this page
		comments.build(srv,{title=title,url=url_local,posts=posts,get=get,put=put,sess=sess,user=user})
	elseif pageopts.flame=="anon" then -- add *anonymous* comments to this page
		comments.build(srv,{title=title,url=url_local,posts=posts,get=get,put=put,sess=sess,user=user,anon="default"})
	end

	put("footer")
	
end

