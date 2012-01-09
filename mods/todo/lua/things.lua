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

module("todo.things")
local _M=require(...)

-- the key used should be a local url id eg "/todo/something" this is also the waka page for more data
default_props=
{
	title="", -- a cache of the title of the waka page
	total=0, -- total of all "good" pledges
	count=0, -- count of "good" pledges
	state="none",
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
	return "todo.thing"
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
-- fill a thing with the given data
--
--------------------------------------------------------------------------------
function fill(srv,it,tab)

	local it=it or create(srv)
	
	it.key.id=tab.id -- set id
	it.cache.id=tab.id
	
	it.props.title=tab.title -- set title
	it.cache.title=tab.title

	return it
end



--------------------------------------------------------------------------------
--
-- list comments
--
--------------------------------------------------------------------------------
function list(srv,opts,t)
	opts=opts or {} -- stop opts from being nil
	
	t=t or dat -- use transaction?
	
	local q={
		kind=kind(srv),
		limit=opts.limit or 100,
		offset=opts.offset or 0,
	}
-- add filters?
	for i,v in ipairs{"id","state"} do
		if opts[v] then
			local t=type(opts[v])
			if t=="string" or t=="number" then
				q[#q+1]={"filter",v,"==",opts[v]}
			end
		end
	end

-- sort by?
	if opts.sortdate then
		q[#q+1]={"sort","updated", opts.sortdate }
	end
	if opts.sortmake then
		q[#q+1]={"sort","created", opts.csortdate }
	end
	
	local r=t.query(q)

	for i=1,#r.list do local v=r.list[i]
		dat.build_cache(v)
	end

	return r.list
end



dat.set_defs(_M) -- create basic data handling funcs

dat.setup_db(_M) -- make sure DB exists and is ready


