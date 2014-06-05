-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local export,lookup,set_env=require("wetgenes"):export("export","lookup","set_env")

-- base modules
local mime=require("mime")
local wjson=require("wetgenes.json")
local wstr=require("wetgenes.string")
local whtml=require("wetgenes.html")

--pagecake base modules
local sys=require("wetgenes.www.any.sys")
local dat=require("wetgenes.www.any.data")
local users=require("wetgenes.www.any.users")
local stash=require("wetgenes.www.any.stash")
local img=require("wetgenes.www.any.img")
local oauth=require("wetgenes.www.any.oauth")
local fetch=require("wetgenes.www.any.fetch")
local cache=require("wetgenes.www.any.cache")

--pagecake mods
local d_sess =require("dumid.sess")
local d_users=require("dumid.users")

-- debug functions
local dprint=function(...)print(wstr.dump(...))end
local log=require("wetgenes.www.any.log").log


--module
local M={ modname=(...) } ; package.loaded[M.modname]=M
M.export=export

M.bearer=function(srv)
	local url="https://api.twitter.com/oauth2/token"
	
	local ret=cache.get(srv,url)
	if ret then return ret end
	
	local secret=srv.opts("twitter","secret") or "secret"
	local key=srv.opts("twitter","key") or "key"
	local sk64=oauth.b64(oauth.esc(key)..":"..oauth.esc(secret))
	
	local headers={
			["Authorization"]		=	"Basic "..sk64,
			["Content-Type"]		=	"application/x-www-form-urlencoded;charset=UTF-8",
	}

	local ret=fetch.post(url,headers,"grant_type=client_credentials")
	local j=wjson.decode(ret.body)
	
--	dprint(ret)

	local ret
	
	if j.token_type=="bearer" then ret=j.access_token end

	if ret then
		cache.put(srv,url,ret)
	end
	
	return ret
end

M.search=function(srv,opts)

	local headers={
		["Authorization"]="Bearer "..M.bearer(srv),
	}

-- build url from opts
	local url="https://api.twitter.com/1.1/search/tweets.json"
	local t={url,"?"}
	for n,v in pairs(opts) do
		t[#t+1]=n
		t[#t+1]="="
		t[#t+1]=oauth.esc(v)
		t[#t+1]="&"
	end
	t[#t]=nil -- remove trailing & or ? then build url string
	url=table.concat(t)
	
	local ret=fetch.get(url,headers)
	local j
	if ret.body then
		j=wjson.decode(ret.body)
	end
	
	return j
end

--[=[

module("port.twitter")

--
-- make a twat update
--
-- it.user -- the user (must be a twitter user)
-- it.text -- 140 characters
--

function post(srv,it) --TODO--NOW--
local it=it or {}

-- check it is a twitter user before going further
	if not lookup(it,"user","cache","authentication","twitter","secret") then return end

	local v={}
	v.oauth_timestamp , v.oauth_nonce = oauth.time_nonce("sekrit")
	v.oauth_consumer_key = srv.opts("twitter","key")
	v.oauth_signature_method="HMAC-SHA1"
	v.oauth_version="1.0"
		
	v.oauth_token=lookup(it,"user","cache","authentication","twitter","token")
	v.status=it.text

	local o={}
	o.post="POST"
	o.url="http://api.twitter.com/1/statuses/update.json"
	v.tok_secret=lookup(it,"user","cache","authentication","twitter","secret")
	o.api_secret=srv.opts("twitter","secret")
	
	local k,q = oauth.build(v,o)
	local b={}
	
	for _,n in pairs({"status"}) do
		b[n]=v[n]
		v[n]=nil
	end
	v.oauth_signature=k

	local vals={}
	for ii,iv in pairs(b) do
		vals[#vals+1]=oauth.esc(ii).."="..oauth.esc(iv)
	end
	local q=table.concat(vals,"&")
	
	local auths={}
	for ii,iv in pairs(v) do
		auths[#auths+1]=oauth.esc(ii).."=\""..oauth.esc(iv).."\""
	end

	local got=fetch.post(o.url.."?"..q,
		{
			["Authorization"]="OAuth "..table.concat(auths,", "),
			["Content-Type"]="x-www-form-urlencoded; charset=utf-8",
		},q) -- get from internets

end

]=]
