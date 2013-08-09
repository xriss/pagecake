-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local wet_html=require("wetgenes.html")
local replace=wet_html.replace

local sys=require("wetgenes.www.any.sys")

local json=require("wetgenes.json")
local dat=require("wetgenes.www.any.data")

local users=require("wetgenes.www.any.users")

local log=require("wetgenes.www.any.log").log -- grab the func from the package

local wstr=require("wetgenes.string")
local wet_string=wstr
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

local dl_users=require("dimeload.users")
local dl_transactions=require("dimeload.transactions")

local dl_projects=require("dimeload.projects")
local dl_pages=require("dimeload.pages")

local dl_downloads=require("dimeload.downloads")

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

	srv.dl=wakapages.load(srv,"/dl")[0] -- main waka page
	local dlua=srv.dl.lua or {}

	local cmd=srv.url_slash[ srv.url_slash_idx+0 ]

-- functions for each special command
	local cmds={
		tmp=		serv_test,
	}
	local f=cmds[ string.lower(cmd or "") ]
	if f then return f(srv) end
	
-- check for project
	local lc=string.lower(cmd or "")
	for i,v in ipairs(dlua.projects or {}) do
		if lc == string.lower(v) then
			return serv_project(srv,lc)
		end
	end

	return
end


-----------------------------------------------------------------------------
--
-- just a test
--
-----------------------------------------------------------------------------
function serv_test(srv)
local sess,user=d_sess.get_viewer_session(srv)
local get,put=make_get_put(srv)
	
	put("This is a dimeload test, please ignore it for now")

end


-----------------------------------------------------------------------------
--
-- display a project, or a subpage of the project
--
-----------------------------------------------------------------------------
function serv_project(srv,pname)

	local url_local="/dl/"..pname

	local project=dl_projects.get(srv,pname)
	if not project then return end

	local code=srv.url_slash[ srv.url_slash_idx+1 ]
	if code then -- check for code
log(code)
--		url_local="/dl/pname/"..code
	end
	

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
	if srv.method=="POST" and srv:check_referer(url) then
		for i,v in pairs(srv.posts) do
			posts[i]=v
		end
	end
	if posts.submit then posts.submit=trim(posts.submit) end
	for n,v in pairs(srv.uploads) do
		posts[n]=v
	end
	
	local refined=wakapages.load(srv,"/dl/"..pname)[0]

	local css=refined and refined.css
	local html_head
	if refined.html_head then html_head=get(refined.html_head,refined) end

	refined.title=project.cache.title
	refined.body=project.cache.body

	srv.set_mimetype("text/html; charset=UTF-8")
	put("header",{title=refined.title,css=css,extra=html_head})
	put("dimeload_bar",{page="dl/"..pname})
	
	put(macro_replace(refined.plate or "{body}",refined))

	comments.build(srv,{title=title,url=url_local,posts=posts,get=get,put=put,sess=sess,user=user})

	put("footer")


end


