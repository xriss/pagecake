-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require


local sys=require("wetgenes.www.any.sys")

local wet_html=require("wetgenes.html")
local replace=wet_html.replace

local html=require("html")

module("dimeload.html")

setmetatable(_M,{__index=html}) -- use a meta table to also return html base 


-----------------------------------------------------------------------------
--
-- overload footer
--
-----------------------------------------------------------------------------
footer=function(d)

	d=d or {}
	
	d.mod_name="dimeload"
	d.mod_link="http://boot-str.appspot.com/about/mod/dimeload"
	
	return html.footer(d)
end

-----------------------------------------------------------------------------
--
-- control bar
--
-----------------------------------------------------------------------------
todo_bar=function(d)


	d.admin=""
	if d.srv and d.srv.user and d.srv.user.cache and d.srv.user.cache.admin then -- admin
		d.admin=replace([[
	<div class="aelua_admin_bar">
		<form method="POST" enctype="multipart/form-data" action="/?cmd=edit&page={page}">
			<button type="submit" name="submit" value="edit" class="button" >Edit</button>
		</form>
	</div>
]],d)
	end
	
	return (d.admin)

end
