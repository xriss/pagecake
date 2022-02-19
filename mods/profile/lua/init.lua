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
local html=require("profile.html")

local waka=require("waka")
local note=require("note")
local wakapages=require("waka.pages")
local comments=require("note.comments")

local ipv4=require("admin.ipv4")

local dl_users=require("dimeload.users")

-- opts


-- replacement version of module that does not global
local module=function(modname, ...)
	local ns={ _NAME = modname , _PACKAGE = string.gsub (modname, "[^.]*$", "") }
	ns._M = ns
	package.loaded[modname] = ns
	setfenv (2, ns)
	for _,f in ipairs({...}) do f(ns) end
end
module("profile")

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


-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-----------------------------------------------------------------------------
function serv(srv)
local sess,user=d_sess.get_viewer_session(srv)
local put=make_put(srv)
local get=make_get(srv)
	
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
	
	local name=srv.url_slash[srv.url_slash_idx+0] -- the profile name, could be anything
	if name=="" then name=nil end -- can not be ""
	if name then name=name:lower() end -- force to lower
	
	if name then -- need to check the name is valid


--		local notes=waka.build_notes(srv,"profile/"..name,{save_post="status"})
		local pusr=d_users.get(srv,name) -- get user from userid
		local phtml=get_profile_html(srv,name)
		if pusr and phtml then

			local refined=waka.prepare_refined(srv,"profile")
			refined.cake.note.title="profile of "..pusr.cache.name
			refined.cake.note.url="/profile/"..name
			
			refined.cake.note.opts_admin=name
			refined.cake.note.opts_saveas="status"
			
			comments.build(srv,refined)

--			refined.cake.notes=notes

			if srv.is_admin(user) then
--				refined.cake.admin="{cake.admin_profile_bar}"
			end

			
			refined.cake.profile=phtml
			refined.body="{.cake.profile}"
			refined.title="Profile of "..pusr.cache.name

			waka.display_refined(srv,refined)	
--			srv.set_mimetype("text/html; charset=UTF-8")
--			srv.put(macro_replace("{cake.html.plate}",refined))


--[[
			baseurl=baseurl.."/"..name

-- need the base wiki page, its kind of the main site everything
			local refined=wakapages.load(srv,"/profile")[0]	

			srv.set_mimetype("text/html; charset=UTF-8")
			put("header",{title="profile ",H={user=user,sess=sess}})

			refined.body=phtml
			refined.title=pusr.cache.name.." profile"
			put( macro_replace(refined.plate_profile or refined.plate or "{body}", refined ) )

			comments.build(srv,{
				url=baseurl,
				posts=posts,
				get=get,
				put=put,
				sess=sess,
				user=user,
				post_lock="admin",
				admin=pusr.cache.id,
				save_post="status",
				post_text="change your status",
				title=refined.title,
				})
			
			put("footer")
]]
			return
		else
			srv.redirect("/")
		end	
	end

-- nothing to see here, move along	
--	sys.redirect(srv,"/")
end


-----------------------------------------------------------------------------
--
-- given a userid
-- return some html that represents information about them
-- something that can be shoved into other game profiles and provide
-- links back to their real profile
--
-----------------------------------------------------------------------------
function get_profile_html(srv,name)

local get=make_get(srv)

	if name then -- need to check the name is valid
	
		local pusr=d_users.get(srv,name) -- get user from userid
		if pusr then -- gots a user to display profile of
			
			local content={head={},foot={},wide={},side={}}
			local list={ -- default stuff to display
					{
						form="name",
						show="head",
					},
--					{
--						form="location",
--						show="head",
--					},
				}
			content.list=list
			content.user=pusr.cache
			local t={form="site",show="head"}
			t.userid=pusr.cache.id
			t.url=""
			t.site=""
			t.siteid=0
			
			local endings={"@id.wetgenes.com"}
			for i,v in ipairs(endings) do
				if string.sub(t.userid,-#v)==v then
					t.siteid=(string.sub(t.userid,1,-(#v+1)))
					t.url="http://like.wetgenes.com/-/profile/$"..t.siteid
					t.site="wetgenes"
					list[#list+1]=t
					break
				end
			end

			local endings={"@id.twitter.com"}
			for i,v in ipairs(endings) do
				if string.sub(t.userid,-#v)==v then
					t.siteid=(string.sub(t.userid,1,-(#v+1)))
					t.url="/js/dumid/twatbounce.html?id="..t.siteid
					t.site="twitter"
					list[#list+1]=t
					break
				end
			end
	
			local endings={"@id.facebook.com"}
			for i,v in ipairs(endings) do
				if string.sub(t.userid,-#v)==v then
					t.siteid=(string.sub(t.userid,1,-(#v+1)))
					t.url="http://www.facebook.com/profile.php?id="..t.siteid
					t.site="facebook"
					list[#list+1]=t
					break
				end
			end
	
			local endings={"@id.steamcommunity.com"}
			for i,v in ipairs(endings) do
				if string.sub(t.userid,-#v)==v then
					t.siteid=(string.sub(t.userid,1,-(#v+1)))
					t.url="http://steamcommunity.com/profiles/"..t.siteid
					t.site="steam"
					list[#list+1]=t
					break
				end
			end
			

-- display dimeload chunk on profile?
			local dluser=dl_users.get(srv,pusr.cache.id)
--dluser={cache={id=0,dimes=100,spent=90,avail=10}}
			if dluser then
				local t={form="dimeload",show="head"}
				t.userid=pusr.cache.id
				t.dimes=dluser.cache.dimes
				t.spent=dluser.cache.spent
				t.avail=dluser.cache.avail
				list[#list+1]=t
			end


			for i,v in ipairs(list) do -- get all chunks
				makechunk(content,v)
			end

			return get("profile_layout",content)
			
		end
		
	end

	return nil
end

-----------------------------------------------------------------------------
--
-- build this chunk and put it into the content
--
-----------------------------------------------------------------------------
function makechunk(content,chunk)

	content.chunk=chunk
	local form=chunk.form
	
	local f=_M[ "makechunk_"..form ]
	if f then
		local r=f(content,chunk)
		local t=content[ chunk.show ] or {}
		t[#t+1]=r
		content[ chunk.show ]=t
	end
end


-----------------------------------------------------------------------------
--
-- the name of the person
--
-----------------------------------------------------------------------------
function makechunk_name(content,chunk)
	local user=content.user
--log(tostring(user))
	local d={}
	d.content=content
	d.chunk=chunk
	d.name=user.name
	d.status=user.comment_status or "NO COMMENT"
	
	local plink,purl=d_users.get_profile_link(user.id)
	d.status = replace([[
<div class="wetnote_comment_div" id="wetnote{id}" >
<div class="wetnote_comment_icon" ><a href="{purl}"><img src="{icon}" width="100" height="100" /></a></div>
<div class="wetnote_comment_head" > status of <a href="{purl}">{name}</a> </div>
<div class="wetnote_comment_text" style="font-size:200%">{text}</div>
<div class="wetnote_comment_tail" ></div>
</div>
]],{
	text=wet_waka.waka_to_html(d.status,{base_url="/",escape_html=true}),
	author=user.id,
	name=user.name,
	plink=plink,
	purl=purl,
	icon=user.avatar_url or d_users.get_avatar_url(nil,user),
	})
	
		
	local p=[[
<div class="profile_name">
{status}
</div>
]]
	return replace(p,d)
end


-----------------------------------------------------------------------------
--
-- the location of the person
--
-----------------------------------------------------------------------------
function makechunk_location(content,chunk)
	local user=content.user
	local d={}
	d.location = replace([[
	<div class="profile_flag">
	<img src="/art/base/flags/{co}.png" width="16" height="11" />
	</div>
]],{
	co=ipv4.country(user.ip):lower(),
	})
	
		
	local p=[[
<div class="profile_location">
{location}
</div>
]]
	return replace(p,d)
end

-----------------------------------------------------------------------------
--
-- the name of the person
--
-----------------------------------------------------------------------------
function makechunk_site(content,chunk)
	local user=content.user
--log(tostring(user))
	local d={}
	d.content=content
	d.chunk=chunk
	d.name=user.name
	
	if chunk.site=="wetgenes" then
	
		chunk.site=replace([[<a href="{chunk.url}"><img src="/thumbcache/640/50/like.wetgenes.com/-/badge/{name}/640/50/badge.png" /></a>]],d)
		
	elseif chunk.site=="steam" then
	
		chunk.site=replace([[<a href="{chunk.url}"><img src="http://badges.steamprofile.com/profile/default/steam/{chunk.siteid}.png"><br/>View steam profile</a>]],d)
		
	elseif chunk.site=="facebook" then
	
		chunk.site=replace([[<a href="{chunk.url}">View facebook profile</a>]],d)

	elseif chunk.site=="twitter" then

		chunk.site=replace([[
<a class="twitter-timeline" href="https://twitter.com/{name}" >View tweets by @{name}</a>
]],d)

	else
	
		chunk.site=replace([[<a href="{chunk.url}">{chunk.site}</a>]],d)
	
	end
	
	local p=[[
<div class="profile_site">
{chunk.site}
</div>
]]
	return replace(p,d)
end



-----------------------------------------------------------------------------
--
-- dimeload stats
--
-----------------------------------------------------------------------------
function makechunk_dimeload(content,chunk)
	return replace([[
	<div class="profile_dimeload">
		<div>
			<span>Dimes remaining:</span>{avail}
		</div>
		<div>
			<span>Total dimes purchased:</span>{dimes}
		</div>
	</div>
]],chunk)
end


