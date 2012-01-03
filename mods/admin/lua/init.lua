-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require



local wet_html=require("wetgenes.html")

local sys=require("wetgenes.www.any.sys")

local json=require("wetgenes.json")
local dat=require("wetgenes.www.any.data")

local users=require("wetgenes.www.any.users")

local fetch=require("wetgenes.www.any.fetch")
local cache=require("wetgenes.www.any.cache")

local log=require("wetgenes.www.any.log").log -- grab the func from the package

local wet_string=require("wetgenes.string")
local str_split=wet_string.str_split
local serialize=wet_string.serialize

local ae_opts=require("wetgenes.www.any.opts")

local d_sess =require("dumid.sess")

-- require all the module sub parts
local html=require("admin.html")




module("admin")
local function make_put(srv)
	return function(a,b)
		b=b or {}
		b.srv=srv
		srv.put(wet_html.get(html,a,b))
	end
end

-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-- do not cache the srv param localy, make sure it cascades around
--
-----------------------------------------------------------------------------
function serv(srv)
local sess,user=d_sess.get_viewer_session(srv)
local put=make_put(srv)

	if not( user and user.cache and user.cache.admin ) then -- adminfail
		return srv.redirect("/dumid?continue="..srv.url)
	end

	local url=srv.url_base:sub(1,-2) -- lose the trailing /

	put("header",{})
	
	local posts={} -- remove any gunk from the posts input
	-- check if this post probably came from this page before allowing post params
	if srv.method=="POST" and srv.headers.Referer and string.sub(srv.headers.Referer,1,string.len(url))==url then
		for i,v in pairs(srv.posts) do
			posts[i]=v
		end
	end	
	
	if posts.text then -- change
		ae_opts.put_dat("lua",posts.text)
		srv.reloadcache() -- force lua reload on next request
	end

	
	local lua=ae_opts.get_dat("lua") or ""
	put("admin_edit",{text=lua})
	
	put("footer",{})
end

