
local json=require("wetgenes.json")

local dat=require("wetgenes.aelua.data")
local cache=require("wetgenes.aelua.cache")

local log=require("wetgenes.aelua.log").log -- grab the func from the package

local fetch=require("wetgenes.aelua.fetch")
local sys=require("wetgenes.aelua.sys")


local os=os
local string=string
local math=math

local tostring=tostring
local type=type
local ipairs=ipairs

local wet_string=require("wetgenes.string")
local str_split=wet_string.str_split
local serialize=wet_string.serialize

module("dimeload.dimes")
dat.set_defs(_M) -- create basic data handling funcs


-- each download is live for 60 minutes after first activation.
default_props=
{
	shell="", -- the id of the shell this load belongs to
	load="", -- the id of the load this dime belongs to

	ip="", -- each download is locked to an ip
	
	owner="", -- a user may claim a dimeload if they wish
	
	count="", -- number of times this has been downloaded (if it gets large we may add more restrictions)
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
	return "dimeload.dime"
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








