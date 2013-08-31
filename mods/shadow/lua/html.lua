-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local log=require("wetgenes.www.any.log").log

local sys=require("wetgenes.www.any.sys")
local users=require("wetgenes.www.any.users")

local waka=require("wetgenes.waka")

local wstr=require("wetgenes.string")
local whtml=require("wetgenes.html")


--module
local M={ modname=(...) } ; package.loaded[M.modname]=M

local base_html=require("base.html")

-----------------------------------------------------------------------------
--
-- load and parse html from file
--
-----------------------------------------------------------------------------

base_html.import(M,"lua/shadow/html.html")
