-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local wet_html=require("wetgenes.html")
local replace=wet_html.replace

local sys=require("wetgenes.www.any.sys")

local json=require("wetgenes.json")
local dat=require("wetgenes.www.any.data")

local users=require("wetgenes.www.any.users")

local log=require("wetgenes.www.any.log").log -- grab the func from the package

local wet_string=require("wetgenes.string")
local trim=wet_string.trim
local str_split=wet_string.str_split
local serialize=wet_string.serialize
local macro_replace=wet_string.macro_replace

local wet_waka=require("wetgenes.waka")
local d_sess =require("dumid.sess")
local d_users=require("dumid.users")

-- require all the module sub parts
local html=require("dimeload.html")

local waka=require("waka")
local note=require("note")

local wakapages=require("waka.pages")
local comments=require("note.comments")


-- opts
local opts_mods_profile=(opts and opts.mods and opts.mods.profile) or {}

module("dimeload")

local function make_get_put(srv)
	local get=function(a,b)
		b=b or {}
		b.srv=srv
		return wet_html.get(html,a,b)
	end
	return  get , function(a,b) srv.put(get(a,b)) end
end

-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-----------------------------------------------------------------------------
function serv(srv)
local sess,user=d_sess.get_viewer_session(srv)
local get,put=make_get_put(srv)
	
	local url=srv.url_base
	if url:sub(-1)=="/" then url=url:sub(1,-2) end -- trim any trailing /

-- this is the base url we use for comments
	local t={""}
	for i=4,srv.url_slash_idx-1 do
		t[#t+1]=srv.url_slash[i]
	end
	local baseurl=table.concat(t,"/")

-- handle posts cleanup
	local posts={} -- remove any gunk from the posts input
	-- check if this post probably came from this page before allowing post params
	if srv.method=="POST" and srv.headers.Referer and string.sub(srv.headers.Referer,1,string.len(url))==url then
		for i,v in pairs(srv.posts) do
			posts[i]=v
		end
	end
	if posts.submit then posts.submit=trim(posts.submit) end
	for n,v in pairs(srv.uploads) do
		posts[n]=v
	end

end


