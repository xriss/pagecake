-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local wet_html=require("wetgenes.html")

local sys=require("wetgenes.www.any.sys")

local json=require("wetgenes.json")
local dat=require("wetgenes.www.any.data")
local cache=require("wetgenes.www.any.cache")

local users=require("wetgenes.www.any.users")

local fetch=require("wetgenes.www.any.fetch")

local img=require("wetgenes.www.any.img")

local log=require("wetgenes.www.any.log").log -- grab the func from the package

local wstring=require("wetgenes.string")

local wet_string=require("wetgenes.string")
local str_split=wet_string.str_split
local serialize=wet_string.serialize

local wet_diff=require("wetgenes.diff")


-- require all the module sub parts
local html=require("blog.html")

local ngx=ngx

--
-- Which can be overidden in the global table opts
--



-- replacement version of module that does not global
local module=function(modname, ...)
	local ns={ _NAME = modname , _PACKAGE = string.gsub (modname, "[^.]*$", "") }
	ns._M = ns
	package.loaded[modname] = ns
	setfenv (2, ns)
	for _,f in ipairs({...}) do f(ns) end
end
module("data.file")
--local _M=require(...)

default_props=
{
	metakey=0, -- the meta data id associated with this file
	
	nextkey=0, -- if not 0 then the next file key if we are split over a few entries
	prevkey=0, -- if not 0 then the previous file key if we are split over a few entries

	data="", -- the actual data, max length of ( 1000 * 1000 ) 1meg decimal
	size=0, -- the size of the data in this chunk
}

default_cache=
{
}

function kind(srv)
	if not srv or not srv.flavour or srv.flavour=="data" then return "data.file" end
	return srv.flavour..".data.file"
end

--------------------------------------------------------------------------------
--
-- what key name should we use to cache an entity?
--
--------------------------------------------------------------------------------
--[[
function cache_key(id)
	return "type=ent&data.file="..id
end
]]

--------------------------------------------------------------------------------
--
-- Create a new local entity filled with initial data
--
--------------------------------------------------------------------------------
--[[
function create(srv)

	local ent={}
	
	ent.key={kind=kind(srv)} -- we will not know the key id until after we save
	ent.props={}
	
	local p=ent.props
	
	p.created=srv.time
	p.updated=srv.time

	p.metakey=0 -- the meta data id associated with this file
	
	p.nextkey=0 -- if not 0 then the next file key if we are split over a few entries
	p.prevkey=0 -- if not 0 then the previous file key if we are split over a few entries

	p.data="" -- the actual data, max length of ( 1000 * 1000 ) 1meg decimal
	p.size=0 -- the size of the data in this chunk
	
	dat.build_cache(ent) -- this just copies the props across
	
-- these are json only vars
	local c=ent.cache

	return check(srv,ent)
end
]]

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
-- Save to database
-- this calls check before putting and does not put if check says it is invalid
-- build_props is called so code should always be updating the cache values
--
--------------------------------------------------------------------------------
--[[
function put(srv,ent,t)

	t=t or dat -- use transaction?

	local _,ok=check(srv,ent) -- check that this is valid to put
	if not ok then return nil end

	dat.build_props(ent)
	local ks=t.put(ent)
	
	if ks then
		ent.key=dat.keyinfo( ks ) -- update key with new id
		dat.build_cache(ent)
	end

	return ks -- return the keystring which is an absolute name
end
]]

--------------------------------------------------------------------------------
--
-- Load from database, pass in id or entity
-- the props will be copied into the cache
--
--------------------------------------------------------------------------------
--[[
function get(srv,id,t)

	local ent=id
	
	if type(ent)~="table" then -- get by id
		ent=create(srv)
		ent.key.id=id
	end
	
	t=t or dat -- use transaction?
	
	if not t.get(ent) then return nil end	
	dat.build_cache(ent)
	
	return check(srv,ent)
end
]]


--------------------------------------------------------------------------------
--
-- get - update - put
--
-- f must be a function that changes the entity and returns true on success
-- id can be an id or an entity from which we will get the id
--
--------------------------------------------------------------------------------
--[[
function update(srv,id,f)

	if type(id)=="table" then id=id.key.id end -- can turn an entity into an id
		
	for retry=1,10 do
		local mc={}
		local t=dat.begin()
		local e=get(srv,id,t)
		if e then
			what_memcache(srv,e,mc) -- the original values
			if e.props.created~=srv.time then -- not a newly created entity
				if e.cache.updated>=srv.time then t.rollback() return false end -- stop any updates that time travel
			end
			e.cache.updated=srv.time -- the function can change this change if it wishes
			if not f(srv,e) then t.rollback() return false end -- hard fail
			check(srv,e) -- keep consistant
			if put(srv,e,t) then -- entity put ok
				if t.commit() then -- success
					what_memcache(srv,e,mc) -- the new values
					fix_memcache(srv,mc) -- change any memcached values we just adjusted
					return e -- return the adjusted entity
				end
			end
		end
		t.rollback() -- undo everything ready to try again
	end
	
end
]]

--------------------------------------------------------------------------------
--
-- given an entity return or update a list of memcache keys we should recalculate
-- this list is a name->bool lookup
--
--------------------------------------------------------------------------------
--[[
function what_memcache(srv,ent,mc)
	local mc=mc or {} -- can supply your own result table for merges	
	local c=ent.cache
	
	mc[ cache_key(c.id) ] = true
	
	return mc
end
]]

--------------------------------------------------------------------------------
--
-- fix the memcache items previously produced by what_memcache
-- probably best just to delete them so they will automatically get rebuilt
--
--------------------------------------------------------------------------------
--[[
function fix_memcache(srv,mc)
	for n,b in pairs(mc) do
		cache.del(srv,n)
--		srv.cache[n]=nil
	end
end
]]

--------------------------------------------------------------------------------
--
-- like find but with as much cache as we can use so ( no transactions available )
--
--------------------------------------------------------------------------------
function cache_get_data(srv,id)

	local ck="type=ent.data&data.file="..id
	local ret=cache.get(srv,ck)
	
	if ret then -- got cach
		return ret
	else
		ent=get(srv,id)
		if ent and ent.cache.nextkey==0 then -- we can cache this as it is small
			ret={cache={data=ent.cache.data,mimetype=ent.cache.mimetype,nextkey=0}}
			cache.put(srv,ck,ret,60*60)
			return ret
		end
		return ent
	end
end



--------------------------------------------------------------------------------
--
-- delete this id and its linked data
--
--------------------------------------------------------------------------------
function delete(srv,id)

	if id==0 then return end -- nothing to do

	local mc={}
	
	mc[ "type=ent.data&data.file="..id ]=true
	
	local e=get(srv,id) -- get entity first
	if e then
		cache_what(srv,e,mc) -- the new values
		dat.del(e.key) -- delete first chunk
		while e.cache.nextkey~=0 do -- 0 termed			
			e=get(srv,e.cache.nextkey) -- get entity first
			cache_what(srv,e,mc) -- the new values
			dat.del(e.key) -- delete linked chunk
		end

		cache_fix(srv,mc) -- change any memcached values we just adjusted
	end

end



dat.set_defs(_M) -- create basic data handling funcs

if not ngx then
	function cache_key(srv,id) -- disable cache, we have gae binary problems...
		return nil
	end
end

dat.setup_db(_M) -- make sure DB exists and is ready
