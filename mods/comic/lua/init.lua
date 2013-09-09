-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local wet_html=require("wetgenes.html")
local replace=wet_html.replace

local sys=require("wetgenes.www.any.sys")

local json=require("wetgenes.json")
local dat=require("wetgenes.www.any.data")

local users=require("wetgenes.www.any.users")

local log=require("wetgenes.www.any.log").log -- grab the func from the package

local wet_string=require("wetgenes.string")
local trim=wet_string.trim
local str_split=wet_string.str_split
local serialize=wet_string.serialize
local macro_replace=wet_string.macro_replace

local stash=require("wetgenes.www.any.stash")


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


-- opts


module("comic")

local function make_get_put(srv)
	local get=function(a,b)
		b=b or {}
		b.srv=srv
		return wet_html.get(html,a,b)
	end
	return  get , function(a,b) srv.put(get(a,b)) end
end

function get_comic_stash(srv,v)

	local sname="comic="..v.id.."&type=links&v1"

	local cstash=stash.get(srv,sname)
	if  	( not cstash ) or 
			( not cstash.cachetime ) or
			( cstash.cachetime<os.time() ) then
			
		cstash={}
		local function gcache(v) return v and v.cache end

		cstash.cfirst=gcache(comics.list(srv,{limit=1,sort="+pubdate"})[1])
		cstash.clast=gcache(comics.list(srv,{limit=1,sort="-pubdate"})[1])

		cstash.cprev=gcache(comics.list(srv,{limit=1,sort="-pubdate",["<pubdate"]=v.pubdate})[1])
		cstash.cnext=gcache(comics.list(srv,{limit=1,sort="+pubdate",[">pubdate"]=v.pubdate})[1])
		
		cstash.crandom=gcache(comics.list(srv,{limit=1,offset=math.random(1,100),sort="-pubdate"})[1])
		
		cstash.cachetime=os.time()+(60*60) -- just one hour TTL

		stash.put(srv,sname,cstash)
	end
	return cstash
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
	if srv.method=="POST" and srv:check_referer(url) then
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
	local cstash={}
	local url_local="/comic"
	local url_waka="comic"
	
	if #list==0 and comicname then

		list=comics.list(srv,{name=comicname,limit=1})
		
		if list[1] then
			group=list[1].cache.group
			title=list[1].cache.title
			plate_comic="comic_inpage"
			
			cstash=get_comic_stash(srv,list[1].cache)
			
			url_local="/comic/"..comicname
			url_waka=group.."/"..comicname
			
			crumbs[#crumbs+1]={url=url_local,text=comicname}

		end
		
	end
	

	if #list==0 and comicname then -- try for groups

		local groups=str_split("+",comicname,true)
		
		if groups[1]~="" then
			
			group=groups[1] 
			 
			if groups[2] then 
				list=comics.list(srv,{group=groups,limit=50,sort="pubdate"}) -- this is an in query
			else
				list=comics.list(srv,{group=group,limit=50,sort="pubdate"})
			end
			
			if list[1] then

				title="comic "..(group or "")
				plate_comic="comic_inlist"
				pageopts.flame="off"
				
				url_waka="comic/"..(group or "")

				for i,v in ipairs(groups) do
					url_local="/comic/"..v
					crumbs[#crumbs+1]={url=url_local,text=v}
				end
			end
			
		end

	end
	
	if #list==0 then
	
		if comicname then return srv.redirect(srv.url_base:sub(1,-2)) end -- redirect to all comics

		group=nil
		title="comics"
		plate_comic="comic_inlist"
		list=comics.list(srv,{group=group,limit=50,sort="pubdate"})
		
		pageopts.flame="off"
		
		url_waka="comic"
	
	end


	local refined	
	if comicname then 
		refined=waka.fill_refined(srv,"comic/"..comicname)
	else
		refined=waka.fill_refined(srv,"comic")
	end

	
	if list[1] then
		refined.cprev=refined.cprev or list[1].cache
		refined.cnext=refined.cnext or list[1].cache
	end

	local comics={}
	for i,v in ipairs(list) do	
		comics[i]=v.cache
	end

	comics.plate="{cake."..plate_comic.."}"
	
	
	refined.comics=comics
	refined.it=comics[1]
	refined.it.cfirst=cstash.cfirst
	refined.it.clast=cstash.clast
	refined.it.crandom=cstash.crandom
	refined.it.cprev=cstash.cprev
	refined.it.cnext=cstash.cnext

	if user and user.cache and user.cache.admin then
		refined.cake.admin="{cake.admin_comic_bar}"
	end
	
--	refined.cake.admin_list=tab
	refined.body=[[
	{comics}
]]

	refined.cake.notes=waka.build_notes(srv,refined.cake.pagename)

	srv.set_mimetype("text/html; charset=UTF-8")
	put(macro_replace("{cake.html.plate}",refined))


--[[	
	srv.set_mimetype("text/html; charset=UTF-8")
	put("header",refined)
	put("comic_bar",refined)

	if refined then

		refined.body=table.concat(ss)
		
		put(macro_replace(refined.plate or "{body}",refined))

	end

	if pageopts.flame=="on" then -- add comments to this page
		comments.build(srv,{title=refined.title,url=url_local,posts=posts,get=get,put=put,sess=sess,user=user})
	elseif pageopts.flame=="anon" then -- add *anonymous* comments to this page
		comments.build(srv,{title=refined.title,url=url_local,posts=posts,get=get,put=put,sess=sess,user=user,anon="default"})
	end

	put("footer",refined)
]]

end


-----------------------------------------------------------------------------
--
-- get a html string which is a handful of commics,
--
-----------------------------------------------------------------------------
function chunk_import(srv,opts)
opts=opts or {}

local get,put=make_get_put(srv)

	local t={}
	local css=""
	local list=comics.list(srv,opts)

	local ret={}
	for i,v in pairs(opts) do ret[i]=v end -- copy opts into the return
	
	for i,v in ipairs(list) do
	
		local c=v.cache
		
		c.date=os.date("%Y-%m-%d %H:%M:%S",c.published)
		c.link="/comic/"..c.name
	
		if #list==1 then -- special extras for single comic
			
			local cstash=get_comic_stash(srv,c)
			for n,d in pairs(cstash) do
				c[n]=d
			end
			c.cprev=c.cprev or c
			c.cnext=c.cnext or c
		end

		if type(opts.hook) == "function" then -- fix up each item?
			opts.hook(v,{class="comic"})
		end
		
		ret[#ret+1]=c
	end
	
	
	return ret
		
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
	for i,n in ipairs(srv.opts("mods","comic","groups") or {}) do
	
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

	local pubdate=math.floor(tonumber(refined.time or page.props.created) or page.props.created) -- force a published date?

	local image=refined.image or ""
	local icon=refined.icon or ""
	
	local rand=math.random()
	
--	local tags=refined.tags or {}
	
	if id and title then 
	

		local it=comics.set(srv,id,function(srv,e) -- create or update
			e.cache.group=group -- update group
			e.cache.name=name -- update name
			
			e.cache.title=title -- update title
			e.cache.body=body -- update body

			e.cache.width=width -- update width
			e.cache.height=height -- update height

			e.cache.image=image -- update image
			e.cache.icon=icon -- update icon

			e.cache.pubdate=pubdate -- update published time

			e.cache.random=rand -- sort by this random number

			return true
		end)
		
	end
	
end

-- add our hook to the waka stuffs, this should get called on module load
-- We want to catch all edits here and then filter them in the function
waka.add_changed_hook("^/",waka_changed)


