-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local json=require("wetgenes.json")

local dat=require("wetgenes.www.any.data")
local cache=require("wetgenes.www.any.cache")

local log=require("wetgenes.www.any.log").log -- grab the func from the package

local fetch=require("wetgenes.www.any.fetch")
local sys=require("wetgenes.www.any.sys")


local wstr=require("wetgenes.string")
local wet_string=wstr
local str_split=wet_string.str_split
local serialize=wet_string.serialize

local wxml=require("wetgenes.simpxml")

local ngx=ngx

-- replacement version of module that does not global
local module=function(modname, ...)
	local ns={ _NAME = modname , _PACKAGE = string.gsub (modname, "[^.]*$", "") }
	ns._M = ns
	package.loaded[modname] = ns
	setfenv (2, ns)
	for _,f in ipairs({...}) do f(ns) end
end
module("dumid.users")
--local _M=require(...)

default_props=
{
	flavour="",
	email  ="", -- this is a duplicate of the userid or a real email
	name   ="",
	parent ="", -- set to a parent userid for linked accounts
	ip="", -- last known ip or blank if unknown
	type="ok", -- flag as spam if spammer
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
	return "user.data"
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
		
	return ent
end



-----------------------------------------------------------------------------
--
-- Make sure this userid exists (with limited info)
--
-----------------------------------------------------------------------------
function manifest_userid(srv,userid,name,flavour)

	set(srv,userid,function(srv,e)
	
		if not e.key.notsaved then return true end -- already exists so we do nothing
		
		fill(srv,e,{userid=userid,name=name,flavour=flavour}) -- setup some rather dumb defaults
		
		return true
	end)
	
end

-----------------------------------------------------------------------------
--
-- Make a new local user data, ready to be put
--
-----------------------------------------------------------------------------
function fill(srv,user,tab)

	local user=user or create(srv)
	
	if not tab.name or tab.name=="" or tab.name==tab.userid then
	
		user.cache.name=str_split("@",tab.userid)[1] -- build a short name from email
		user.cache.name=string.sub(user.cache.name,1,32)
		
	else
	
		user.cache.name=tab.name -- use given name
		
	end

	userid=string.lower(tab.userid)

	user.key.id=userid -- each userid is unique
	user.cache.id=user.key.id

	user.cache.flavour=tab.flavour -- provider hint, we can mostly work this out from the email if missing
	
	user.cache.email=tab.userid -- repeat the key as the email (but allow upper case here)

	return user
end



--------------------------------------------------------------------------------
--
-- Load a list of users
--
--------------------------------------------------------------------------------
function list(srv,opts)
local H=srv.H
opts=opts or {}

	local list={}
	
	local q={
		kind=kind(srv),
		limit=opts.limit or 10,
		offset=opts.offset or 0,
		}	
	dat.build_qq_filters(opts,q,{"flavour","email","name","parent","ip","type","updated","created"})
--	q[#q+1]={"sort","updated","DESC"}
		
	local ret=dat.query(q)
		
	for i=1,#ret.list do local v=ret.list[i]
		dat.build_cache(v)
	end

	return ret.list
end







-----------------------------------------------------------------------------
--
-- convert a userid into a profile link, a 16x16 icon linked to a profile (html)
-- returns nil if we cant
-- also returns bare profile url in second argument
--
-----------------------------------------------------------------------------
function get_profile_link(userid)

	local url="/profile/"..userid
	local profile="<a href="..url.."><img src=\"/art/base/icon_goog.png\" /></a>"

	local endings={"@id.wetgenes.com"}
	for i,v in ipairs(endings) do
		if string.sub(userid,-#v)==v then
			profile="<a href="..url.."><img src=\"/art/base/icon_wet.png\" /></a>"
		end
	end

	local endings={"@id.facebook.com"}
	for i,v in ipairs(endings) do
		if string.sub(userid,-#v)==v then
			profile="<a href="..url.."><img src=\"/art/base/icon_fb.png\" /></a>"
		end
	end

	local endings={"@id.twitter.com"}
	for i,v in ipairs(endings) do
		if string.sub(userid,-#v)==v then
			profile="<a href="..url.."><img src=\"/art/base/icon_twat.png\" /></a>"
		end
	end
	
	local endings={"@id.google.com"}
	for i,v in ipairs(endings) do
		if string.sub(userid,-#v)==v then
			profile="<a href="..url.."><img src=\"/art/base/icon_goog.png\" /></a>"
		end
	end

	return profile,url
end

-----------------------------------------------------------------------------
--
-- convert a userid into an avatar image url, 100x100 loaded via /thumbcache/100/100
-- so we cache it on site, pass in w,h for alternative sized avatar
--
-- this function may hit external sites and take some time to run
-- so cache its result and do not call this multiple times every page render
--
-----------------------------------------------------------------------------
function get_avatar_url(srv,userid,w,h)
	srv=srv or (ngx and ngx.ctx)
	
	local user=nil
	
	w=w or 100
	h=h or 100
	local email=userid


	if type(userid)=="table" then
		user=userid
		userid=user.id or ""
		email=(user.cache and user.cache.email) or user.email or userid
	end
	
	if type(userid)=="string" then userid=userid:lower() end
	if type(email) =="string" then email = email:lower() end
	local url="/www.gravatar.com/avatar/"..sys.md5(email):lower().."?s=200&d=identicon&r=x"

	local curl
	if srv then curl=cache.get(srv,"avatar_from_userid="..userid) end
	if curl then -- check cache
		url=curl
--log("got cache"..curl)
	else -- build cache

		local endings={"@id.wetgenes.com"}
		for i,v in ipairs(endings) do
			if string.sub(userid,-#v)==v then
				url="/api.wetgenes.com:1408/genes/avatar/$"..string.sub(userid,1,-(#v+1))
			end
		end

		local endings={"@id.facebook.com"}
		for i,v in ipairs(endings) do
			if string.sub(userid,-#v)==v then
				url="/graph.facebook.com/"..string.sub(userid,1,-(#v+1)).."/picture?type=large"
			end
		end

		local endings={"@id.twitter.com"}
		for i,v in ipairs(endings) do
			if string.sub(userid,-#v)==v then
			
			if user then
				if user.info then
					if user.info.profile_image_url then
						url="/"..user.info.profile_image_url:sub(8)
						url=url:gsub("%_normal%.","%.") -- needing this is fucking twitarded
						url=url:gsub("%_bigger%.","%.") -- needing this is fucking twitarded
					end
				end
	--			log(wstr.dump(user))
			end

			end
		end
		
		local endings={"@id.steamcommunity.com"}
		for i,v in ipairs(endings) do
			if string.sub(userid,-#v)==v then

				local id=userid:sub(1,-#v-1)
				local got=fetch.get("http://steamcommunity.com/profiles/"..id.."/?xml=1")
				if type(got.body)=="string" then
					local x=wxml.parse(got.body)
					if x then
						local avatar=wxml.descendent(x,"avatarfull")
						if avatar then
							url="/"..(avatar[1]):sub(8) -- skip "http://"
						end
					end
				end

			end
		end	


		local endings={"@id.google.com"}
		for i,v in ipairs(endings) do
			if string.sub(userid,-#v)==v then
				local id=userid:sub(1,-#v-1)
				local icon=nil
				local hax=fetch.get("https://plus.google.com/"..id.."/about")
				if type(hax.body=="string") then
					hax.body:gsub('guidedhelpid="profile_photo"><img src="([^"]+)', function(a,b) icon="http:"..a end , 1)
				end
				if icon then -- got an image from a public google profile
					url="/"..(icon):sub(8) -- skip "http://"
				end
			end
		end
		
		
		if srv then
			cache.put(srv,"avatar_from_userid="..userid,url,60*60*24)
--log("put cache"..url)
		end
	end

	url="/thumbcache/"..w.."/"..h..url
	
	return url -- return nil if no image found
end



dat.set_defs(_M) -- create basic data handling funcs

dat.setup_db(_M) -- make sure DB exists and is ready


