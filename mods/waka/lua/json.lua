-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local sys=require("wetgenes.www.any.sys")
local wet_html=require("wetgenes.html")
local replace=wet_html.replace
local url_esc=wet_html.url_esc

local html=require("base.html")

local fetch=require("wetgenes.www.any.fetch")

local cache=require("wetgenes.www.any.cache")
local stash=require("wetgenes.www.any.stash")

local log=require("wetgenes.www.any.log").log -- grab the func from the package

local json=require("wetgenes.json")
local wstr=require("wetgenes.string")

module("waka.json")

-- build a waka chunk
function getwaka(srv,opts)

	local s=""
	local t,err=get(srv,opts)
	local o={}
	
	if t then
		for i,v in pairs(opts) do t[i]=v end -- copy opts into the return
		
		if opts.hook then -- update this stuff?
			local flag,err=pcall(opts.hook,t)
			if not flag and err then
				log("WAKA JSON HOOK:"..err)
			end
		end
		s=t--wstr.serialize(t)
	else
		s=err or "JSON IMPORT fail please reload page to try again."
	end

	return s
end

--
-- get data from internets or cache
--
function get(srv,opts)

-- https://picasaweb.google.com/data/feed/api/user/krissd/album/test?kind=photo&access=public&alt=json&start-index=1&max-results=1
-- http://www.facebook.com/feeds/page.php?id=193837337360896&format=json

	local url=opts.url
	
	local cachetime=opts.cachetime or (60*60*24)
	
	local cachename="waka_json&"..url_esc(url)
	local datastr
	local err
	
	local meta=stash.get(srv,cachename) -- check cache
	local data=meta.data
	if meta.updated+(cachetime) < srv.time then -- cache for 24 hours
		data=nil
	end
	
--log(tostring(data))
	if data then return data end
	
	datastr,err=fetch.get(url) -- get from internets
--log(url)
	if err then
		log(err)
	end
	if datastr then datastr=datastr.body end -- check
--log(tostring(datastr))
	if type(datastr)=="string" then -- trim some junk get string within the outermost {}
		local d=datastr:match("^[^{]*(.-)[^}]*$")
		if not d then
			return nil,err
		end
		datastr=d
	end
	
--	local origsize=0
	
	if datastr then -- got some data
	
--		origsize=datastr:len() or 0
		local suc
		suc,data=pcall(function() return json.decode(datastr) end) -- convert from json, hopefully
		
		if suc and data then
			stash.put(srv,cachename,{data=data})
		end -- cache for an hour
	end
		
	return data,err
end


--[[

#test form=import

import="json"

url="http://www.facebook.com/feeds/page.php?id=193837337360896&format=json"
cachetime=60*60

plate="testplate"

hook=function(t)
	if t and t.entries then
		local r={}
		for i,v in ipairs(t.entries) do
			r[#r+1]=v
		end
		for i=1,#t do t[i]=nil end -- clear all
		for i,v in ipairs(r) do t[#t+1]=v end -- insert the ones we remembered
	end
end

#testplate

<div>
<h1><a href="{it.alternate}">{it.title}</a></h1>
{it.content}</div>


]]
