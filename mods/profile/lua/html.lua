-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require


local sys=require("wetgenes.www.any.sys")
local wet_html=require("wetgenes.html")
local replace=wet_html.replace
local url_esc=wet_html.url_esc

local html=require("base.html")


module("profile.html")

setmetatable(_M,{__index=html}) -- use a meta table to also return html base 



-----------------------------------------------------------------------------
--
-- overload footer
--
-----------------------------------------------------------------------------
footer=function(d)
	d.mod_name="profile"
	d.mod_link="http://boot-str.appspot.com/about/mod/profile"
	return html.footer(d)
end


-----------------------------------------------------------------------------
--
-- table layout, grab all the previously built bits and spit them out
-- into some sort of layout
--
-----------------------------------------------------------------------------
profile_layout=function(d)

-- the 4 main components, may be arrays of strings just join them if they are
	for i,v in ipairs{"head","wide","side","foot"} do
		if type(d[v])=="table" then
			d[v]=table.concat(d[v]) -- turn any tables to strings
		end
	end

	local p=get_plate("profile_layout",[[
<div class="profile_layout">
<div class="profile_layout_head">
{head}
</div>
<div class="profile_layout_body">
	<div class="profile_layout_wide">
{wide}
	</div>
	<div class="profile_layout_side">
{side}
	</div>
</div>
<div class="profile_layout_foot">
{foot}
</div>
</div>
]])
	return replace(p,d)
end


