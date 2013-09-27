-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local json=require("wetgenes.json")
local wstr=require("wetgenes.string")

local dat=require("wetgenes.www.any.data")
local cache=require("wetgenes.www.any.cache")

local log=require("wetgenes.www.any.log").log -- grab the func from the package

local fetch=require("wetgenes.www.any.fetch")
local sys=require("wetgenes.www.any.sys")



local waka=require("waka")
local wakapages=require("waka.pages")



--module
local M={ modname=(...) } ; package.loaded[M.modname]=M
function M.kind(srv) return "dimeload.projects" end


M.default_props=
{
	published=0,	-- set to 1 if published
}

M.default_cache=
{
}


--------------------------------------------------------------------------------
--
-- check that entity has initial data and set any missing defaults
-- the second return value is false if this is not a valid entity
--
--------------------------------------------------------------------------------
function M.check(srv,ent)

	local ok=true
	local c=ent.cache
	local p=ent.props
	
	if not p.published then p.published=0 end
		
	return ent
end

--------------------------------------------------------------------------------
--
-- Load a list of active visible projects
--
--------------------------------------------------------------------------------
function M.list(srv,opts)
opts=opts or {}

	local list={}
	
	local q={
		kind=M.kind(srv),
		limit=opts.limit or 10,
		offset=0,
		}
	q[#q+1]={"filter","published","==",1}
	q[#q+1]={"sort","updated","DESC"}
		
	local ret=dat.query(q)
		
	for i=1,#ret.list do local v=ret.list[i]
		dat.build_cache(v)
	end

	return ret.list
end


-----------------------------------------------------------------------------
--
-- hook into waka page updates, any page under will come in here
-- that way we canuse the waka to update our basic data
--
-- page is just an entity get on the page, check its id or whatever before proceding
--
-----------------------------------------------------------------------------
function M.waka_changed(srv,page)

	if not page then return end

	local id=tostring(page.key.id)

--log("check : "..id)

	local projectname
	id:gsub("/dl/([^/]+)",function(s) projectname=s end)

	if not projectname then return end

	local refined=wakapages.load(srv,id)[0]
	local ldat=refined.lua or {} -- better just to use #lua chunk for data, so it can parse and maintain native types

	local it=M.set(srv,projectname,function(srv,e) -- create or update
		local c=e.cache
		
-- grab chunks from this page that we want to associate with this project on other pages

		c.body=""
		c.title=refined.title or ""
		c.about=refined.about or ""
		c.icon=refined.icon or ""
		c.video=refined.video or ""
		c.sitelink=refined.sitelink or "" -- could just be the dimeload page or a special gamesite
		c.name=projectname

		c.published=ldat.published or 0
		c.files=ldat.files or {}

		return true
	end)
		
end


dat.set_defs(M) -- create basic data handling funcs

dat.setup_db(M) -- make sure DB exists and is ready


-- add our hook to the waka stuffs, this should get called on module load
-- We want to catch all edits here and then filter them in the function
waka.add_changed_hook("^/",M.waka_changed)






