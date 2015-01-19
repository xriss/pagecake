-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local log=require("wetgenes.www.any.log").log

local cache=require("wetgenes.www.any.cache")

local stashdata=require("wetgenes.www.any.stashdata")
local wstr=require("wetgenes.string")


-- a stash is a simple long term cache, it lives in data entities and survives reboots
-- but still may be deleted at anytime and expect to be recreated

module(...)


-----------------------------------------------------------------------------
--
-- clear all stashed data, may fail...
-- everything in the stash should be recreatable
--
-----------------------------------------------------------------------------
function clear(srv)
	delgroup(srv) -- this deletes everything
	cache.clear(srv)
	return false --not gonna do this yet, appengine has issues anyhow
end

-----------------------------------------------------------------------------
--
-- delete id from stash
--
-----------------------------------------------------------------------------
function del(srv,id)
	stashdata.del(srv,id)
	cache.del(srv,id)
end
-----------------------------------------------------------------------------
--
-- delete all in group from stash
-- also deletes anything withthe same id
--
-----------------------------------------------------------------------------
function delgroup(srv,group)
	repeat
		local list=stashdata.list(srv,{group=group})
log("deleting stash for "..#list.." items")
		for i,v in ipairs(list) do
			del(srv,v.cache.id)
		end
	until #list==0
	if group then del(srv,group) end
end
-----------------------------------------------------------------------------
--
-- put id in stash
-- it.data is data to store (should be json encodable)
--
-- everything else in is optional metadata such as
-- it.group
-- it.base
-- it.func
--
-----------------------------------------------------------------------------
function put(srv,id,it)
	local e=stashdata.set(srv,id,function(srv,e)
		for i,v in pairs(it) do -- copy into the cache, the cache is what we return on get
			e.cache[i]=v
		end
		return e
	end)
	if e then
		cache.put(srv,e.cache.id,e.cache,24*60*60) -- build cache
		return e.cache
	end	
end

-----------------------------------------------------------------------------
--
-- get id from stash
-- return it
-- the entity can be used for extra validity checks of the date (IE last update  time)
--
-----------------------------------------------------------------------------
function get(srv,id)
	local c=cache.get(srv,id) -- try cache first
	if c then return c end
	local e=stashdata.get(srv,id)
	if e then
		cache.put(srv,e.cache.id,e.cache,24*60*60) -- build cache
		return e.cache
	end
end
