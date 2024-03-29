-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local sys=require("wetgenes.www.any.sys")
local wet_html=require("wetgenes.html")
local replace=wet_html.replace
local url_esc=wet_html.url_esc

local html=require("base.html")


-- replacement version of module that does not global
local module=function(modname, ...)
	local ns={ _NAME = modname , _PACKAGE = string.gsub (modname, "[^.]*$", "") }
	ns._M = ns
	package.loaded[modname] = ns
	setfenv (2, ns)
	for _,f in ipairs({...}) do f(ns) end
end
module("data.html")

setmetatable(_M,{__index=html}) -- use a meta table to also return html base 



-----------------------------------------------------------------------------
--
-- data form
--
-----------------------------------------------------------------------------
data_upload_form=function(d)

	d.id=d.id or 0
	d.filename=d.filename or ""
	d.mimetype=d.mimetype or ""

	return replace([[
<form name="post" id="post" action="" method="post" enctype="multipart/form-data">

	id : <input type="text" name="dataid" id="dataid" size="40" value="{id}"  /><a onclick="$('#dataid').val('0');" class="button button_clear" >X</a> <br />
	filename : <input type="text" name="filename" id="filename" size="40" value="{filename}"  /><a onclick="$('#filename').val('');" class="button button_clear" >X</a> <br />
	mimetype : <input type="text" name="mimetype" id="mimetype" size="40" value="{mimetype}"  /><a onclick="$('#mimetype').val('');" class="button button_clear" >X</a> <br />
	The above settings are optional, just leave them <a href="/data" class="button">blank</a> for most uploads. <br />
	upload : <input type="file" name="filedata" size="40" />  <br />
	<input type="submit" name="submit" value="Upload" class="button" /> a file or
	<input type="submit" name="submit" value="DELETE" class="button" /> a file! <br />

</form>

<script>
head.js(head.fs.jquery_js,function(){
});
</script>

]],d)

end


-----------------------------------------------------------------------------
--
-- data info
--
-----------------------------------------------------------------------------
data_list_item=function(d)
	local c=d.it.cache
	if c.mimetype:sub(1,5)=="image" then
	d.example=[[<span style="width:100px;display:inline-block;text-align:center"><img src="/data]]..c.pubname..[[" style="max-width:100px;max-height:50px" /></span>]]
	elseif c.mimetype=="application/zip" then
		d.example=[[<span style="width:100px;display:inline-block;text-align:center"><a href="/data/]]..c.id..[[/">list</a></span>]]
	else
		d.example=[[<span style="width:100px;display:inline-block;text-align:center">unknown</span>]]
	end
	return replace([[
<div>
<a href="/data//edit/{it.cache.id}" >edit</a> {example} {it.cache.size} <a href="/data{it.cache.pubname}">{it.cache.pubname}</a>
</div>
]],d)

end

data_list_foot=function(d)
	return replace([[
<div>
<a href="/data?off={page.prev}" >prev page</a> 
<a href="/data?off={page.next}" >next page</a> 
</div>
]],d)

end
