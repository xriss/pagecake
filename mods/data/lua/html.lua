
local sys=require("wetgenes.www.any.sys")
local wet_html=require("wetgenes.html")
local replace=wet_html.replace
local url_esc=wet_html.url_esc

local html=require("html")

local setmetatable=setmetatable

local os=require("os")
local string=require("string")

module("data.html")

setmetatable(_M,{__index=html}) -- use a meta table to also return html base 






-----------------------------------------------------------------------------
--
-- overload footer
--
-----------------------------------------------------------------------------
footer=function(d)
	d.mod_name="data"
	d.mod_link="http://boot-str.appspot.com/about/mod/data"
	return html.footer(d)
end


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
	<input type="submit" name="submit" value="Upload" class="button" /> <br />

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
<a href="/data//edit/{it.cache.id}" >edit</a> {example} <a href="/data{it.cache.pubname}">{it.cache.pubname}</a>
</div>
]],d)

end
