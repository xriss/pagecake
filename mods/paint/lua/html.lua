-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require


local sys=require("wetgenes.www.any.sys")

local wet_html=require("wetgenes.html")
local replace=wet_html.replace

local html=require("base.html")


--module
local M={ modname=(...) } ; package.loaded[M.modname]=M


setmetatable(M,{__index=html}) -- use a meta table to also return html base 


function M.fill_cake(srv,refined)

	refined.cake=refined.cake or html.fill_cake(srv)
	local cake=refined.cake
	
	cake.paint={}

	cake.paint.admin_bar=[[
<div class="cake_admin_bar">
	<form action="{cake.qurl}" method="POST" enctype="multipart/form-data">
		<a href="/?cmd=edit&page=paint" class="cake_button" > EditWaka </a>
	</form>
</div>
]]


	return cake
end
