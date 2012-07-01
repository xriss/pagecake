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

module("comic.comics")
local _M=require(...)


default_props=
{
	group="", -- the comic group, eg pms
	name="", -- the comic name a hopefully unique name
	pubdate=0, -- the time of publishing
	width=0, -- the width of image
	height=0, -- the height of image
	random=0, -- random number to sort by
--	tags={}, -- our tags
}


default_cache=
{
	icon="", -- 100x100 icon as a site url, IE /data/something
	title="", -- the comic title
	image="", -- image as a site url, IE /data/something
	body="", -- main body text for under the comic
}



--------------------------------------------------------------------------------
--
-- allways this kind
--
--------------------------------------------------------------------------------
function kind(srv)
	return "comic.comics"
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
	
	if not c.random then c.random=math.random() end
		
	return ent
end



--------------------------------------------------------------------------------
--
-- list pages
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
	for i,v in ipairs{"name","group","<pubdate",">pubdate","<random",">random"} do
		if opts[v] then
			local t=type(opts[v])
			if t=="string" or t=="number" then
				local c=v:sub(1,1)
				if c==">" then
					q[#q+1]={"filter",v:sub(2),">",opts[v]}
				elseif c=="<" then
					q[#q+1]={"filter",v:sub(2),"<",opts[v]}
				else
					q[#q+1]={"filter",v,"==",opts[v]}
				end
			else
				if t=="table" then
					q[#q+1]={"filter",v,"in",opts[v]}
				end
			end
		end
	end
	
	if     opts.sort=="pubdate"  then q[#q+1]={"sort","pubdate","DESC"} -- newest published
	elseif opts.sort=="updated"  then q[#q+1]={"sort","updated","DESC"} -- newest updated

	elseif opts.sort=="-pubdate" then q[#q+1]={"sort","pubdate","DESC"} -- newest published
	elseif opts.sort=="+pubdate" then q[#q+1]={"sort","pubdate","ASC"}  -- oldest published
	elseif opts.sort=="-random" then q[#q+1]={"sort","random","DESC"} -- random order
	elseif opts.sort=="+random" then q[#q+1]={"sort","random","ASC"}  -- random order
	end
	
	local r=t.query(q)
		
	for i=1,#r.list do local v=r.list[i]
		dat.build_cache(v)
	end

	return r.list
end







dat.set_defs(_M) -- create basic data handling funcs

dat.setup_db(_M) -- make sure DB exists and is ready


