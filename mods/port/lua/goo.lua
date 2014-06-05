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
local fetch=require("wetgenes.www.any.fetch")

--pagecake mods
local d_sess =require("dumid.sess")
local d_users=require("dumid.users")

-- debug functions
local dprint=function(...)print(wstr.dump(...))end
local log=require("wetgenes.www.any.log").log


--module
local M={ modname=(...) } ; package.loaded[M.modname]=M



--
-- shorten a url , returns the new url
--

function M.shorten(url)

	local got=fetch.post("https://www.googleapis.com/urlshortener/v1/url?key=AIzaSyBvpbJCF1Pl-VENOr09NXHdO8xryGDH0Sg",
		{
--			["Authorization"]="OAuth "..table.concat(auths,", "),
			["Content-Type"]="application/json; charset=utf-8",
		},json.encode({longUrl=url}) )

	local ret=json.decode(got.body)

	return (ret and ret.id) or url
end


