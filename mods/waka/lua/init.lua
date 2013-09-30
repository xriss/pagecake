-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local wet_html=require("wetgenes.html")

local sys=require("wetgenes.www.any.sys")

local json=require("wetgenes.json")
local dat=require("wetgenes.www.any.data")

local users=require("wetgenes.www.any.users")

local fetch=require("wetgenes.www.any.fetch")

local img=require("wetgenes.www.any.img")

local log=require("wetgenes.www.any.log").log -- grab the func from the package

local wet_sandbox=require("wetgenes.sandbox")

local wet_string=require("wetgenes.string")
local wstr=wet_string
local replace=wet_string.replace
local macro_replace=wet_string.macro_replace
local trim=wet_string.trim
local str_split=wet_string.str_split
local serialize=wet_string.serialize

local wet_waka=require("wetgenes.waka")
local d_sess =require("dumid.sess")

-- require all the module sub parts
local html=require("waka.html")
local pages=require("waka.pages")
local edits=require("waka.edits")

local comments=require("note.comments")

--
-- Which can be overeiden in the global table opts
--



module("waka")
local function make_put(srv)
	return function(a,b)
		b=b or {}
		b.srv=srv
		srv.put(wet_html.get(html,a,b))
	end
end
local function make_get(srv)
	return function(a,b)
		b=b or {}
		b.srv=srv
		return wet_html.get(html,a,b)
	end
end

hooks={
	changed={},
}
function call_hooks_changed(srv,pagename)
	local ep
	for f,p in pairs(hooks.changed) do -- update hooks?
--print("hook ",p," : ",pagename)
		if string.find(pagename,p) then
			if not ep then ep=pages.get(srv,pagename) end
			f(srv,ep)
		end
	end
end

-----------------------------------------------------------------------------
--
-- handle callbacks
--
-----------------------------------------------------------------------------
function add_changed_hook(pat,func)

	hooks.changed[func]=pat -- use func as the key
	
end



-----------------------------------------------------------------------------
--
-- fill the pageopts and return
--
-----------------------------------------------------------------------------
function fill_opts(srv,pageopts)
	local pageopts=pageopts or {}

	pageopts.flame="on"

	pageopts.vars=srv.vars -- page code is allowed access to these bits
	pageopts.url           = srv.url
	pageopts.url_local     = srv.url_local
	pageopts.url_slash     = srv.url_slash
	pageopts.url_slash_idx = srv.url_slash_idx
	
	pageopts.limit=math.floor(tonumber(srv.vars.limit or 10) or 10)
	if pageopts.limit<1 then pageopts.limit=1 end
	
	pageopts.offset=math.floor(tonumber(srv.vars.offset or 0) or 0)
	if pageopts.offset<0 then pageopts.offset=0 end
	
	pageopts.offset_next=pageopts.offset+pageopts.limit
	pageopts.offset_prev=pageopts.offset-pageopts.limit
	if pageopts.offset_prev<0 then pageopts.offset_prev=0 end
	
	return pageopts
end
-----------------------------------------------------------------------------
--
-- fill the crumbs and return
--
-----------------------------------------------------------------------------
function fill_crumbs(srv,pagename)
	local url="/"-- srv.url_base
	local crumbs={}
	crumbs.plate="{cake.homebar.crumbs_plate}"
	if pagename and pagename~="" then
		for i,v in ipairs( wstr.split(pagename,"/",true) ) do
			url=url..wstr.url_escape(v)
			local text=string.gsub(v,"([^%w%s]*)","")
			crumbs[#crumbs+1]={url=url,text=text}
			url=url.."/"
		end
	end
	return crumbs
end

-----------------------------------------------------------------------------
--
-- fill the refined values from the given pagename,
-- including the cake and opts also bubble up the chunks
--
-----------------------------------------------------------------------------
function fill_refined(srv,pagename,refined)

	local refined=refined or {}
	refined.cake=html.fill_cake(srv)
	refined.cake.pagename=pagename
	refined.cake.homebar.crumbs=fill_crumbs(srv,pagename)
	refined.opts=fill_opts(srv,refined.opts)
	
	local chunks=pages.load(srv,"/"..pagename,{refined=refined})

	return refined	
end


-----------------------------------------------------------------------------
--
-- comments for pagename, handle post inputs and more
--
-----------------------------------------------------------------------------
function build_notes(srv,pagename,opts)

local sess,user=d_sess.get_viewer_session(srv)
local get=make_get(srv)
local posts={}
if srv.method=="POST" and srv:check_referer(srv.url) then
	for i,v in pairs(srv.posts) do
		posts[i]=v
	end
end
	
	local _tab={}
	local _put=function(a,b)
		local s=get(a,b)
		_tab[#_tab+1]=s
	end
	local t=opts or {}
	t.title=pagename
	t.url="/"..pagename
	t.put=_put
	t.posts=posts
	t.get=get
	t.sess=sess
	t.user=user
	comments.build(srv,t)
	return table.concat(_tab)
end	
			
-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-----------------------------------------------------------------------------
function serv(srv)
local sess,user=d_sess.get_viewer_session(srv)
local put=make_put(srv)
local get=make_get(srv)

local display_edit
local display_edit_only=false
local ext

-- allow ?page=this to override page name from url
	local aa={}
	if srv.vars.page then -- overload with this forced pagename
		if srv.vars.page~="" then
			aa=str_split("/",srv.vars.page,true)
		end
	else
		for i=srv.url_slash_idx,#srv.url_slash do
			aa[#aa+1]=srv.url_slash[ i ]
		end
	end
	if aa[1]=="" then table.remove(aa,1) end-- kill any leading slash
	if aa[#aa]=="" then aa[#aa]=nil end-- kill any trailing slash
	
	if aa[1]=="!" and aa[2]=="admin" then
		return serv_admin(srv)
	end
	
-- find extension and remove it from name
	if aa[#aa] then
		local ap=str_split(".",aa[#aa])
		if #ap>1 and ap[#ap] then
			ext=ap[#ap]
			ap[#ap]=nil
			aa[#aa]=table.concat(ap,".")
			if aa[#aa]=="" then aa[#aa]=nil end-- kill any trailing slash we may have just created
		end
	end


-- finally build page name and also build crumbs

	local url=srv.url_base
	local crumbs={ }
	crumbs.plate="{cake.homebar.crumbs_plate}"
	for i,v in ipairs(aa) do
		url=url..wstr.url_escape(v)
		local text=string.gsub(v,"([^%w%s%-%_]*)","")
		crumbs[#crumbs+1]={url=url,text=text}
		url=url.."/"
	end
	local pagename="/"..table.concat(aa,"/")
	local url=srv.url_base..table.concat(aa,"/")
	if ext then url=url.."."..ext end -- this is a page extension
	
	if not srv.vars.page and srv.url~=url then -- force a redirect to the page name
		return srv.redirect(url)
	end



	local posts={} -- remove any gunk from the posts input
	-- check if this post probably came from this *SITE* before allowing post params
	-- this is less of a check than normal since we are now lax with wiki edit urls
	if srv.method=="POST" and srv:check_referer(srv.url) then
		for i,v in pairs(srv.posts) do
			posts[i]=v
--			posts[i]=string.gsub(v,"[^%w%p ]","") -- sensible characters only please
		end
	end
	if posts.submit then posts.submit=trim(posts.submit) end
	
	local page=pages.manifest(srv,pagename)
	local page_edit
	if posts.text or posts.submit or (srv.vars.cmd and srv.vars.cmd=="edit") then
	
		if posts.submit=="Cancel" then
			return srv.redirect(url)
		end
		
		if posts.text then -- replace the page with what was in the form?
			page.cache.text=posts.text
		end
		
		if user and user.cache and user.cache.admin then -- admin
			if posts.submit=="Save" or posts.submit=="Save and Edit" then -- save page to database
				if posts.text then
					local chunks=wet_waka.text_to_chunks(posts.text)
					local e=pages.edit(srv,pagename,
						{
							text=posts.text,
							author=user.cache.id,
							note=(chunks.note and chunks.note.text) or "",
							tags=wet_waka.text_to_tags(chunks.tags and chunks.tags.text),
						})
					call_hooks_changed(srv,pagename)
				end
			end
			
			if posts.submit~="Save" then -- keep editing

--todo, remove since the new way does not need
display_edit=get("waka_edit_form",{text=page.cache.text}) -- still editing

				page_edit=page.cache.text
				if (srv.vars.cmd and srv.vars.cmd=="edit") then display_edit_only=true end
			end
			
		end
	end
	
	local refined={}
	refined.cake=html.fill_cake(srv)
	refined.cake.pagename=pagename
	refined.cake.homebar.crumbs=crumbs
	if page_edit then refined.cake.admin_waka_form_text=wet_html.esc(page_edit) end
	
	refined.opts=fill_opts(srv)
	
	local refined_opts={}
	refined_opts.refined=refined
	if display_edit_only then
		refined_opts.unrefined=true
	end

	local chunks=pages.load(srv,pagename,refined_opts)
	
	if refined.opts.redirect then -- we may force a redirect here
		return srv.redirect(refined.opts.redirect)
	end

-- disable comments if page is not saved to the database IE a MISSING PAGE	
-- except when page has been locked upstream
	if page.key.notsaved then
		if refined.opts.lock=="on" then -- we are using fake pages and smart lua codes to generate them
		else -- redirect to parent except when we are admin
			if not( user and user.cache and user.cache.admin ) then -- only admins can go to empty pages
				if page.cache.id~="/welcome" then -- special safe welcome page even if it doesnt exist
					return srv.redirect(page.cache.group)
				end
			end
		end
	end

-- disable comments if this is not the real page address
	if srv.vars.page then refined.opts.flame="off" end

	if ext=="css" then -- css only, with cache enabled
	
		srv.set_mimetype("text/css; charset=UTF-8")
		srv.set_header("Cache-Control","public") -- allow caching of page
		srv.set_header("Expires",os.date("%a, %d %b %Y %H:%M:%S GMT",os.time()+(60*60))) -- one hour cache
		srv.put(refined.css or "")
		
	elseif ext=="data" then -- raw chunk data
	
		srv.set_mimetype("text/plain; charset=UTF-8")
		srv.put(page.cache.text or "")
		
	elseif ext=="dump" then -- dump out all the bubbled chunks as json

		if user and user.cache and user.cache.admin then -- only admin
			srv.set_mimetype("text/plain; charset=UTF-8")
			srv.put( json.encode(chunks) )
		end
	
	elseif ext and chunks[ext] then -- generic extension dump using named chunk
	
		srv.set_header("Cache-Control","public") -- allow caching of page
		srv.set_header("Expires",os.date("%a, %d %b %Y %H:%M:%S GMT",os.time()+(60*60))) -- one hour cache
		srv.set_mimetype(chunks[ext].opts.mimetype or "text/plain; charset=UTF-8")
		srv.put(macro_replace(refined[ext],refined))
		
	else -- new pagecake way
	
		if user and user.cache and user.cache.admin then
			if refined.cake.admin_waka_form_text then
				refined.cake.admin=refined.cake.admin.."{cake.admin_waka_form}"
			else
				refined.cake.admin=refined.cake.admin.."{cake.admin_waka_bar}"
			end
		end
		
		if display_edit_only then
			refined.cake.plate=""
		end

		if refined.opts.flame=="on" then -- add comments to this page
			local _tab={}
			local _put=function(a,b)
				local s=get(a,b)
				_tab[#_tab+1]=s
			end
			local t={
				title=refined.title or pagename,
				url=srv.url_local,
				posts=posts,
				get=get,
				put=_put,
				sess=sess,
				user=user,
			}
			comments.build(srv,t)
			refined.cake.notes=table.concat(_tab)
		end
		
		srv.set_mimetype("text/html; charset=UTF-8")
		srv.put(macro_replace("{cake.html.plate}",refined))
	

	end
end



-----------------------------------------------------------------------------
--
-- handle admin special pages/lists
--
-----------------------------------------------------------------------------
function serv_admin(srv)
local sess,user=d_sess.get_viewer_session(srv)
local put=make_put(srv)
local get=make_get(srv)

	if not( user and user.cache and user.cache.admin ) then -- adminfail
		return false
	end

	local cmd= srv.url_slash[ srv.url_slash_idx+2]
	
	
	srv.set_mimetype("text/html; charset=UTF-8")
	put("header",{title="waka : admin"})

	put("waka_bar",{})

	if cmd=="pages" then
	
		local list=pages.list(srv,{})
		
		for i=1,#list do local v=list[i]
		
			local dat={
				page=v.cache,
				page_name=v.cache.id,
				url_base=srv.url_base:sub(1,-2),
				time=os.date("%Y/%m/%d %H:%M:%S",v.cache.updated),
				author=( (v.cache.edit and v.cache.edit.author) or "")
				}
			put([[
<a style="position:relative;display:block;width:960px" href="{url_base}{page_name}">
{time} : {page_name} 
<span style="position:absolute;right:0px">{author}</span>
</a>]],dat)

		end
	
	elseif cmd=="edits" then
	
		local list=edits.list(srv,{})
		
		for i=1,#list do local v=list[i]
		
			local dat={
				page=v.cache,
				page_name=v.cache.page,
				url_base=srv.url_base:sub(1,-2),
				time=os.date("%Y/%m/%d %H:%M:%S",v.cache.time),
				author=(v.cache.author or "")
				}
			put([[
<a style="position:relative;display:block;width:960px" href="{url_base}{page_name}">
{time} : {page_name}
<span style="position:absolute;right:0px">{author}</span>
</a>]],dat)

		end
	else
	
			put([[
			<br/>
			<a href="{srv.url_base}?cmd=edit"> Edit root of all pages </a><br/>
			<br/>
			<a href="{srv.url_base}!/admin/pages"> view all pages </a><br/>
			<br/>
			<a href="{srv.url_base}!/admin/edits"> view all edits </a><br/>
			<br/>
]],{})

	end
	

	put("footer")
	
end
