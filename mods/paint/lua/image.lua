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

--local ngx=ngx

--module
local M={ modname=(...) } ; package.loaded[M.modname]=M


M.default_props=
{

-- the key is user/day so you only get one image upload per user per day

	user="",		-- the user this image belongs to
	day=0,			-- the day this image belongs to (days since 1970)
	title="",		-- the title (challenge) for this day
	rank=0,			-- a ranking metric for sorting (-1 to hide)

	pix_data="",	-- the image data	(<256k enforced limit)
	pix_mime="",	-- the mime type of image
	pix_width=0,	-- width
	pix_height=0,	-- height
	pix_depth=0,	-- number of frames

	fat_data="",	-- the image data	(<256k enforced limit)
	fat_mime="",	-- the mime type of image
	fat_width=0,	-- width
	fat_height=0,	-- height
	fat_depth=0,	-- number of frames
}

M.default_cache=
{
}

function M.kind(srv)
	local f=srv.flavour or "" ; if f=="paint" then f="" end
	return f..".paint.image"
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
		ent=get(srv,id)
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
	
	local e=get(srv,id) -- get entity first
	if e then
		cache_what(srv,e,mc) -- the new values
		dat.del(e.key) -- delete first chunk
		cache_fix(srv,mc) -- change any memcached values we just adjusted
	end

end



dat.set_defs(M) -- create basic data handling funcs

if not ngx then
	function M.cache_key(srv,id) -- disable cache, we have gae binary problems...
		return nil
	end
end

dat.setup_db(M) -- make sure DB exists and is ready
