-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

-- wetgenes base modules
local json=require("wetgenes.json")
local wstr=require("wetgenes.string")
local whtml=require("wetgenes.html")
local mime=require("mime")

--pagecake base modules
local sys=require("wetgenes.www.any.sys")
local dat=require("wetgenes.www.any.data")
local users=require("wetgenes.www.any.users")
local stash=require("wetgenes.www.any.stash")
local img=require("wetgenes.www.any.img")

--pagecake mods
local d_sess =require("dumid.sess")
local d_users=require("dumid.users")

local note=require("note")
local comments=require("note.comments")

local waka=require("waka")
local wakapages=require("waka.pages")

local data=require("data")

-- debug functions
local dprint=function(...)print(wstr.dump(...))end
local log=require("wetgenes.www.any.log").log


-- sub modules of this mod
local html=require("artcrawl.html")
local pics=require("artcrawl.pics")
local arts=require("artcrawl.arts")




--module
local M={ modname=(...) } ; package.loaded[M.modname]=M


-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-----------------------------------------------------------------------------
function M.serv(srv)

	local cmd=srv.url_slash[ srv.url_slash_idx+0 ]	
	local cmds={
		test=		M.serv_test,
		cron=		M.serv_cron,
	}
	local f=cmds[ string.lower(cmd or "") ] or cmds.test
	if f then return f(srv) end

-- bad page
	return srv.redirect("/")
end


-----------------------------------------------------------------------------
--
-- all views fill in this stuff
--
-----------------------------------------------------------------------------
function M.get(srv,name)
local sess,user=d_sess.get_viewer_session(srv)

	srv.refined=waka.fill_refined(srv,name) -- basic root page and setup
	html.fill_cake(srv) -- more local setup

	if srv.is_admin(user) then
		srv.refined.cake.admin="{cake.artcrawl.admin_bar}"
	end
	
	return srv.refined
end

-----------------------------------------------------------------------------
--
-- all views return this html
--
-----------------------------------------------------------------------------
function M.put(srv)
	if srv.refined.opts.flame=="on" then -- add comments to this page
		srv.refined.cake.note.title=srv.refined.it and srv.refined.it.title or "artcrawl"
		srv.refined.cake.note.url=srv.url_local
		comments.build(srv,srv.refined)
	end
	srv.set_mimetype("text/html; charset=UTF-8")
	srv.put(wstr.macro_replace("{cake.html.plate}",srv.refined))
end

-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-----------------------------------------------------------------------------
function M.serv_cron(srv)
local sess,user=d_sess.get_viewer_session(srv)
	
--[[
	if srv.is_admin(user) or srv.is_local() then
	else
		return srv.redirect("/dumid?continue="..srv.url)
	end
]]
	
	local refined=M.get(srv,"artcrawl/cron")
	
	refined.body=pics.twat_search(srv,{hashtag="#leedsartcrawl"})

	M.put(srv)
end

-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-----------------------------------------------------------------------------
function M.serv_test(srv)
local sess,user=d_sess.get_viewer_session(srv)
	
	local refined=M.get(srv,"artcrawl/test")

	if not srv.is_admin(user) then
		return srv.redirect("/dumid?continue="..srv.url)
	end

	refined.title="art test"
	refined.listplate=[[
	<div>
	<img src="{it.pic_url}"/>
	<div><a href="http://twitter.com/{it.screen_name}/status/{it.id}">{it.text}</a></div>
	<div><a href="http://maps.google.com/?q={it.lat},{it.lng}">{it.lat} : {it.lng}</a></div>
	</div>
	]]

	refined.body="{-list:listplate}<pre>{list}</pre>"
	
--	refined.list=pics.twat_search(srv,{hashtag="#leedsartcrawl"})
	
	local le=pics.list(srv,{hashtag="#leedsartcrawl",valid=3,sort="twat_time-"})
	local l={}
	for i,v in ipairs(le) do
		local c=v.cache
		c.twat=nil
		l[#l+1]=c
	end
	refined.list=l

	M.put(srv)
end

-----------------------------------------------------------------------------
--
-- get image detail in a list
--
-----------------------------------------------------------------------------
function M.chunk_import(srv,opts)
opts=opts or {}

	local ret={}
	for i,v in pairs(opts) do ret[i]=v end -- copy opts into the return

	if opts.cmd=="list" then

		local list=pics.list(srv,opts)

		for i,v in ipairs(list) do
		
			local c=v.cache
			
			c.date=os.date("%Y-%m-%d",c.twat_time)
			c.time=os.date("%h:%M:%s",c.twat_time)
			
			c.thumb_url=c.pic_url:sub(8) -- skip http://

			if type(opts.hook) == "function" then -- fix up each item?
				opts.hook(v,{class="list"})
			end
			
			ret[#ret+1]=c
		end
	end
	
	return ret		
end


