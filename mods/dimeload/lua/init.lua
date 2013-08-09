-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local wet_html=require("wetgenes.html")
local replace=wet_html.replace

local sys=require("wetgenes.www.any.sys")

local json=require("wetgenes.json")
local dat=require("wetgenes.www.any.data")

local users=require("wetgenes.www.any.users")

local log=require("wetgenes.www.any.log").log -- grab the func from the package

local wstr=require("wetgenes.string")
local wet_string=wstr
local trim=wet_string.trim
local str_split=wet_string.str_split
local serialize=wet_string.serialize
local macro_replace=wet_string.macro_replace

local wet_waka=require("wetgenes.waka")
local d_sess =require("dumid.sess")
local d_users=require("dumid.users")

-- require all the module sub parts
local html=require("dimeload.html")

local waka=require("waka")
local note=require("note")

local wakapages=require("waka.pages")
local comments=require("note.comments")

local dl_users=require("dimeload.users")
local dl_transactions=require("dimeload.transactions")

local dl_projects=require("dimeload.projects")
local dl_pages=require("dimeload.pages")

local dl_downloads=require("dimeload.downloads")

module("dimeload")

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
	if srv.method=="POST" and srv:check_referer(url) then
		for i,v in pairs(srv.posts) do
			posts[i]=v
		end
	end
	if posts.submit then posts.submit=trim(posts.submit) end
	for n,v in pairs(srv.uploads) do
		posts[n]=v
	end
	
	put("This is a dimeload test, please ignore it for now")

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

--log("check : "..id)

	local projectname
	id:gsub("/dl/([^/]+)",function(s) projectname=s end)

	if not projectname then return end
	
	log("dimeload project update : "..projectname)

	local refined=wakapages.load(srv,id)[0]
	local ldat=refined.lua or {} -- better just to use #lua chunk for data, so it can parse and maintain native types

		local it=dl_projects.set(srv,projectname,function(srv,e) -- create or update
			local c=e.cache
			
			c.title=refined.title or ""
			c.body=refined.body or ""


			c.published=ldat.published or 0
			c.files=ldat.files or {}

--[[
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
]]

			return true
		end)


--[[

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
]]
end

-- add our hook to the waka stuffs, this should get called on module load
-- We want to catch all edits here and then filter them in the function
waka.add_changed_hook("^/",waka_changed)

