-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local wet_html=require("wetgenes.html")

local dat=require("wetgenes.www.any.data")

local users=require("wetgenes.www.any.users")

local img=require("wetgenes.www.any.img")
local sys=require("wetgenes.www.any.sys")

local log=require("wetgenes.www.any.log").log -- grab the func from the package

local wstr=require("wetgenes.string")
local json=require("wetgenes.json")

local d_sess=require("dumid.sess")
local d_users=require("dumid.users")
local d_acts=require("dumid.acts")


local blog=require("blog")
local comments=require("note.comments")
local profile=require("profile")

local html=require("shadow.html")


local function cleanfloor(n)
	n = math.floor(tonumber(n or 0) or 0)
	if n~=n then n=0 end -- check for nan
	return n
end

--module
local M={ modname=(...) } ; package.loaded[M.modname]=M

-----------------------------------------------------------------------------
--
-- get/put generator
--
-----------------------------------------------------------------------------
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
function M.serv(srv)

local sess,user=d_sess.get_viewer_session(srv)
local get,put=make_get_put(srv)

	srv.set_mimetype("text/html; charset=UTF-8")
	put("header",{title="Beware of Shadow over WetVille!"})
	
	put("footer",footer_data)	
end

