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

local wet_waka=require("wetgenes.waka")
local d_sess =require("dumid.sess")
local d_users=require("dumid.users")

-- require all the module sub parts
local html=require("todo.html")

local waka=require("waka")
local note=require("note")

local wakapages=require("waka.pages")
local comments=require("note.comments")

local things=require("todo.things")


-- opts
local opts_mods_profile=(opts and opts.mods and opts.mods.profile) or {}

module("todo")

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
	
	local name=srv.url_slash[srv.url_slash_idx+0] -- the task name, could be anything
	if name=="" then name=nil end -- can not be ""
	if name then name=name:lower() end -- force to lower
	
	srv.crumbs={ {url="/",text="Home"} , {url="/todo",text="todo"} , }


	if name then -- need to check the name is a valid thing
	
		local url_local="/todo/"..name
	
		local thing=things.get(srv,url_local)
		
		if thing then -- we gots a page
	
			srv.crumbs[#srv.crumbs+1]={url=url_local,text=name}
			
			local refined=wakapages.load(srv,url_local)[0]
		
			srv.set_mimetype("text/html; charset=UTF-8")
			put("header",{title="todo : "..refined.title})
			put("todo_bar",{page=url_local:sub(2)})
			
			put( macro_replace(refined.plate or "<h1>{title}</h1>{body}", refined ) )
					
			comments.build(srv,{title=refined.title or name,url=url_local,posts=posts,get=get,put=put,sess=sess,user=user})
				
			put("footer")
			
			return
		end
		
	end

-- by default list all possible things
	
-- need the base wiki page, for style yo
	local refined=wakapages.load(srv,"/todo")[0]

	srv.set_mimetype("text/html; charset=UTF-8")
	put("header",{title="todo"})
	put("todo_bar",{page="todo"})
	
	local l=things.list(srv,{})
	local things={}
	for i,v in ipairs(l) do
		dat.build_cache(v) -- expand
		things[i]=v.cache
	end
	things.plate="plate_things"
	refined.things=things
	refined.plate_things=refined.plate_things or [[
<a href="{it.id}"><span style="width:100px;display:inline-block;">{it.total}</span>{it.title}</a><br/>
]]

	refined.body=refined.body or [[
<h1>This is a list of things we plan todo</h1>
Click on an item for more info and the opportunity to bribe us to do it quicker.<br/>
<br/>
{things}
<br/>
<br/>
]]
	put( macro_replace(refined.plate or "{body}", refined ) )
			
	put("footer")
end


-----------------------------------------------------------------------------
--
-- hook into waka page updates, any page under /todo will come in here
-- that way we canuse the waka to update our basic todo data
--
-----------------------------------------------------------------------------
function waka_changed(srv,page)

	if not page then return end
	if tostring(page.key.id):sub(1,6)~="/todo/" then return end
	
	local id=page.key.id	
	local chunks=wet_waka.text_to_chunks( page.cache.text )
	local title=chunks.title.text
	
	log(tostring(id))
	log(tostring(title))
	
	if id and title then 
		local it=things.set(srv,id,function(srv,e) -- create or update
			e.cache.title=title -- update title
			return true
		end)
	end
	
end

-- add our hook to the waka stuffs, this should get called on module load
-- so that we always watch the waka edits, the trailing slash is to make sure that
-- we only catch todo sub pages and not the todo root
waka.add_changed_hook("^/todo/",waka_changed)



--[[
-----------------------------------------------------------------------------
--
-- hook into note posts?
--
-----------------------------------------------------------------------------
function note_posted(srv,page,parent)

	if not page then return end
	if tostring(page.key.id):sub(1,6)~="/todo/" then return end
	
	log("NOTE: "..tostring(page.key.id))
	
	local chunks=wet_waka.text_to_chunks( page.cache.text )
	
	log("NOTE: "..tostring(chunks.body.text))
end

-- add our hook to the waka stuffs, this should get called on module load
-- so that we always watch the waka edits, the trailing slash is to make sure that
-- we only catch task pages and bellow
note.add_posted_hook("^/todo/",note_posted)
]]


