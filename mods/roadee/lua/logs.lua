-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require


local whtml=require("wetgenes.html")
local wjson=require("wetgenes.json")
local wstr=require("wetgenes.string")

local log=require("wetgenes.www.any.log").log -- grab the func from the package

local sys=require("wetgenes.www.any.sys")
local dat=require("wetgenes.www.any.data")
local cache=require("wetgenes.www.any.cache")
local users=require("wetgenes.www.any.users")
local fetch=require("wetgenes.www.any.fetch")
local img=require("wetgenes.www.any.img")


--local ngx=ngx

--module
local M={ modname=(...) } ; package.loaded[M.modname]=M


M.default_props=
{
	data_time=0,
	data_name="",
	data_id="",			-- the image data key (image is actually stored in main data table)

}

M.default_cache=
{
}

function M.kind(srv)
	local n="roadee.logs"
	local f=srv and srv.flavour or ""
	if f=="roadee" then f="" end
	if f=="" then return n else return f.."."..n end
end


--------------------------------------------------------------------------------
--
-- check that entity has initial data and set any missing defaults
-- the second return value is false if this is not a valid entity
--
--------------------------------------------------------------------------------
function M.check(srv,ent)

	return ent
end

--------------------------------------------------------------------------------
--
-- delete this id and its linked data
--
--------------------------------------------------------------------------------
function M.delete(srv,id)

	if id==0 then return end -- nothing to do

	local mc={}
	
	local e=M.get(srv,id) -- get entity first
	if e then
		cache_what(srv,e,mc) -- the new values
		dat.del(e.key) -- delete first chunk
		cache_fix(srv,mc) -- change any memcached values we just adjusted

		data.delete(srv,{id=e.cache.data_id}) -- remove images from data

	end

end


--------------------------------------------------------------------------------
--
-- list pages
--
--------------------------------------------------------------------------------
function M.list(srv,opts,t)
	opts=opts or {} -- stop opts from being nil
	
	t=t or dat -- use transaction?
	
	local q={
		kind=M.kind(srv),
		limit=opts.limit or 100,
		offset=opts.offset or 0,
	}
	
	dat.build_qq_filters(opts,q,{"created"})

	local r=t.query(q)
		
	for i=1,#r.list do local v=r.list[i]
		dat.build_cache(v)
		M.check(srv,v)
	end

	return r.list
end




dat.set_defs(M) -- create basic data handling funcs

dat.setup_db(M) -- make sure DB exists and is ready
