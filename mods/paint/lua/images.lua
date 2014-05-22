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

-- the key is user/day so you only get one image upload per user per day

	userid="",			-- the userid this image belongs to
	day=0,				-- the day this image belongs to (days since 1970)
	rank=0,				-- a ranking metric for sorting, higher is better (and -1 causes this image to be hidden)

	pix_id="",			-- the image data key (image is actually stored in main data table)
	pix_mimetype="",	-- the mime type of image
	pix_width=0,		-- width
	pix_height=0,		-- height
	pix_depth=0,		-- number of frames

	fat_id="",			-- the image data key (image is actually stored in main data table)
	fat_mimetype="",	-- the mime type of image
	fat_width=0,		-- width
	fat_height=0,		-- height
	fat_depth=0,		-- number of frames
}

M.default_cache=
{
	user_name="",		-- the user name this image belongs to
	title="",			-- the title (challenge) for this day
}

function M.kind(srv)
	local n="paint.images"
	local f=srv and srv.flavour or ""
	if f=="paint" then f="" end
	if f=="" then return n else return f.."."..n end
end


--------------------------------------------------------------------------------
--
-- check that entity has initial data and set any missing defaults
-- the second return value is false if this is not a valid entity
--
--------------------------------------------------------------------------------
function M.check(srv,ent)

	local ok=true

	local c=ent.cache
			
	return ent
end

--------------------------------------------------------------------------------
--
-- like find but with as much cache as we can use so ( no transactions available )
--
--------------------------------------------------------------------------------
function M.cache_get_data(srv,id)

	local ck="type=ent.paint&paint.image="..id
	local ret=cache.get(srv,ck)
	
	if ret then -- got cach
		return ret
	else
		ent=M.get(srv,id)
		ret={cache=ent.cache}
		cache.put(srv,ck,ret,60*60)
		return ret
	end
end



--------------------------------------------------------------------------------
--
-- delete this id and its linked data
--
--------------------------------------------------------------------------------
function M.delete(srv,id)

	if id==0 then return end -- nothing to do

	local mc={}
	
	mc[ "type=ent.paint&paint.image="..id ]=true
	
	local e=M.get(srv,id) -- get entity first
	if e then
		cache_what(srv,e,mc) -- the new values
		dat.del(e.key) -- delete first chunk
		cache_fix(srv,mc) -- change any memcached values we just adjusted
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
	
	dat.build_qq_filters(opts,q,{"userid","day","rank","created"})
print(wstr.dump(opts))
print(wstr.dump(q))

	local r=t.query(q)
		
	for i=1,#r.list do local v=r.list[i]
		dat.build_cache(v)
	end

	return r.list
end




dat.set_defs(M) -- create basic data handling funcs

dat.setup_db(M) -- make sure DB exists and is ready
