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

-- the key is just the day, so you only get one plot per day

	day=0,				-- the day this plot belongs to (days since 1970)

	pix_width=0,		-- width
	pix_height=0,		-- height
	pix_depth=0,		-- number of frames

	pix_name,			-- code name for resolution of image
	pal_name,			-- code name for palette of image
	fat_name,			-- code name for fat style of image eg "3x3,bloom++","4x,escher"
	
}

M.default_cache=
{
	style="",			-- json style settings that we squirt across to the client, size,fat,pal 
	title="",			-- the title (challenge) for this day
}

function M.kind(srv)
	local n="paint.plots"
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
	
	dat.build_qq_filters(opts,q,{"day",
		"pix_width","pix_height","pix_depth",
		"pix_name","pal_name","fat_name"})

	local r=t.query(q)
		
	for i=1,#r.list do local v=r.list[i]
		dat.build_cache(v)
	end

	return r.list
end


dat.set_defs(M) -- create basic data handling funcs

dat.setup_db(M) -- make sure DB exists and is ready
