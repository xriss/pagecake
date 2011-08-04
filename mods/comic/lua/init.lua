
local wet_html=require("wetgenes.html")
local replace=wet_html.replace

local sys=require("wetgenes.aelua.sys")

local json=require("wetgenes.json")
local dat=require("wetgenes.aelua.data")

local users=require("wetgenes.aelua.users")

local log=require("wetgenes.aelua.log").log -- grab the func from the package

local wet_string=require("wetgenes.string")
local trim=wet_string.trim
local str_split=wet_string.str_split
local serialize=wet_string.serialize
local macro_replace=wet_string.macro_replace

local wet_waka=require("wetgenes.waka")
local d_sess =require("dumid.sess")
local d_users=require("dumid.users")

-- require all the module sub parts
local html=require("comic.html")

local waka=require("waka")
local note=require("note")

local comics=require("comic.comics")

local wakapages=require("waka.pages")
local comments=require("note.comments")

local math=math
local string=string
local table=table
local os=os

local ipairs=ipairs
local pairs=pairs
local tostring=tostring
local tonumber=tonumber
local type=type
local pcall=pcall
local loadstring=loadstring


-- opts
local opts_mods_comic=(opts and opts.mods and opts.mods.comic) or {}

module("comic")

local function make_get_put(srv)
	local get=function(a,b)
		b=b or {}
		b.srv=srv
		return wet_html.get(html,a,b)
	end
	return  get , function(a,b) srv.put(get(a,b)) end
end

-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-----------------------------------------------------------------------------
function serv(srv)
local sess,user=d_sess.get_viewer_session(srv)
local get,put=make_get_put(srv)
	
	local url=srv.url_base
	if url:sub(-1)=="/" then url=url:sub(1,-2) end -- trim any trailing /

-- this is the base url we use for comments
	local t={""}
	for i=4,srv.url_slash_idx-1 do
		t[#t+1]=srv.url_slash[i]
	end
	local baseurl=table.concat(t,"/")

-- handle posts cleanup
	local posts={} -- remove any gunk from the posts input
	-- check if this post probably came from this page before allowing post params
	if srv.method=="POST" and srv.headers.Referer and string.sub(srv.headers.Referer,1,string.len(url))==url then
		for i,v in pairs(srv.posts) do
			posts[i]=v
		end
	end
	if posts.submit then posts.submit=trim(posts.submit) end
	for n,v in pairs(srv.uploads) do
		posts[n]=v
	end

-- need the base wiki page, for style yo

	local group=nil--"pms"
	local comicname=nil--"pms"

	local pageopts={
		flame="on",
	}
	srv.pageopts=pageopts -- keep the page options here
	
	local crumbs={ {url="/",text="Home"} , {url="/comic",text="comic"} }
	srv.crumbs=crumbs

	
	comicname=srv.url_slash[srv.url_slash_idx+0]

	local list={}

	local title="comic"
	local plate_comic="comic_inlist"
	local cnext=nil
	local cprev=nil
	local url_local="/comic"
	local url_waka="comic"
	
	if #list==0 and comicname then

		list=comics.list(srv,{name=comicname,limit=1})
		
		if list[1] then
			group=list[1].cache.group
			title=list[1].cache.title
			plate_comic="comic_inpage"
			local pubdate=list[1].cache.pubdate
			cprev=comics.list(srv,{limit=1,sort="-pubdate",["<pubdate"]=pubdate})[1]
			cnext=comics.list(srv,{limit=1,sort="+pubdate",[">pubdate"]=pubdate})[1]
			
			url_local="/comic/"..comicname
			url_waka=group.."/"..comicname
			
			crumbs[#crumbs+1]={url=url_local,text=comicname}

		else
			return srv.redirect(srv.url_base:sub(1,-2))
		end
		
	end
	
--[[
	if #list==0 and group then

		title="comic "..(group or "")
		plate_comic="comic_inlist"
		list=comics.list(srv,{group=group,limit=50,sort="pubdate"})
	
	end
]]
	
	if #list==0 then
	
		group=nil
		title="comics"
		plate_comic="comic_inlist"
		list=comics.list(srv,{group=group,limit=50,sort="pubdate"})
		
		pageopts.flame="off"
		
		url_waka="comic"
	
	end


	local refined	
	
	if group then 
		refined=wakapages.load(srv,"/comic/"..group)[0]
	else
		refined=wakapages.load(srv,"/comic")[0]
	end


	local css=refined and refined.css


-- plates to display the comic in a list or on its own page
-- you can override these in the wiki

refined["comic_inlist"]=refined["comic_inlist"] or [[
<a href="/comic/{it.name}" title="{it.title}" style="background:#000;margin:20px auto;position:relative;display:block;width:{it.width}px;height:{it.height}px"><img data-href="{it.image}"/></a>
]]
-- an easy shadow, if you put it in the a tag
-- <div style="position:absolute;width:100px;height:100px;right:-100px;bottom:0px;background-image:url(http://4lfa.com/css/img/diag_shad.png)"></div>

refined["comic_inpage"]=refined["comic_inpage"] or [[
<h1 style="text-align:center;height:100px;">{it.title}</h1>
<div style="margin:20px auto;width:{it.width}px;" >
<span title="{it.title}" style="background:#000;margin:20px auto;position:relative;display:block;width:{it.width}px;height:{it.height}px"><img data-href="{it.image}"/>
</span>
<div style="text-align:center;height:100px;" >
<a href="/comic/{cprev.name}" style="width:100px;height:100px;opacity:0.25;" ><img src="{cprev.icon}" width="100" height="100" /></a>
<span style="display:inline-block;width:10px;"></span>
<a href="/comic/{cnext.name}" style="width:100px;height:100px;opacity:0.25;" ><img src="{cnext.icon}" width="100" height="100" /></a>
</div>
<div>{it.body}</div>
</div>
]]

	if cprev then refined.cprev=cprev.cache end
	if cnext then refined.cnext=cnext.cache end
	
	if list[1] then
		refined.cprev=refined.cprev or list[1].cache
		refined.cnext=refined.cnext or list[1].cache
	end
	
	srv.set_mimetype("text/html; charset=UTF-8")
	put("header",{title=title,css=css})
	put("comic_bar",{page=url_waka})

	local ss={}
	for i,v in ipairs(list) do
	
		refined.it=v.cache

		local text=get(macro_replace(refined[plate_comic] ,refined))

		ss[#ss+1]=text
	end
	
	if refined then

		refined.body=table.concat(ss)
		
		put(macro_replace(refined.plate or "{body}",refined))

	end
	
	put([[<script> 
head.js(head.fs.jquery_js,
head.fs.jquery_asynch_image_loader_js,
function(){
	$(function(){
		$('img').jail({effect:"fadeIn"});
	});
});
</script>]])

	if pageopts.flame=="on" then -- add comments to this page
		comments.build(srv,{title=title,url=url_local,posts=posts,get=get,put=put,sess=sess,user=user})
	elseif pageopts.flame=="anon" then -- add *anonymous* comments to this page
		comments.build(srv,{title=title,url=url_local,posts=posts,get=get,put=put,sess=sess,user=user,anon="default"})
	end

	put("footer")
	
end


-----------------------------------------------------------------------------
--
-- hook into waka page updates, any page under will come in here
-- that way we canuse the waka to update our basic data
--
-- page is just an entity get on the page, check its id or whatever before proceding
--
-----------------------------------------------------------------------------
function waka_changed(srv,page)

	if not page then return end

	local id=tostring(page.key.id)

	local doit=false
	for i,n in ipairs(opts_mods_comic.groups or {}) do
	
		local check="/"..n.."/"
		
		if id:sub(1,#check)==check then
			doit=true
			break
		end
	end
	if not doit then return end -- we are not interested in this page
	
	log("comic update : "..id)

	local refined=wakapages.load(srv,id)[0]

	local group=refined.group or ""
	local name=refined.name or ""

	local title=refined.title or ""
	local body=refined.body or ""
	local width=math.floor(tonumber(refined.width or 0) or 0)
	local height=math.floor(tonumber(refined.height or 0) or 0)

	local pubdate=math.floor(tonumber(refined.time or 0) or 0) -- force a published date?

	local image=refined.image or ""
	local icon=refined.icon or ""
	
--	local tags=refined.tags or {}
	
	if id and title then 
	

		local it=comics.manifest(srv,id,function(srv,e) -- create or update
			e.cache.group=group -- update group
			e.cache.name=name -- update name
			
			e.cache.title=title -- update title
			e.cache.body=body -- update body

			e.cache.width=width -- update width
			e.cache.height=height -- update height

			e.cache.image=image -- update image
			e.cache.icon=icon -- update icon

			if pubdate==0 then -- update with the now
			
				if (not e.cache.pubdate) or (e.cache.pubdate==0) then -- force a publish time only if not set
					e.cache.pubdate=srv.time
				end
				
			else -- force
				e.cache.pubdate=pubdate -- update published time
			end

			return true
		end)
		
	end
	
end

-- add our hook to the waka stuffs, this should get called on module load
-- We want to catch all edits here and then filter them in the function
waka.add_changed_hook("^/",waka_changed)


