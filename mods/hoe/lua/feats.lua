-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local wet_html=require("wetgenes.html")
local json=require("wetgenes.json")

local dat=require("wetgenes.www.any.data")
local cache=require("wetgenes.www.any.cache")

local users=require("wetgenes.www.any.users")

local img=require("wetgenes.www.any.img")

local log=require("wetgenes.www.any.log").log -- grab the func from the package

local wstr=require("wetgenes.string")
local wet_string=wstr
local str_split=wet_string.str_split
local serialize=wet_string.serialize


-- require all the module sub parts
local html   =require("hoe.html")
local players=require("hoe.players")


-- manage rounds
-- not only may there be many rounds active at once
-- information may still be requested about rounds that have finished

-- replacement version of module that does not global
local module=function(modname, ...)
	local ns={ _NAME = modname , _PACKAGE = string.gsub (modname, "[^.]*$", "") }
	ns._M = ns
	package.loaded[modname] = ns
	setfenv (2, ns)
	for _,f in ipairs({...}) do f(ns) end
end
module("hoe.feats")

--------------------------------------------------------------------------------
--
-- build some top players for the given roundid
-- find the top 3 in a number of catagorys
-- only return wetgenes emails for privacy issues?
--
--------------------------------------------------------------------------------
function get_top_players(srv,round_id)
	local H=srv.H
	
	-- a unique keyname for this query
	local cachekey="feats=get_top_players&round="..round_id

	local r=cache.get(srv,cachekey) -- do we already know the answer
	if r then return json.decode(r) end

	local ret={}
	
	local list=players.list(srv,{sort="score",limit=100,order="DESC",round_id=round_id})
	
	local t={}
	local topscore=1
	for i=1,#list do local v=list[i]
		local crowns=""
		local c=0
		if i==1 then
			topscore=v.cache.score
			if topscore<1 then topscore=1 end -- sane
			c=10
		else
			c=math.floor(10*v.cache.score/topscore)
		end

		if c>10 then c=10 end -- sane
		if c<0  then c=0  end -- sane
		t[#t+1]={ id=v.cache.email , crown=c , score=v.cache.score }
	end
	
	ret.info=t
	
	cache.put(srv,cachekey,json.encode(ret),10*60) -- save this new result for 10 mins
	return ret
end


