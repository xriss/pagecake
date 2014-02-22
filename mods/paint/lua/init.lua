-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local wet_html=require("wetgenes.html")
local replace=wet_html.replace

local sys=require("wetgenes.www.any.sys")

local json=require("wetgenes.json")
local dat=require("wetgenes.www.any.data")

local users=require("wetgenes.www.any.users")

local log=require("wetgenes.www.any.log").log -- grab the func from the package

local wet_string=require("wetgenes.string")
local trim=wet_string.trim
local str_split=wet_string.str_split
local serialize=wet_string.serialize
local macro_replace=wet_string.macro_replace

local stash=require("wetgenes.www.any.stash")


local wet_waka=require("wetgenes.waka")
local d_sess =require("dumid.sess")
local d_users=require("dumid.users")

-- require all the module sub parts
local html=require("paint.html")

local waka=require("waka")
local note=require("note")

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

	local cmd=srv.url_slash[ srv.url_slash_idx+0 ]	
	local cmds={
		test=		M.serv_test,
		upload=		M.serv_upload,
	}
	local f=cmds[ string.lower(cmd or "") ]
	if f then return f(srv) end

-- bad page
	return srv.redirect("/")
end



-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-----------------------------------------------------------------------------
function M.serv_test(srv)
local sess,user=d_sess.get_viewer_session(srv)
	
	local refined=waka.fill_refined(srv,"paint")
	html.fill_cake(srv,refined) -- add paint html
	
	if srv.is_admin(user) then
		refined.cake.admin="{cake.paint.admin_bar}"
	end

	srv.set_mimetype("text/html; charset=UTF-8")
	srv.put(macro_replace("{cake.html.plate}",refined))

end


-----------------------------------------------------------------------------
--
-- upload an image (possibly replacing what is there already)
-- this is time locked to today GMT only, with a little bit of safezone either side
-- the day challenge changes at midnight GMT eitherway.
--
-----------------------------------------------------------------------------
function M.serv_upload(srv)
local sess,user=d_sess.get_viewer_session(srv)

-- handle posts cleanup
	local posts={} -- remove any gunk from the posts input
	-- check if this post probably came from this page before allowing post params
	if srv.method=="POST" and srv:check_referer() then
		for i,v in pairs(srv.posts) do
			posts[i]=v
		end
	end
	if posts.submit then posts.submit=trim(posts.submit) end
	for n,v in pairs(srv.uploads) do
		posts[n]=v
	end

	local refined=waka.fill_refined(srv,"paint")
	html.fill_cake(srv,refined) -- add paint html
	
	if srv.is_admin(user) then
		refined.cake.admin="{cake.paint.admin_bar}"
	end

	srv.set_mimetype("text/html; charset=UTF-8")
	srv.put(macro_replace("{cake.html.plate}",refined))

end

-----------------------------------------------------------------------------
--
-- get image detail in a list
--
-----------------------------------------------------------------------------
function M.chunk_import(srv,opts)
opts=opts or {}

	return {}
		
end
