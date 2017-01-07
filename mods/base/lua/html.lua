-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require


local log=require("wetgenes.www.any.log").log

local wstr=require("wetgenes.string")
local whtml=require("wetgenes.html")


--module
local M={ modname=(...) } ; package.loaded[M.modname]=M


-- fill cake with juicy chunks ready to be served
function M.fill_cake(srv)
	local cake={}
	
	cake.url=srv.url
	cake.urlesc=whtml.url_esc(srv.url)
	cake.qurl=srv.qurl
	cake.url_base=srv.url_base
	cake.subdomain=srv.subdomain

	cake.html={}
	cake.html.css="{css}" -- use css chunk
	cake.html.title="{-title}" -- empty title
	cake.html.extra="" -- squirt this into the head
	
-- for example add an atom link using cake.html.extra
-- <link rel="alternate" type="application/atom+xml" title="{blogtitle}" href="{blogurl}" />


	cake.html.js=[[
<script src="/js/base/head.min.js"></script>
<script>
head.fs={};
//head.fs.jquery_js="http://ajax.googleapis.com/ajax/libs/jquery/1.4.3/jquery.min.js";
head.fs.jquery_js="/js/base/jquery-1.11.1.min.js";
head.fs.jquery_ui_js="http://ajax.googleapis.com/ajax/libs/jqueryui/1.8.2/jquery-ui.min.js";
head.fs.jquery_validate_js="http://ajax.microsoft.com/ajax/jQuery.Validate/1.6/jQuery.Validate.min.js";
head.fs.jquery_asynch_image_loader_js="/js/base/JqueryAsynchImageLoader-0.8.min.js";
head.fs.jquery_cookie_js="/js/base/jquery.cookie.js";
head.fs.jquery_wet_js="/js/base/jquery-wet.js";
head.fs.jquery_wakaedit_js="/js/base/jquery-wakaedit.js";
head.fs.swfobject_js="http://ajax.googleapis.com/ajax/libs/swfobject/2.2/swfobject.js";
head.fs.codemirror_js="/js/base/codemirror.min.js";
head.fs.codemirror_css="/css/base/codemirror.css";
</script>
]]
	
-- open main html chunk of a page and fill in head chunk
--[[	cake.html.head=[ [
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
]]

	cake.html.mimetype="text/html; charset=UTF-8"
	cake.html.head=[[
<html>
<head>
<meta charset="UTF-8"/>
<title>{-cake.html.title}</title>
<link rel="stylesheet" type="text/css" href="/css/base/pagecake.css" />
{-cake.html.extra}
{cake.html.js}
<style type="text/css">{cake.html.css}</style>
</head>
<body>
]]

-- close main html chunk of a page
	cake.html.foot=[[
{cake.anal}
</body>
</html>
]]
	cake.html.plate=[[
{cake.html.head}
<div class="cake_body">
{cake.admin}
{cake.bars}
{cake.plate}
</div>
{cake.html.foot}
]]

-- override with your google analytics code or whatever you want injected into the footer
	cake.anal=""
	cake.edit=""
	cake.notes=""
	cake.comments="{-cake.notes}"
	cake.plate=[[
<h1>{-title}</h1>
{body}
{-cake.comments}
]]

	cake.admin=""
	cake.admin_waka_bar=[[
<div class="cake_admin_bar">
	<form action="{cake.qurl}" method="POST" enctype="multipart/form-data">
		<a href="/!/admin/edit#{-cake.pagename}" class="cake_button" target="_blank" > Edit </a>
		<a href="/!/admin" class="cake_button" > Admin </a>
	</form>
</div>
]]
	cake.admin_blog_bar=[[
<div class="cake_admin_bar">
	<form action="{cake.qurl}" method="POST" enctype="multipart/form-data">
		{-cake.admin_blog_bar_edit}
		<a href="/?cmd=edit&page=blog" class="cake_button" > EditMain </a>
		<a href="/?cmd=edit&page=blog/list" class="cake_button" > EditList </a>
		<a href="/blog" class="cake_button" > View Blog </a> 
		<a href="/blog/!/admin/pages" class="cake_button" > List </a> 
		<a href="/blog/!/admin/edit/$newpage" class="cake_button" > New Post </a>
	</form>
</div>
]]
	cake.admin_blog_bar_edit=[[
		<a href="/blog/!/admin/edit/$hash/{it.id}" class="cake_button" > EditPost </a>
]]
	cake.admin_comic_bar=[[
<div class="cake_admin_bar">
	<form action="{cake.qurl}" method="POST" enctype="multipart/form-data">
		<a href="/?cmd=edit&page=comic" class="cake_button" > EditWaka </a>
		<a href="/?cmd=edit&page={it.id}" class="cake_button" > EditComic </a>
	</form>
</div>
]]

	cake.admin_dimeload_bar=[[
<div class="cake_admin_bar">
	<form action="{cake.qurl}" method="POST" enctype="multipart/form-data">
		<a href="/?cmd=edit&page=dl" class="cake_button" > EditWaka </a>
		<a href="/?cmd=edit&page=dl/{cake.dimeload.project.id}" class="cake_button" > EditProject </a>
		<a href="/dl/admin" class="cake_button" > Admin </a>
	</form>
</div>
]]

	cake.admin_waka_form=[[
<div class="cake_wakaedit">
<form name="post" action="{cake.qurl}" method="post" enctype="multipart/form-data">
	<textarea name="text" class="cake_field cake_wakaedit_field">{.cake.admin_waka_form_text}</textarea>
</form>

<script>
window.auto_wakaedit={who:".cake_wakaedit",width:960,height:window.innerHeight-40};
head.js(head.fs.jquery_wakaedit_js);
</script>

</div>
]]


	cake.admin_blog_item=[[
<div>
<input type="checkbox" name="{it.pubname}" value="Check"></input>
<a href="{cake.url_base}!/admin/edit/$hash/{it.id}">
<span style="width:20px;display:inline-block;">{it.layer}</span>
<span style="width:200px;display:inline-block;">{it.pubname}</span>
<span style="width:400px;display:inline-block;">{it.chunks.title.text}</span>
{it.pubdate}
</a>
</div>
]]

	cake.bars=[[
<div class="cake_bars_wrap"><div class="cake_bars">{cake.homebar.div}{cake.userbar.div}</div></div>
]]
	cake.userbar={}
	cake.userbar.hello="Hello {cake.userbar.profile},"

	if srv.user and srv.sess then -- a user is logged in and viewing
		local user=srv.user
		local hash=srv.sess and srv.sess.key and srv.sess.key.id

		cake.userbar.name=user.cache.name
		cake.userbar.id=user.cache.id
		cake.userbar.hash=hash
		cake.userbar.profile="<a href=\"/profile/{.cake.userbar.id}\" >{.cake.userbar.name}</a>"
		cake.userbar.action="<a href=\"/dumid/logout/{cake.userbar.hash}/?continue={.cake.urlesc}\">Logout?</a>"
	else
		cake.userbar.name="Anon"
		cake.userbar.id=""
		cake.userbar.hash=""
		cake.userbar.profile="{.cake.userbar.name}"
		cake.userbar.action="<a href=\"/dumid/login/?continue={.cake.urlesc}\">Login?</a>"
	end
	
	cake.userbar.div=[[<div class="cake_userbar">{cake.userbar.hello} {cake.userbar.action}</div>]]

	cake.homebar={}
	cake.homebar.div=[[<div class="cake_homebar"><a href="/">Home</a>{-cake.homebar.crumbs}</div>]]
	cake.homebar.crumbs_plate=[[
	/ <a href="{it.url}">{it.text}</a>
	]]


	cake.blog_item=[[<h1><a href="{it.link}">{it.title}</a></h1>{it.body}]]
	cake.blog_page=[[{cake.blog_item}]]
	cake.blog_list=[[{cake.blog_item}]]

	cake.blog_bar=[[<div class="cake_blog_bar"><a href="{-opts.link_prev}"  class="cake_blog_bar_prev" >PREV</a><a href="{-opts.link_next}" class="cake_blog_bar_next" >NEXT</a></div>]]

	cake.blog_edit_form=[[
<form name="post" id="post" action="" method="post" enctype="multipart/form-data">
	<table style="float:right">
	<tr><td> group   </td><td> <input type="text" name="group"   size="20" value="{.it.group}"  /> </td></tr>
	<tr><td> pubname </td><td> <input type="text" name="pubname" size="20" value="{.it.pubname}"/> </td></tr>
	<tr><td> pubdate </td><td> <input type="text" name="pubdate" size="20" value="{.it.pubdates}"/> </td></tr>
	<tr><td> layer   </td><td> <input type="text" name="layer"   size="20" value="{.it.layer}"  /> </td></tr>
	</table>
	<textarea style="width:100%" name="text" cols="80" rows="24" class="field" >{.it.text}</textarea>
	<br/>
	<input type="submit" name="submit" value="Save" class="button" />
	<input type="submit" name="submit" value="Preview" class="button" />
	<input type="submit" name="submit" value="{it.publish}" class="button" />
	<br/>	
</form>
]]


	cake.comic_inlist=[[
<div>
<h3>{it.title}</h3>
<img src="{it.image}"/>
</div>
]]

	cake.comic_inpage=[[
<div>
<h3>{it.title}</h3>
<img src="{it.image}"/>
<div>
<a href="/comic/{cfirst.name}"> FIRST <img src="{cfirst.icon}" width="100" height="100"/> </a>
<a href="/comic/{cprev.name}"> PREVIOUS <img src="{cprev.icon}" width="100" height="100"/> </a>
<a href="/comic/{crandom.name}"> RANDOM <img src="{crandom.icon}" width="100" height="100"/> </a>
<a href="/comic/{cnext.name}"> NEXT <img src="{cnext.icon}" width="100" height="100"/> </a>
<a href="/comic/{clast.name}"> LAST <img src="{clast.icon}" width="100" height="100"/> </a>
</div>
<div>{it.body}</div>
</div>
]]

	cake.profile_layout=[[
<div class="profile_layout">
<div class="profile_layout_head">
{-cake.profile_head}
</div>
<div class="profile_layout_body">
	<div class="profile_layout_wide">
{-cake.profile_wide}
	</div>
	<div class="profile_layout_side">
{-cake.profile_side}
	</div>
</div>
<div class="profile_layout_foot">
{-cake.profile_foot}
</div>
</div>
]]

	return cake
end

