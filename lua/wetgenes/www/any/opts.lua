-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local dat=require("wetgenes.www.any.data")
local cache=require("wetgenes.www.any.cache")


-- a place to keep options such as passwords that
-- the server needs to know about but are different per app
-- and obviously should not be included in code

-- data is kept in the datastore and also cached in the memcache (todo)

local ngx=ngx

module("wetgenes.www.any.opts")
local _M=require(...)

default_props=
{
}

default_cache=
{
}

function kind()
	return "opts"
end



--------------------------------------------------------------------------------
--
-- check that entity has initial data and set any missing defaults
-- the second return value is false if this is not a valid entity
--
--------------------------------------------------------------------------------
function check(srv,ent)
	local srv=ngx and ngx.ctx

	local c=ent.cache
		
	return ent
end


--------------------------------------------------------------------------------
--
-- read a string
--
--------------------------------------------------------------------------------
function get_dat(id)
	local srv=ngx and ngx.ctx
	local e=get(srv,id,t)
	if e then return e.cache.dat end
	return nil
end
--------------------------------------------------------------------------------
--
-- write a string
--
--------------------------------------------------------------------------------
function put_dat(id,dat)
	local srv=ngx and ngx.ctx
	local e=create(srv)
	e.key.id=id
	e.cache.dat=dat
	local r=put(srv,e)
	
	return r
end



--dat.set_defs(_M) -- create basic data handling funcs
--dat.setup_db(_M) -- make sure DB exists and is ready
