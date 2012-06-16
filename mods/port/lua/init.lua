-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local wet_html=require("wetgenes.html")
local replace=wet_html.replace

local sys=require("wetgenes.www.any.sys")

local json=require("wetgenes.json")
local dat=require("wetgenes.www.any.data")

local users=require("wetgenes.www.any.users")

local fetch=require("wetgenes.www.any.fetch")
local cache=require("wetgenes.www.any.cache")

local img=require("wetgenes.www.any.img")

local log=require("wetgenes.www.any.log").log -- grab the func from the package

local wet_string=require("wetgenes.string")
local trim=wet_string.trim
local str_split=wet_string.str_split
local serialize=wet_string.serialize

local wet_waka=require("wetgenes.waka")

local d_sess =require("dumid.sess")

-- require all the module sub parts
local html=require("port.html")
local twitter=require("port.twitter")
local goo=require("port.goo")



-- opts
local opts_twitter=( opts and opts.twitter ) or {}
local opts_mods_port=(opts and opts.mods and opts.mods.port) or {}

module("port")

local function make_put(srv)
	return function(a,b)
		b=b or {}
		b.srv=srv
		srv.put(wet_html.get(html,a,b))
	end
end
local function make_get(srv)
	return function(a,b)
		b=b or {}
		b.srv=srv
		return wet_html.get(html,a,b)
	end
end
-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-----------------------------------------------------------------------------
function serv(srv)
local sess,user=d_sess.get_viewer_session(srv)
local put=make_put(srv)
local get=make_get(srv)
	
	if not( user and user.cache and user.cache.admin ) then -- adminfail
--		return false
	end

	local url=srv.url_base
	if url:sub(-1)=="/" then url=url:sub(1,-2) end -- trim any trailing /
	
	local posts={} -- remove any gunk from the posts input
	-- check if this post probably came from this page before allowing post params
	if srv.method=="POST" and srv:check_referer(url) then
		for i,v in pairs(srv.posts) do
			posts[i]=v
		end
	end
	if posts.submit then posts.submit=trim(posts.submit) end
	
--[[
local oauth=require("wetgenes.www.any.oauth")

	local v={}
	v.oauth_timestamp , v.oauth_nonce = oauth.time_nonce("sekrit")
	v.oauth_consumer_key = opts_twitter.key
	v.oauth_signature_method="HMAC-SHA1"
	v.oauth_version="1.0"
		
	v.oauth_token=user.cache.authentication.twitter.token
	v.status="This is a test twitter update."

	local o={}
	o.post="POST"
	o.url="http://api.twitter.com/1/statuses/update.json"
--	o.url="http://host.local:8008/"
	o.tok_secret=user.cache.authentication.twitter.secret
	o.api_secret=opts_twitter.secret
	
	local k,q = oauth.build(v,o)
	local b={}
	
	for _,n in pairs({"status"}) do
		b[n]=v[n]
		v[n]=nil
	end
	v.oauth_signature=k
	
--	v["Content-Type"]="x-www-form-urlencoded; charset=utf-8"

	local vals={}
	for ii,iv in pairs(b) do
		vals[#vals+1]=oauth.esc(ii).."="..oauth.esc(iv)
	end
	local q=table.concat(vals,"&")
	
	local vals={}
	for ii,iv in pairs(v) do
		vals[#vals+1]=oauth.esc(ii).."=\""..oauth.esc(iv).."\""
	end
	
	local oa="OAuth "..table.concat(vals,", ")

	local got=fetch.post(o.url.."?"..q,{["Authorization"]=oa,["Content-Type"]="x-www-form-urlencoded; charset=utf-8"},q) -- get from internets
		
--	local got=fetch.get(o.url.."?"..q) -- get from internets	
		
]]
	
	local url1="http://www.wetgenes.com"
	local url2=goo.shorten(url1)
	
	srv.set_mimetype("text/html; charset=UTF-8")
	put("header",{title="import",H={user=user,sess=sess}})

	put("this is the port mod<br/><br/>")

	put(url1.."<br/>"..url2.."<br/><br/>")	
	
--[[
	put(oa)	
	put("<br/><br/>")
	put(q)	
	put("<br/><br/>")
	
	put(tostring(got))	
	put("<br/><br/>")
]]
	
	put("footer")
end

