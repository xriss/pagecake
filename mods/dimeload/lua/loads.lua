-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local json=require("wetgenes.json")

local dat=require("wetgenes.www.any.data")
local cache=require("wetgenes.www.any.cache")

local log=require("wetgenes.www.any.log").log -- grab the func from the package

local fetch=require("wetgenes.www.any.fetch")
local sys=require("wetgenes.www.any.sys")

local wet_string=require("wetgenes.string")
local str_split=wet_string.str_split
local serialize=wet_string.serialize

module("dimeload.loads")
local _M=require(...)

default_props=
{
	shell="", -- the id of the shell this load belongs to

	owner="", -- the initial users id eg "1234@id.gmail.com"
	dimes=0, -- number of initial downloads available
	available=0, -- number of downloads available now
}

default_cache=
{
	link="", -- as an actualy paying customer you may provide a promoted link
}



--------------------------------------------------------------------------------
--
-- allways this kind
--
--------------------------------------------------------------------------------
function kind(srv)
	return "dimeload.load"
end

--------------------------------------------------------------------------------
--
-- check that entity has initial data and set any missing defaults
-- the second return value is false if this is not a valid entity
--
--------------------------------------------------------------------------------
function check(srv,ent)

	local ok=true
	local c=ent.cache
		
	return ent,ok
end






dat.set_defs(_M) -- create basic data handling funcs

dat.setup_db(_M) -- make sure DB exists and is ready





