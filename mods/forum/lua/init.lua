-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local whtml=require("wetgenes.html")
local json=require("wetgenes.json")

local sys=require("wetgenes.www.any.sys")
local dat=require("wetgenes.www.any.data")
local users=require("wetgenes.www.any.users")
local log=require("wetgenes.www.any.log").log -- grab the func from the package
local stash=require("wetgenes.www.any.stash")
local img=require("wetgenes.www.any.img")

local wstr=require("wetgenes.string")
local dlog=function(...)log(wstr.dump(...))end

local mime=require("mime")

local wet_waka=require("wetgenes.waka")
local d_sess =require("dumid.sess")
local d_users=require("dumid.users")

-- require all the module sub parts
local html=require("forum.html")

local waka=require("waka")
local note=require("note")
local data=require("data")

local wakapages=require("waka.pages")
local comments=require("note.comments")


--module
local M={ modname=(...) } ; package.loaded[M.modname]=M


-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-----------------------------------------------------------------------------
function M.serv(srv)
	local sess,user=d_sess.get_viewer_session(srv)


	local board_name=srv.url_slash[srv.url_slash_idx+0]
	if board_name then

		local refined=M.fill_refined(srv,"forum/"..board_name)
		local board
		if refined.lua and refined.lua.forums and board_name then
			for i,v in ipairs(refined.lua.forums) do
				if v.name:lower()==board_name:lower() then
					board=v
					break
				end
			end
		end
		if not board then
			return srv.redirect("/forum")
		end
		refined.body=board.body or "{title}"
		refined.title=board.title or board.name
		
		refined.cake.note.title=refined.title or "forum"
		refined.cake.note.url=srv.url_local
		comments.build(srv,refined)
		
		return waka.display_refined(srv,refined)
	else

		local refined=M.fill_refined(srv,"forum")
		refined.cake.notes=""
		refined.cake.note.tick_items=refined.cake.note.tick_items or comments.recent_refined(srv,comments.get_recent(srv,48))

		return waka.display_refined(srv,refined)	
	end
	
end


-----------------------------------------------------------------------------
--
-- all views fill in this stuff
--
-----------------------------------------------------------------------------
function M.fill_refined(srv,name)
	local sess,user=d_sess.get_viewer_session(srv)

	local refined=waka.prepare_refined(srv,name) -- basic root page and setup
	html.fill_cake(srv,refined) -- more local setup

	if srv.is_admin(user) then
		refined.cake.admin="{cake.forum.admin_bar}"
	end
	
	if refined.opts.flame=="on" then -- add comments to this page
		refined.cake.note.title=refined.it and refined.it.title or "forum"
		refined.cake.note.url=srv.url_local
		comments.build(srv,refined)
	end

	return refined
end


