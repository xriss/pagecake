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


module("dumid.acts")

-----------------------------------------------------------------------------
--
-- associates a future action with the active user, returns a key valid for 5 minutes
-- this data is only stored in the cache so if the cache breaks so does this
-- system
-- 
-----------------------------------------------------------------------------
function put(srv,user,dat)
	if not user or not dat then return nil end
	
local id=tostring(math.random(10000,99999)) -- need a random number but "random" isnt a big issue
	
local key="user=act&"..user.cache.id.."&"..id

	cache.put(srv,key,dat,60*5) -- store for 5 mins
	
	return id
end

-----------------------------------------------------------------------------
--
-- retrives an action for this active user or nil if not a valid key
--
-----------------------------------------------------------------------------
function get(srv,user,id)
	if not user or not id then return nil end
	
local key="user=act&"..user.cache.id.."&"..id
local dat=cache.get(srv,key)

	if not dat then return nil end -- notfound
	
	cache.del(srv,key) -- one use only
	
	return dat

end
