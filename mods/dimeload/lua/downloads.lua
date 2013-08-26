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

module("dimeload.downloads")
local _M=require(...)


default_props=
{
	user="", -- who downloaded
	ip="", -- ip of where it was downloaded to

	project="", -- project name
	page="", -- page name (may be "")
	file="", -- file name
}

default_cache=
{
}



--------------------------------------------------------------------------------
--
-- allways this kind
--
--------------------------------------------------------------------------------
function kind(srv)
	return "dimeload.downloads"
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
		
	return ent
end

--------------------------------------------------------------------------------
--
-- Load a list of active visible projects
--
--------------------------------------------------------------------------------
function list(srv,opts)
local H=srv.H
opts=opts or {}

	local list={}
	
	local q={
		kind=kind(srv),
		limit=opts.limit or 10,
		offset=0,
		}
	q[#q+1]={"sort","updated","DESC"}
		
	local ret=dat.query(q)
		
	for i=1,#ret.list do local v=ret.list[i]
		dat.build_cache(v)
	end

	return ret.list
end


dat.set_defs(_M) -- create basic data handling funcs

dat.setup_db(_M) -- make sure DB exists and is ready






