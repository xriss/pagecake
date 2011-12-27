
local json=require("wetgenes.json")

local dat=require("wetgenes.www.any.data")
local cache=require("wetgenes.www.any.cache")

local log=require("wetgenes.www.any.log").log -- grab the func from the package

local fetch=require("wetgenes.www.any.fetch")
local sys=require("wetgenes.www.any.sys")


local os=os
local string=string
local math=math

local tostring=tostring
local type=type
local ipairs=ipairs

local wet_string=require("wetgenes.string")
local str_split=wet_string.str_split
local serialize=wet_string.serialize

module("dimeload.shells")
dat.set_defs(_M) -- create basic data handling funcs

-- a shell maps to a wiki page (use same id as page) and should contain a list of data ids for the actual downloads
default_props=
{
	owner="", -- the initial users id eg "1234@id.gmail.com"

}

default_cache=
{
	dataids={}, -- pointers to meta data, one file or maybe more
}



--------------------------------------------------------------------------------
--
-- allways this kind
--
--------------------------------------------------------------------------------
function kind(srv)
	return "dimeload.shell"
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








