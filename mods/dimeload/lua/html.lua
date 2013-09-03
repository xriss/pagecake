-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require


local sys=require("wetgenes.www.any.sys")

local wet_html=require("wetgenes.html")
local replace=wet_html.replace

local html=require("base.html")


--module
local M={ modname=(...) } ; package.loaded[M.modname]=M


setmetatable(M,{__index=html}) -- use a meta table to also return html base 


-----------------------------------------------------------------------------
--
-- overload footer
--
-----------------------------------------------------------------------------
M.footer=function(d)

	d=d or {}
	
	d.mod_name="dimeload"
	d.mod_link="https://bitbucket.org/xixs/pagecake/src/tip/mods/dimeload"
	
	return html.footer(d)
end

-----------------------------------------------------------------------------
--
-- control bar
--
-----------------------------------------------------------------------------
M.dimeload_bar=function(d)


	d.admin=""
	if d.srv and d.srv.user and d.srv.user.cache and d.srv.user.cache.admin then -- admin
		d.admin=replace([[
	<div class="aelua_admin_bar">
		<a href="/?cmd=edit&page={page}" class="button" > Edit </a>
		<a href="/?cmd=edit&page=dl" class="button" > Admin </a>
	</div>
]],d)
	end
	
	return (d.admin)

end



-----------------------------------------------------------------------------
--
-- sponsor form and links
--
-----------------------------------------------------------------------------
M.sponsor=function(d)

	return replace([[
	<div>
	<form action="?sponsor" method="post" >
	 PROJECT:<input type="text" name="project" value="{project}"/> <br/>
	 CODE:<input type="text" name="code" value="{code}"/> <br/>
	 DIMES:<input type="text" name="dimes" value="{dimes}"/> <br/>
	 ABOUT:<textarea rows="20" cols="80" name="about">{about}</textarea> <br/>
	 <input type="submit" value="Update" /> <br/>
	</form>
	</div>
]],d)


end
