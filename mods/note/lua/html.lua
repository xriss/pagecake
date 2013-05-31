-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local sys=require("wetgenes.www.any.sys")
local wet_html=require("wetgenes.html")
local replace=wet_html.replace
local url_esc=wet_html.url_esc

local html=require("base.html")

module("note.html")

setmetatable(_M,{__index=html}) -- use a meta table to also return html base 



-----------------------------------------------------------------------------
--
-- overload footer
--
-----------------------------------------------------------------------------
footer=function(d)
	d.mod_name="note"
	d.mod_link="https://bitbucket.org/xixs/anlua/src/tip/mods/note"
	return html.footer(d)
end



-----------------------------------------------------------------------------
--
-- atom wrappers
--
-----------------------------------------------------------------------------
note_atom_head=function(d)
	return replace([[<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">

	<title>{title}</title>
	<link rel="self" href="{srv.url_base}.atom"/>
	<updated>{updated}</updated>
	<author>
		<name>{author_name}</name>
	</author>
	<id>{srv.url_base}.atom</id>
]],d)

end

note_atom_foot=function(d)
	return replace([[</feed>
]],d)

end
note_atom_item=function(d)
	d.pubdate=(os.date("%Y-%m-%dT%H:%M:%SZ",d.it.created))
	d.id=d.link
	return replace([[
	<entry>
		<title type="text">{title}</title>
		<link href="{link}"/>
		<id>{id}</id>
		<updated>{pubdate}</updated>
		<content type="html">{text}</content>
	</entry>
]],d)

end

