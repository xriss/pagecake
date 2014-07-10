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
	hot=0,				-- a hot ranking metric for sorting, higher is better
	bad=0,				-- a bad ranking metric for sorting, higher is worse

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
	
	palette="",			-- name of pallete used
	shader="",			-- name of shader used
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

-- added some fields, patch them up
	local p=ent.props
	p.hot=p.hot or 0
	p.bad=p.bad or 0

	local c=ent.cache
	c.hot=c.hot or 0
	c.bad=c.bad or 0

-- minimum size is pix size...
	c.min_width=pix_width
	c.min_height=pix_height
-- ...with fixed aspect	
	if     c.fat_width >c.fat.height then c.min_width =math.floor(c.min_width *c.fat_width/ c.fat_height)
	elseif c.fat_height>c.fat.width  then c.min_height=math.floor(c.min_height*c.fat_height/c.fat_width)
	end

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

		data.delete(srv,{id=e.cache.pix_id}) -- remove images from data
		data.delete(srv,{id=e.cache.fat_id})

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
	
	dat.build_qq_filters(opts,q,{"userid","day","hot","bad","created"})

	local r=t.query(q)
		
	for i=1,#r.list do local v=r.list[i]
		dat.build_cache(v)
		M.check(srv,v)
	end

	return r.list
end




dat.set_defs(M) -- create basic data handling funcs

dat.setup_db(M) -- make sure DB exists and is ready
