-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local json=require("wetgenes.json")

local dat=require("wetgenes.www.any.data")
local cache=require("wetgenes.www.any.cache")

local log=require("wetgenes.www.any.log").log -- grab the func from the package

local fetch=require("wetgenes.www.any.fetch")
local sys=require("wetgenes.www.any.sys")


local wet_string=require("wetgenes.string")
local wstr=wet_string
local str_split=wet_string.str_split
local serialize=wet_string.serialize

--module
local M={ modname=(...) } ; package.loaded[M.modname]=M
function M.kind(srv) return "dimeload.downloads" end


M.default_props=
{
	user="", -- who downloaded
	ip="", -- ip of where it was downloaded to

	project="", -- project name
	page="", -- page name (may be "")
	file="", -- file name
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
	q[#q+1]={"sort","updated","DESC"}
		
	local ret=dat.query(q)
		
	for i=1,#ret.list do local v=ret.list[i]
		dat.build_cache(v)
	end

	return ret.list
end

--------------------------------------------------------------------------------
--
-- Check if we should allow a free download retry for this ip
-- 
-- return true if there is a recent log entry
--
--------------------------------------------------------------------------------
function M.allowretry(srv,opts)

	local q={
		kind=M.kind(srv),
		limit=1,
		offset=0,
		}
	q[#q+1]={"sort","updated","DESC"}
	q[#q+1]={"filter","ip","==",opts.ip or srv.ip}
	q[#q+1]={"filter","project","==",opts.project}
	q[#q+1]={"filter","file","==",opts.file}
	q[#q+1]={"filter","updated",">",srv.time-(60*60*4)} -- give a 4 hours download window

	local ret=dat.query(q)

--log(wstr.dump(ret))

	if #ret.list>0 then return true else return false end
end



dat.set_defs(M) -- create basic data handling funcs

dat.setup_db(M) -- make sure DB exists and is ready







