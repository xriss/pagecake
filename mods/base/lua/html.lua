-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require


local log=require("wetgenes.www.any.log").log

local sys=require("wetgenes.www.any.sys")
local waka=require("wetgenes.waka")
local users=require("wetgenes.www.any.users")

local wstr=require("wetgenes.string")
local wet_html=require("wetgenes.html")
local replace=wet_html.replace
local url_esc=wet_html.url_esc


local opts=opts

local ngx=ngx

module("base.html")
local _M=require("base.html")

_M.basefunc={}

-----------------------------------------------------------------------------
--
-- turn a number of seconds into a rough duration
--
-----------------------------------------------------------------------------
function _M.basefunc.rough_english_duration(html,t)
	t=math.floor(t)
	if t>=2*365*24*60*60 then
		return math.floor(t/(365*24*60*60)).." years"
	elseif t>=2*30*24*60*60 then
		return math.floor(t/(30*24*60*60)).." months" -- approximate months
	elseif t>=2*7*24*60*60 then
		return math.floor(t/(7*24*60*60)).." weeks"
	elseif t>=2*24*60*60 then
		return math.floor(t/(24*60*60)).." days"
	elseif t>=2*60*60 then
		return math.floor(t/(60*60)).." hours"
	elseif t>=2*60 then
		return math.floor(t/(60)).." minutes"
	elseif t>=2 then
		return t.." seconds"
	elseif t==1 then
		return "1 second"
	else
		return "0 seconds"
	end
end

-----------------------------------------------------------------------------
--
-- turn an integer number into a string with three digit grouping
--
-----------------------------------------------------------------------------
function _M.basefunc.num_to_thousands(html,n)
	local p=math.floor(n) -- remove the fractions
	if p<0 then p=-p end -- remove the sign
	local s=string.format("%d",p) -- force format integer part only?
	local len=string.len(s) -- total length of number
	local skip=len%3 -- size of first batch
	local t={}
	if skip>0 then -- 1 or 2 digits
		t[#t+1]=string.sub(s,1,skip)
	end
	for i=skip,len-3,3 do -- batches of 3 digits
		t[#t+1]=string.sub(s,i+1,i+3)
	end
	local s=table.concat(t,",") -- join it back together with commas every 3 digits
	if n<0 then return "-"..s else return s end -- put the sign back and return it
end

-----------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------
_M.basefunc.header=function(html,d)

	local srv=d.srv or (ngx and ngx.ctx) or {}
	
	if (srv.opts("html","bar") or "head") =="head" then
		d.bar=html.get_html("aelua_bar",d)
	end
	if srv.opts("html","bar")=="top" then
		d.bartop=html.get_html("aelua_bar",d)
	end
	
	d.bar=d.bar or ""
	d.bartop=d.bartop or ""

	d.extra=(d.srv and d.srv.extra or "") .. ( d.extra or "" ).. ( d.html_head or "" )
	

	for _,v in ipairs{d.srv or {},d,srv.opts("head") or {} } do
				
		if type(v.extra_css)=="table" then
			for i,v in ipairs(v.extra_css) do
				d.extra=d.extra..[[<link rel="stylesheet" type="text/css" href="]]..v..[[" />
]]
			end
		end
		if type(v.extra_js)=="table" then
			for i,v in ipairs(v.extra_js) do
				d.extra=d.extra..[[<script type="text/javascript" src="]]..v..[["></script>
]]
			end
		end
		if v.css then --embed some raw css
			d.extra=d.extra.."<style type=\"text/css\">"..v.css.."</style>"
		end		
		
		if type(v.extra)=="table" then -- any old random extra junk can go here
			for i,v in ipairs(v.extra) do
				d.extra=d.extra..v
			end
		end

	end

	
	d.jquery_js="http://ajax.googleapis.com/ajax/libs/jquery/1.4.3/jquery.min.js"
	d.jquery_ui_js="http://ajax.googleapis.com/ajax/libs/jqueryui/1.8.2/jquery-ui.min.js"
	d.swfobject_js="http://ajax.googleapis.com/ajax/libs/swfobject/2.2/swfobject.js"
	d.jquery_validate_js="http://ajax.microsoft.com/ajax/jQuery.Validate/1.6/jQuery.Validate.min.js"
	d.head_js="/js/base/head.min.js"
	d.gcf_js="http://ajax.googleapis.com/ajax/libs/chrome-frame/1/CFInstall.min.js"

	if d.srv.url_slash[3]=="host.local:80801" then -- a local shop only servs local people
		d.jquery_js="/js/base/jquery-1.4.3.js"
		d.jquery_ui_js="/js/base/jquery-ui-1.8.2.custom.min.js"
		d.swfobject_js="/js/base/swfobject.js"
		d.jquery_validate_js="/js/base/jquery.validate.js"
		d.head_js="/js/base/head.js"
	end
	
	d.all_min_js="/js/base/all.min.js"
		
	if not d.title then
		local crumbs=d.srv.crumbs
		local s
		for i=1,#crumbs do local v=crumbs[i]
			if v.title then
				if not s then s="" else s=s.." - " end
				s=s..v.title
			end
		end
		d.title=s
	end
	
	d.dotcss=".css"
	if d.srv and d.srv.user and d.srv.user and d.srv.user.cache and d.srv.user.cache.admin then -- admin
		d.dotcss=".css?t="..os.time()
	end
	
	local body_junk=[[
{bartop}
<div class="aelua_body">
{bar}
]]
	if d.srv and d.srv.pageopts and d.srv.pageopts.body=="clean" then
		body_junk=""
	end

-- use the extra headers to replace this 
--<link rel="alternate" type="application/atom+xml" title="{blogtitle}" href="{blogurl}" />

	
	local p=html.get_plate_orig("header",[[
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
 <head>

<title>{title}</title>

<meta http-equiv="X-UA-Compatible" content="chrome=1">

<link rel="stylesheet" type="text/css" href="/css/base/aelua.css" /> 
<link rel="stylesheet" type="text/css" href="/{dotcss}" /> 

<script type="text/javascript" src="{head_js}"></script>
<script type="text/javascript"> /* head.js filename sugestions */

if(navigator.appVersion.indexOf("MSIE") != -1){
head.js("http://ajax.googleapis.com/ajax/libs/chrome-frame/1/CFInstall.min.js",
function(){CFInstall.check({});});
}

head.fs={};

head.fs.jquery_js="{jquery_js}";
head.fs.jquery_ui_js="{jquery_ui_js}";
head.fs.jquery_validate_js="{jquery_validate_js}";
head.fs.jquery_wet_js="/js/base/jquery-wet.js";
head.fs.jquery_wakaedit_js="/js/base/jquery-wakaedit.js";
head.fs.jquery_asynch_image_loader_js="/js/base/JqueryAsynchImageLoader-0.8.min.js";

head.fs.ace_js="http://d1n0x3qji82z53.cloudfront.net/src-min-noconflict/ace.js";

head.fs.swfobject_js="{swfobject_js}";

</script>

{extra}

 </head>
<body>]]..body_junk)
	
	return replace(p,d)

end

-----------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------
_M.basefunc.footer=function(html,d)

	local srv=d.srv or (ngx and ngx.ctx) or {} -- hax so we have a srv

	local cache=require("wetgenes.www.any.cache")
	local data=require("wetgenes.www.any.data")
	local fetch=require("wetgenes.www.any.fetch")

	d.bar=""
	if srv.opts("html","bar")=="foot" then
		d.bar=html.get_html("aelua_bar",d)
	end
	
	if not d.time then
		d.time=math.ceil((os.clock()-d.srv.clock)*1000)/1000
	end
	
	if not d.api_time then
		d.api_time=math.ceil( (cache.api_time + data.api_time + fetch.api_time)*1000 )/1000
	end
	
	local mods=""
	
	if d.mod_name and d.mod_link then
	
		mods=" mod <a href=\""..d.mod_link.."\">"..d.mod_name.."</a>"
	
	elseif d.app_name and d.app_link then
	
		mods=" app <a href=\""..d.app_link.."\">"..d.app_name.."</a>"
		
	end
	
	d.about=d.about or about(d)

	d.report=d.report or "Page generated by <a href=\"https://bitbucket.org/xixs/pagecake\">pagecake</a>"..mods.." in "..(d.time or 0).."("..(d.api_time or 0)..") seconds with "..((fetch.count or 0)+(data.count or 0)).." queries and "..(cache.count_got or 0).."/"..(cache.count or 0).." caches."
		
	local body_junk=[[
</div>
<div class="aelua_footer">
<div class="aelua_about">
{about}
</div>
<div class="aelua_report">
{report}
</div>
</div>
{bar}
]]
	if d.srv and d.srv.pageopts and d.srv.pageopts.body=="clean" then
		body_junk=""
	end


	local p=html.get_plate("footer",
body_junk..[[
</body>
</html>
]])
	return replace(p,d)

end
		
-----------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------
_M.basefunc.about=function(html,d)

	d=d or {}
--	d.bootstrapp="<a href=\"http://boot-str.appspot.com/\">bootstrapp</a>"
	d.mods="<a href=\"https://bitbucket.org/xixs/pagecake/src/tip/mods\">mods</a>"
	d.pagecake="<a href=\"https://bitbucket.org/xixs/pagecake\">pagecake</a>"
	d.wetgenes="<a href=\"http://www.wetgenes.com\">wetgenes</a>"
	
--	d.version=opts.bootstrapp_version or 0
--	d.lua="<a href=\"http://www.lua.org/\">lua</a>"
--	d.appengine="<a href=\"http://code.google.com/appengine/\">appengine</a>"

	local p=html.get_plate("about",[[
	{pagecake} is a collection of {mods} developed by {wetgenes}.
]])
	return replace(p,d)

end

-----------------------------------------------------------------------------
--
-- both bars simply joined
--
-----------------------------------------------------------------------------
_M.basefunc.aelua_bar=function(html,d)
	return html.home_bar(d)..html.user_bar(d)
end
	
-----------------------------------------------------------------------------
--
-- a home / tabs / next page area
--
-----------------------------------------------------------------------------
_M.basefunc.home_bar=function(html,d)

	local crumbs=d.crumbs or d.srv.crumbs
	local s
	for i=1,#crumbs do local v=crumbs[i]
		if v.text then
			if not s then s="" else s=s.." / " end
			s=s.."<a href=\""..v.url.."\">"..v.text.."</a>"
		end
	end
	d.crumbs=s or "<a href=\"/\">Home</a>" -- default
		
	local p=html.get_plate("home_bar",[[
<div class="aelua_bar"><div class="aelua_bar2">
<div class="aelua_home_bar">
{crumbs}
</div>
]])
	return replace(p,d)

end

		
-----------------------------------------------------------------------------
--
-- a hello / login / logout area
--
-----------------------------------------------------------------------------
_M.basefunc.user_bar=function(html,d)

	d.adminbar=d.adminbar or ""
	d.alerts_html=d.alerts_html or (d.srv and d.srv.alerts_html) or ""

	local user=d.srv and d.srv.user
	local hash=d.srv and d.srv.sess and d.srv.sess.key and d.srv.sess.key.id
	
	if user then
	
		d.name="<a href=\"/profile/"..user.cache.id.."\" >"..(user.cache.name or "?").."</a>"
	
		d.hello="Hello, "..d.name.."."
		
		d.action="<a href=\"/dumid/logout/"..hash.."/?continue="..url_esc(d.srv.url).."\">Logout?</a>"
		d.js=""
	else
		d.hello="Hello, Anon."
		d.action="<a href=\"/dumid/login/?continue="..url_esc(d.srv.url).."\">Login?</a>"
--		d.action="<a href=\"#\" onclick=\"return dumid_show_login_popup();\">Login?</a>"
	
	end
	
--[[
<script language="javascript" type="text/javascript">
function dumid_show_login_popup()
{
$("body").prepend("<iframe style='position:absolute;left:50%;top:50%;margin-left:-200px;margin-top:-150px;width:400px;height:300px' src='/dumid/login/?continue=..url_esc(d.srv.url)..'></iframe>");
return false;		
}
</script>
]]
	local p=html.get_plate("user_bar",[[
<div class="aelua_user_bar">
{hello} {action}
</div>

<div class="aelua_clear"> </div>
</div></div>
{adminbar}
{alerts_html}
]])
	return replace(p,d)

end

-----------------------------------------------------------------------------
--
-- missing content
--
-----------------------------------------------------------------------------
_M.basefunc.missing_content=function(html,d)

	local p=html.get_plate("missing_content",[[
MISSING CONTENT<br/>
<br/>
<a href="/">return to the homepage?</a><br/>
]])
	return replace(p,d)

end


-----------------------------------------------------------------------------
--
-- load default plates from disk or cache
-- and import default helper functions into the given environment tab
-- call this at the top of your main html module with _M as the argument
--
-----------------------------------------------------------------------------

function import(tab,fname)

	tab.plates=tab.plates or {}

log("checking plates "..(fname or "?") )
	local text=""
	if sys.file_exists(fname or "lua/plates.html") then
log("loading plates "..(fname or "?") )
		text=sys.bytes_to_string(sys.file_read(fname or "lua/plates.html")) or ""
	end
	local chunks=waka.text_to_chunks(text)
	
	for i=1,#chunks do local v=chunks[i] -- copy into plates lookup
		tab.plates[v.name]=v.text
	end

-- these are shoved into the global, well module, name space?
	local function get_html(n,d)
		return ( tab[n](d) )
	end
	local function get_plate(name,alt)
		return ( tab.plates[name] or alt or name )
	end
	local get_plate_orig=get_plate
	local function get_plate(name,alt) -- some simple debug
		return "\n<!-- #"..name.." -->\n\n"..get_plate_orig(name,alt)
	end
	
	tab.get_html=get_html
	tab.get_plate=get_plate
	tab.get_plate_orig=get_plate_orig
	
-- build default plates functions for all plates that we found
	for n,_ in pairs(tab.plates) do

		local f=function(name)
			return function(d)
				return replace(get_plate(name),d)
			end
		end
		
		if not tab[n] then -- create function
			tab[n]=f(n)
		end

	end

-- copy our functions 
	for _,n in ipairs{
						"rough_english_duration",
						"num_to_thousands",
						"header",
						"footer",
						"about",
						"aelua_bar",
						"home_bar",
						"user_bar",
						"missing_content",
					} do
		tab[n]=function(...) return _M.basefunc[n](tab,...) end
	end
		


end

-- fill cake with juicy chunks ready to be served
function fill_cake(srv)
	local cake={}
	
	cake.url=srv.url
	cake.urlesc=url_esc(srv.url)
	cake.qurl=srv.qurl
	cake.url_base=srv.url_base

	cake.html={}
	cake.html.css="{-css}" -- use css chunk
	cake.html.title="{-title}" -- empty title
	cake.html.extra="" -- squirt this into the head
	
-- for example add an atom link using cake.html.custom
-- <link rel="alternate" type="application/atom+xml" title="{blogtitle}" href="{blogurl}" />


	cake.html.js=[[
<script type="text/javascript" src="/js/base/head.min.js"></script>
<script type="text/javascript">
head.fs={};
head.fs.jquery_js="http://ajax.googleapis.com/ajax/libs/jquery/1.4.3/jquery.min.js";
head.fs.jquery_ui_js="http://ajax.googleapis.com/ajax/libs/jqueryui/1.8.2/jquery-ui.min.js";
head.fs.jquery_validate_js="http://ajax.microsoft.com/ajax/jQuery.Validate/1.6/jQuery.Validate.min.js";
head.fs.jquery_asynch_image_loader_js="/js/base/JqueryAsynchImageLoader-0.8.min.js";
head.fs.jquery_wet_js="/js/base/jquery-wet.js";
head.fs.jquery_wakaedit_js="/js/base/jquery-wakaedit.js";
head.fs.swfobject_js="http://ajax.googleapis.com/ajax/libs/swfobject/2.2/swfobject.js";
head.fs.gcf_js="http://ajax.googleapis.com/ajax/libs/chrome-frame/1/CFInstall.min.js";
head.fs.ace_js="http://d1n0x3qji82z53.cloudfront.net/src-min-noconflict/ace.js";
</script>
]]
	
-- open main html chunk of a page and fill in head chunk
	cake.html.head=[[
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>{cake.html.title}</title>
<link rel="stylesheet" type="text/css" href="/css/base/pagecake.css" />
{-cake.html.extra}
{cake.html.js}
<style type="text/css">{cake.html.css}</style>
</head>
<body>
]]

-- close main html chunk of a page
	cake.html.foot=[[
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

	cake.edit=""
	cake.notes=""
	cake.plate=[[
<h1>{title}</h1>
{body}
{.cake.notes}
]]

	cake.admin=""
	cake.admin_waka_bar=[[
<div class="cake_admin_bar">
	<form action="{cake.qurl}" method="POST" enctype="multipart/form-data">
		<button type="submit" name="submit" value="edit" class="cake_button" > Edit </button>
		<a href="?cmd=edit&page={-cake.pagename}" class="cake_button" > EditOnly </a>
		<a href="/!/admin" class="cake_button" > Admin </a>
	</form>
</div>
]]
	cake.admin_blog_bar=[[
<div class="cake_admin_bar">
	<form action="{cake.qurl}" method="POST" enctype="multipart/form-data">
		{-cake.admin_blog_bar_edit}
		<a href="/?cmd=edit&page=blog" class="cake_button" > EditWaka </a>
		<a href="/blog" class="cake_button" > View Blog </a> 
		<a href="/blog/!/admin/pages" class="cake_button" > List </a> 
		<a href="/blog/!/admin/edit/$newpage" class="cake_button" > New Post </a>
	</form>
</div>
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
	<div class="cake_wakaedit_bar">
		<input type="submit" name="submit" value="Save" class="cake_button" />
		<input type="submit" name="submit" value="Save and Edit" class="cake_button" />
		<input type="submit" name="submit" value="Preview" class="cake_button" />
		<input type="submit" name="submit" value="Cancel" class="cake_button" />
	</div>
	<textarea name="text" class="cake_field cake_wakaedit_field">{.cake.admin_waka_form_text}</textarea>
</form>

<script>
window.auto_wakaedit={who:".cake_wakaedit",width:960,height:window.innerHeight-40};
head.js(head.fs.jquery_wakaedit_js);
</script>

</div>
]]
	cake.admin_blog_bar_edit=[[
		<a href="/blog/!/admin/edit/$hash/{it.id}" class="cake_button" > EditPost </a>
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
<div class="cake_bars">{cake.homebar.div}{cake.userbar.div}</div>
]]
	cake.userbar={}
	cake.userbar.hello="Hello {cake.userbar.profile},"

	if srv.user and srv.sess then -- a user is logged i and viewing
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

	cake.blog_bar=[[<div class="cake_blog_bar"><a href="{-opts.link_next}">NEXT<a> <a href="{-opts.link_prev}">PREV<a></div>]]

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


import(_M)

