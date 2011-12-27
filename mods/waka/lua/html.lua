
local sys=require("wetgenes.www.any.sys")
local wet_html=require("wetgenes.html")
local replace=wet_html.replace
local url_esc=wet_html.url_esc
local html_esc=wet_html.esc

local html=require("html")

local setmetatable=setmetatable

module("waka.html")

setmetatable(_M,{__index=html}) -- use a meta table to also return html base 






-----------------------------------------------------------------------------
--
-- overload footer
--
-----------------------------------------------------------------------------
footer=function(d)
	d.mod_name="waka"
	d.mod_link="http://boot-str.appspot.com/about/mod/waka"
	return html.footer(d)
end


-----------------------------------------------------------------------------
--
-- control bar
--
-----------------------------------------------------------------------------
waka_bar=function(d)


	d.admin=""
	if d.srv and d.srv.user and d.srv.user.cache and d.srv.user.cache.admin then -- admin
		d.admin=replace([[
	<div class="aelua_admin_bar">
		<form action="" method="POST" enctype="multipart/form-data">
			<button type="submit" name="submit" value="edit" class="button" >Edit</button>
		</form>
	</div>
]],d)
	end
	
	return (d.admin)

end

-----------------------------------------------------------------------------
--
-- edit form
--
-----------------------------------------------------------------------------
waka_edit_form=function(d)

	d.text=html_esc(d.text)

	return replace([[
<div id="wakaedit" style="width:960px;position:relative;margin:auto;display:block">
<form name="post"  action="" method="post" enctype="multipart/form-data">
	<textarea name="text" class="field" style="width:960px;height:480px;position:relative;margin:auto;display:block" >{text}</textarea>
	<div style="text-align:center;">
		<input type="submit" name="submit" value="Save" class="button" />
		<input type="submit" name="submit" value="Save and Edit" class="button" />
		<input type="submit" name="submit" value="Preview" class="button" />
		<input type="submit" name="submit" value="Cancel" class="button" />
	</div>
</form>

<script>
window.auto_wakaedit={who:"#wakaedit",width:960,height:480};
head.js(head.fs.jquery_wakaedit_js);
</script>

</div>
]],d)

end
