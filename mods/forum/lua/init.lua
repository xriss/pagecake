-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local wet_html=require("wetgenes.html")
local replace=wet_html.replace

local sys=require("wetgenes.www.any.sys")

local json=require("wetgenes.json")
local dat=require("wetgenes.www.any.data")

local users=require("wetgenes.www.any.users")

local fetch=require("wetgenes.www.any.fetch")

local img=require("wetgenes.www.any.img")

local log=require("wetgenes.www.any.log").log -- grab the func from the package

local wet_string=require("wetgenes.string")
local wstr=wet_string
local trim=wet_string.trim
local str_split=wet_string.str_split
local serialize=wet_string.serialize

local wet_waka=require("wetgenes.waka")
local d_sess =require("dumid.sess")

-- require all the module sub parts
local html=require("forum.html")
local comments=require("note.comments")

local wakapages=require("waka.pages")



-- opts
local opts_mods_chan=(opts and opts.mods and opts.mods.chan) or {}

module("forum")

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
local forums=srv.opts.forums

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
	
	local forum_name=srv.url_slash[srv.url_slash_idx+0]
	
	local refined_base=wakapages.load(srv,"/forum")[0]
	
	if refined_base and refined_base.lua and refined_base.lua.forums then
		forums=refined_base.lua.forums
	end
	for i,v in ipairs(forums) do forums[v.id]=v end
	
	if forum_name  and forums[forum_name] then
		baseurl=baseurl.."/"..forum_name
	
		local num=math.floor( tonumber( srv.url_slash[srv.url_slash_idx+1] or 0 ) or 0 )
		
		if num~=0 and tostring(num)==srv.url_slash[srv.url_slash_idx+1] then --got us an id
		
			local ent=comments.get(srv,num)
			
			
			if ent then -- got a comment page? only if its url matches our base
			
				if ent.cache.url == baseurl then -- sanity check of id
				
					srv.set_mimetype("text/html; charset=UTF-8")
					put("header",{title="forum ",H={user=user,sess=sess}})


					local tab={url=baseurl.."/"..num,posts=posts,get=get,put=put,sess=sess,user=user,post_text="Reply"}
					
					
					put( comments.build_get_comment(srv,tab,ent.cache) )
					
					put( [[<div><a href="{url}">return to ]]..forum_name..[[</a></div>]],{url=baseurl} )
					
					comments.build(srv,tab)
					
					if tab.modified then -- sub comment so need to rebuild our special forum cache stuff
					
						rebuild_cache(srv,baseurl,num,tab.meta) -- can use the cached meta
						comments.update_meta_cache(srv,baseurl)
						
					end

					
					put("footer")
		
					return
				end
			end
			
		end

		srv.set_mimetype("text/html; charset=UTF-8")
		put("header",{title="forum ",css=[[
		.wetnote_comment_text{
			max-height: 80px;
			overflow-y: auto;
			width: 480px;
        }
        .wetnote_reply_div{
			margin-bottom:20px;
        }
/*
        .wetnote_reply_div a span{
			bottom:0px;
        }
        .wetnote_reply_div a {
			display:block;
			position:absolute;
			left:110px;
			top:20px;
			width:100%;
			height:80px;
			background-image: -webkit-linear-gradient(top, rgba(255,255,255,0.5), rgba(255,255,255,1) );
			background-image: -moz-linear-gradient(top, rgba(255,255,255,0.5), rgba(255,255,255,1) );
			background-image: -ms-linear-gradient(top, rgba(255,255,255,0.5), rgba(255,255,255,1) );
			background-image: -o-linear-gradient(top, rgba(255,255,255,0.5), rgba(255,255,255,1) );
        }
*/
        ]]})

--[[
]]

		if forums[forum_name] then
		
			comments.build(srv,{url=baseurl,posts=posts,get=get,put=put,sess=sess,user=user,headonly=true,post_text="Start Thread"})
			
		end
		
		put("footer")
		return
	end
	
-- list all available forums

	srv.set_mimetype("text/html; charset=UTF-8")
	put("header",{title="forum ",H={user=user,sess=sess}})

	for i,v in ipairs(forums) do
		put([[<a href="/forum/{name}">{name}</a><br/>]],{name=v.id})
	end
	
	put("footer")
	
end



function rebuild_cache(srv,baseurl,num,meta)

-- build pagecomments meta cache			

	local cs=comments.list(srv,{limit=5,sortdate="DESC",url=baseurl.."/"..num})
	local pagecomments={}
	local newtime=0
	for i,v in ipairs(cs) do -- and build comment cache
		if v.cache.created>newtime then newtime=v.cache.created end
		pagecomments[i]=v.cache
	end

	local hash={}
	local names={}
	
	local do_comment=function(v)
		local c=v.cache -- a cache within a cache...
		if c.user and c.user.name then
			if not hash[c.user.name] then
				hash[c.user.name]=true
				names[#names+1]=c.user.name
			end
		end
	end

	for i,v in ipairs(meta.comments) do
		do_comment(v)
		for i,v in ipairs(v.replies) do
			do_comment(v)
		end
	end
	
	local pagesynopsis=""
	
	pagesynopsis=table.concat(names," , ")

--log(pagesynopsis)

	comments.update(srv,num,function(srv,e)
	
		if(newtime>0) then
			e.cache.updated=newtime -- most recent comment
		else
			e.cache.updated=e.cache.created -- no update
		end
		
		e.cache.pagesynopsis=pagesynopsis -- save new comment cache
		e.cache.pagecomments=pagecomments -- save new comment cache
		e.cache.pagecount=meta.count or #pagecomments -- tab.ret.count -- a number to sort by?
		
		return true
	end)
	
end

