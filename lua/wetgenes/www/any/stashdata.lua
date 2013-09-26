-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local log=require("wetgenes.www.any.log").log

local dat=require("wetgenes.www.any.data")



module(...)
local _M=require(...)
local wdata=require("wetgenes.www.any.data")

default_props=
{
	group="", -- possible grouping of cache, (so we can clear an entire group at once)
}

default_cache=
{
	base=nil,  --
	func=nil,  -- require(base).func(srv,id) to rebuild this stash
	data={},  -- the data we stashed
}


--------------------------------------------------------------------------------
--
-- allways this kind
--
--------------------------------------------------------------------------------
function kind(srv)
	return "stash"
end

--------------------------------------------------------------------------------
--
-- check that entity has initial data and set any missing defaults
--
--------------------------------------------------------------------------------
function check(srv,ent)

	local c=ent.cache
		
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
	for i,v in ipairs{"group"} do
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
	
	local r=t.query(q)
		
	for i=1,#r.list do local v=r.list[i]
		dat.build_cache(v)
	end

	return r.list
end






wdata.set_defs(_M) -- create basic data handling funcs

wdata.setup_db(_M) -- make sure DB exists and is ready


