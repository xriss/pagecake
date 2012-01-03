-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local wet_html=require("wetgenes.html")
local replace=wet_html.replace

local sys=require("wetgenes.www.any.sys")

local json=require("wetgenes.json")
local dat=require("wetgenes.www.any.data")

local users=require("wetgenes.www.any.users")

local fetch=require("wetgenes.www.any.fetch")
local cache=require("wetgenes.www.any.cache")

local img=require("wetgenes.www.any.img")

local log=require("wetgenes.www.any.log").log -- grab the func from the package

local oauth=require("wetgenes.www.any.oauth")

local wet_string=require("wetgenes.string")
local trim=wet_string.trim
local str_split=wet_string.str_split
local serialize=wet_string.serialize

local wet_waka=require("wetgenes.waka")

-- require all the module sub parts
local html=require("port.html")



-- opts
local opts_mods_port=(opts and opts.mods and opts.mods.port) or {}

module("port.goo")

--
-- shorten a url , returns the new url
--

function shorten(url)

	local got=fetch.post("https://www.googleapis.com/urlshortener/v1/url?key=AIzaSyBvpbJCF1Pl-VENOr09NXHdO8xryGDH0Sg",
		{
--			["Authorization"]="OAuth "..table.concat(auths,", "),
			["Content-Type"]="application/json; charset=utf-8",
		},json.encode({longUrl=url}) )

	local ret=json.decode(got.body)

	return ret.id or url
end


