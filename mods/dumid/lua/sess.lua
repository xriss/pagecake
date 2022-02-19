-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local json=require("wetgenes.json")

local dat=require("wetgenes.www.any.data")
local cache=require("wetgenes.www.any.cache")

local log=require("wetgenes.www.any.log").log -- grab the func from the package

local fetch=require("wetgenes.www.any.fetch")
local sys=require("wetgenes.www.any.sys")

local iplog=require("wetgenes.www.any.iplog")


local wet_string=require("wetgenes.string")
local str_split=wet_string.str_split
local serialize=wet_string.serialize

--------------------------------------------------------------------------------
--
-- Time to bite the bullet and clean up the session handling
-- so I can link users together for merged profiles
-- unfortunately this was one of the early bits of code so was
-- designed before I got the hange of using googles datastore
-- in fact it was my first use.
--
-- I hope I do not break anything :)
--
--------------------------------------------------------------------------------

-- replacement version of module that does not global
local module=function(modname, ...)
	local ns={ _NAME = modname , _PACKAGE = string.gsub (modname, "[^.]*$", "") }
	ns._M = ns
	package.loaded[modname] = ns
	setfenv (2, ns)
	for _,f in ipairs({...}) do f(ns) end
end
module("dumid.sess")
--local _M=require(...)

local d_users=require("dumid.users")
local d_nags=require("dumid.nags")


default_props=
{
	userid="", -- who this session belongs too
	ip="", -- and the ip this session belongs to
}

default_cache=
{
}

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function kind(srv)
	return "user.sess"
end

-----------------------------------------------------------------------------
--
-- Check a session ent
--
-----------------------------------------------------------------------------
function check(srv,ent)

	local ok=true
	local c=ent.cache
	local p=ent.props
	
	p.userid=c.userid or ""
	p.ip=c.ip or ""

	c.nags=c.nags or {} -- make sure we always have a nag array

	return ent
end

-----------------------------------------------------------------------------
--
-- Make a local session data, ready to be put
--
-----------------------------------------------------------------------------
function fill(srv,ent,tab)

	local ent=ent or create(srv)
	local p=ent.props
	local c=ent.cache

	ent.key.id=tab.hash
	
	c.userid=tab.user.key.id
	c.ip=srv.ip
	
	return ent
end



-----------------------------------------------------------------------------
--
-- delete all sessions with the given user id
-- 
-----------------------------------------------------------------------------
function del(srv,userid)

	local r=dat.query({
		kind="user.sess",
		limit=100,
		offset=0,
			{"filter","userid","==",userid},
		})
	
	local mc={}
	for i=1,#r.list do local v=r.list[i]
		cache_what(srv,v,mc)
		dat.del(v.key)
	end
	cache_fix(srv,mc) -- remove cache of what was just deleted

end


-----------------------------------------------------------------------------
--
-- get the viewing user session
-- use our cookies and local lookup, not googles
-- googles users can map to our users via dum-id
--
-----------------------------------------------------------------------------
function get_viewer_session(srv)

	if srv.sess and srv.user then return srv.sess,srv.user end -- may be called multiple times
	
	local sess
	
	if srv.cookies.wet_session then -- we have a cookie session to check
	
		sess=get(srv,srv.cookies.wet_session) -- this is probably a cache get
		
		if sess then -- need to validate
			if sess.cache.ip ~= srv.ip then -- ip must match, this makes stealing sessions a local affair.
				sess=nil
			end
		end
	end
	
	srv.sess=sess
	srv.user=nil
	if sess and sess.cache and sess.cache.userid then -- this may be an old session
	
		srv.user=d_users.get(srv,sess.cache.userid) -- this is probably also a cache get
	end
	
	local snag=d_nags.render(srv,sess)
	if snag then srv.alerts_html=(srv.alerts_html or "")..snag end
	
	if srv.user and srv.user.cache and srv.user.cache.admin then -- do not ratelimit admins ips
		iplog.mark_as_admin(srv.ip)
	end

	if srv.user and srv.user.cache and srv.user.cache.type=="spam" then
		srv.spam=true
--		iplog.mark_as_spam(srv.ip)
	end

	return srv.sess,srv.user -- return sess , user
	
end


dat.set_defs(_M) -- create basic data handling funcs

dat.setup_db(_M) -- make sure DB exists and is ready


