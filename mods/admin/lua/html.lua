-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local sys=require("wetgenes.www.any.sys")
local wet_html=require("wetgenes.html")
local replace=wet_html.replace
local url_esc=wet_html.url_esc

local wet_string=require("wetgenes.string")

local html=require("base.html")

local opts=require("opts")


-- replacement version of module that does not global
local module=function(modname, ...)
	local ns={ _NAME = modname , _PACKAGE = string.gsub (modname, "[^.]*$", "") }
	ns._M = ns
	package.loaded[modname] = ns
	setfenv (2, ns)
	for _,f in ipairs({...}) do f(ns) end
end
module("admin.html")
local M=_M
setmetatable(_M,{__index=html}) -- use a meta table to also return html base 


-----------------------------------------------------------------------------
--
-- overload footer
--
-----------------------------------------------------------------------------
footer=function(d)
	d.mod_name="admin"
	d.mod_link="https://bitbucket.org/xixs/pagecake/src/tip/mods/admin"
	return html.footer(d)
end

-----------------------------------------------------------------------------
--
-- edit
--
-----------------------------------------------------------------------------
admin_edit=function(d)
--print("OPTS",tostring(opts))

	d=d or {}
	local srv=d.srv or (ngx and ngx.ctx) or {}

	d.bootstrapp="<a href=\"http://boot-str.appspot.com/\">bootstrapp</a>"	
	d.version=opts.bootstrapp_version or 0
	d.oldopts=wet_string.serialize(srv.opts(),{pretty=true,no_duplicates=true})



	
	return replace([[
<div>
<p>
<a href="/admin/console" class="button" >console</a>
<a href="/admin/users" class="button" >users</a>
<br/>
<a href="/data" class="button" >data</a>
<a href="/!/admin" class="button" >waka</a>
<a href="/blog/!/admin" class="button" >blog</a>
<a href="/note/!/admin" class="button" >note</a>
<a href="/admin/cmd/clearcache" class="button" >decache</a>
<a href="/admin/cmd/clearstash" class="button" >destash</a>
</p>
<form name="post" id="post" action="" method="post" enctype="multipart/form-data">
	<textarea name="text" cols="120" rows="24" class="field" >{text}</textarea>
	<br/>
	<input type="submit" name="submit" value="Save" class="button" />
	<br/>
	<br/>
</form>
<br/>
<p>Your current active Admin Session for remote access is {sess.id} </p>
<br/>
<p>These are your current opts, anything typed in above will modify or replace them.</p>
<pre>{oldopts}</pre>
</div>
]],d)

end











function M.fill_cake(srv,refined)
	local cake=refined.cake or {}
	refined.cake=cake
	
	cake.admin={}
	
--{-cake.dimeload.needlogin}
	cake.admin.user=[[
{it.name}
{it.id}
]]

	return cake
end

