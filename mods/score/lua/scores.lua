
local json=require("wetgenes.json")

local dat=require("wetgenes.aelua.data")
local cache=require("wetgenes.aelua.cache")

local log=require("wetgenes.aelua.log").log -- grab the func from the package

local fetch=require("wetgenes.aelua.fetch")
local sys=require("wetgenes.aelua.sys")


local os=os
local string=string
local math=math

local tostring=tostring
local type=type
local ipairs=ipairs

local wet_string=require("wetgenes.string")
local str_split=wet_string.str_split
local serialize=wet_string.serialize

module("score.scores")
dat.set_defs(_M) -- create basic data handling funcs


default_props=
{
	game="", -- the nameof the game
	owner="", -- email@id of owner
	score=0, -- the score
	ip="",
}


default_cache=
{
}



--------------------------------------------------------------------------------
--
-- allways this kind
--
--------------------------------------------------------------------------------
function kind(srv)
	return "score.scores"
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
		
	return ent,ok
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
	for i,v in ipairs{"game","owner","<score",">score"} do
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
	
	if opts.sort=="updated"  then q[#q+1]={"sort","updated","DESC"} -- newest updated
	elseif opts.sort=="score"  then q[#q+1]={"sort","score","DESC"} -- newest updated
	end
	
	local r=t.query(q)
		
	for i=1,#r.list do local v=r.list[i]
		dat.build_cache(v)
	end

	return r.list
end




