-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local sys=require("wetgenes.www.any.sys")
local wet_html=require("wetgenes.html")
local replace=wet_html.replace
local url_esc=wet_html.url_esc

local html=require("html")

local fetch=require("wetgenes.www.any.fetch")

local cache=require("wetgenes.www.any.cache")

local log=require("wetgenes.www.any.log").log -- grab the func from the package

local json=require("wetgenes.json")
local wstr=require("wetgenes.string")

module("waka.picasa")

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
				log("WAKA PICASA HOOK:"..err)
			end
		end
		s=t--wstr.serialize(t)
	else
		s=err or "PICASSA IMPORT fail please reload page to try again."
	end

	return s
end

--
-- get data from internets or cache
--
function get(srv,opts)

-- https://picasaweb.google.com/data/feed/api/user/krissd/album/test?kind=photo&access=public&alt=json&start-index=1&max-results=1

	local tq=(opts.query or "select *").." limit "..opts.limit.." offset "..opts.offset
	local url

	url="https://picasaweb.google.com/data/feed/api/user/"..opts.user.."/album/"..opts.album.."?kind=photo&alt=json"
--	if opts.offset then url=url.."&start-index="..opts.offset end
--	if opts.limit then url=url.."&max-results="..opts.limit end

	if opts.authkey then url=url.."&authkey="..opts.authkey end

	local cachename="waka_picassa&"..url_esc(url)
	local datastr
	local err
	
	local data=cache.get(srv,cachename) -- check cache
--log(tostring(data))
	if data then return data end
	
	if not datastr then -- we didnt got it from the cache?
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
				return datastr,err
			end
			datastr=d
		end
	end
	
--	local origsize=0
	
	if datastr then
	
--		origsize=datastr:len() or 0
		local suc,dat
		suc,dat=pcall(function() return json.decode(datastr) end) -- convert from json, hopefully
		
		if suc and dat then
			data={}
			for i,v in ipairs( (dat and dat.feed and dat.feed.entry) or {}) do
				local d={}
				d.src=v.content.src:gsub("(/[^/]-)$","/s0%1")
				d.title=(v.summary and v.summary["$t"]) or ""
				d.width=tonumber(v["gphoto$width"]["$t"])
				d.height=tonumber(v["gphoto$height"]["$t"])
				d.album=v["gphoto$albumid"]["$t"]
				d.photo=v["gphoto$id"]["$t"]
				data[#data+1]=d
			end
			cache.put(srv,cachename,data,60*60)
		end -- cache for an hour
	end
		
	return data,err
end
