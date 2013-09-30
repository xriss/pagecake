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


--module
local M={ modname=(...) } ; package.loaded[M.modname]=M
function M.kind(srv) return "dimeload.users" end


local dl_users=M
local dl_transactions=require("dimeload.transactions")


M.default_props=
{
	dimes=0, -- how many dimes we have bought in total
	spent=0, -- how many dimes we have spent in total
	avail=0, -- how many dimes we have left to spend (dimes-spent)
	
	bitcoin="", -- the bitcoin address that this user accepts bitcoins on (auto created for each user when they try to pay with bitcoin)
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
	c.dimes=c.dimes or 0
	c.spent=c.spent or 0
	c.avail=(c.dimes-c.spent)
	if c.avail<0 then c.avail=0 end
	
	return ent
end



--------------------------------------------------------------------------------
--
-- deposit some dimes, record the transaction
--
--------------------------------------------------------------------------------
function M.deposit(srv,opts)

-- create log entry
	local e=dl_transactions.create(srv)
	local c=e.cache
	c.dimes=opts.dimes
	c.userid=opts.userid
	c.flavour=opts.flavour
	c.source=opts.source
	dl_transactions.put(srv,e)

-- update user dimes
	dl_users.set(srv,opts.userid,function(srv,e) -- create or update
		local c=e.cache
		c.dimes=c.dimes+opts.dimes
		return true
	end)

end

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


dat.set_defs(M) -- create basic data handling funcs

dat.setup_db(M) -- make sure DB exists and is ready







