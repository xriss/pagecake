-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require



local wet_html=require("wetgenes.html")

local sys=require("wetgenes.www.any.sys")

local json=require("wetgenes.json")
local dat=require("wetgenes.www.any.data")

local users=require("wetgenes.www.any.users")

local fetch=require("wetgenes.www.any.fetch")
local cache=require("wetgenes.www.any.cache")
local stash=require("wetgenes.www.any.stash")
local iplog=require("wetgenes.www.any.iplog")

local log=require("wetgenes.www.any.log").log -- grab the func from the package

local wstr=require("wetgenes.string")
local str_split=wstr.str_split
local serialize=wstr.serialize

local ae_opts=require("wetgenes.www.any.opts")

local d_sess =require("dumid.sess")

-- require all the module sub parts
local html=require("admin.html")

local waka=require("waka")


local dusers=require("dumid.users")


module("admin")
local function make_put(srv)
	return function(a,b)
		b=b or {}
		b.srv=srv
		srv.put(wet_html.get(html,a,b))
	end
end

-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-- do not cache the srv param localy, make sure it cascades around
--
-----------------------------------------------------------------------------
function serv(srv)
local sess,user=d_sess.get_viewer_session(srv)
local put=make_put(srv)

	if not srv.is_admin(user) then -- adminfail
		return srv.redirect("/dumid?continue="..srv.url)
	end
	
--print(srv.url_slash[ srv.url_slash_idx ])
	
	if srv.url_slash[ srv.url_slash_idx ]=="cmd" then
		local cmd=srv.url_slash[ srv.url_slash_idx+1 ]
		if cmd=="clearcache" then
			srv.set_mimetype("text/html; charset=UTF-8")
			srv.put("MEMCACHE CLEARED")
			cache.clear(srv)
			return
		elseif cmd=="clearstash" then
			srv.set_mimetype("text/html; charset=UTF-8")
			srv.put("STASH CLEARED")
			stash.clear(srv)
			return
		elseif cmd=="iplog" then
			srv.set_mimetype("text/html; charset=UTF-8")
			put(iplog.html_info( srv.url_slash[ srv.url_slash_idx+2 ] or srv.ip),{})
			return
		end
	end
	
	if srv.url_slash[ srv.url_slash_idx ]=="api" then
		return serv_api(srv)
	end

	local ad=srv.url_slash[ srv.url_slash_idx ]
	
	if ad=="users" then
		return serv_users(srv)	
	end

	local url=srv.url_base:sub(1,-2) -- lose the trailing /

	srv.set_mimetype("text/html; charset=UTF-8")
--	put("header",{})
	
	local posts={} -- remove any gunk from the posts input
	-- check if this post probably came from this page before allowing post params
	if srv.method=="POST" and srv:check_referer(url) then
		for i,v in pairs(srv.posts) do
			posts[i]=v
		end
	end	
	
	if posts.text then -- change
		ae_opts.put_dat("lua",posts.text)
		srv.reloadcache() -- force lua reload on next request
	end

	
	local lua=ae_opts.get_dat("lua") or ""
	put("admin_edit",{text=lua,sess=sess.cache})
	
--	put("footer",{})
end


-----------------------------------------------------------------------------
--
-- list users
--
-----------------------------------------------------------------------------
function serv_users(srv)
local sess,user=d_sess.get_viewer_session(srv)


	local refined=waka.fill_refined(srv,"admin")
	html.fill_cake(srv,refined)
	
	refined["cake.html.plate"]="{body}"

	refined["body"]="<table>{users}</table>"
	local l={}
	for i,v in ipairs( dusers.list(srv,{limit=100}) ) do l[#l+1]=v.cache end
	
	l.plate=[[
	<tr>
	<td>{it.name}</td>
	<td><a href="/profile/{it.id}">{it.id}</a></td>
	<td>{it.ip}</td>
	<td>{it.email}</td>
	</tr>
	]]
	refined["users"]=l


	srv.set_mimetype("text/html; charset=UTF-8")
	srv.put(wstr.macro_replace("{cake.html.plate}",refined))

end


-----------------------------------------------------------------------------
--
-- simple json api interface to help get data in and out
--
-----------------------------------------------------------------------------
function serv_api(srv)
local sess,user=d_sess.get_viewer_session(srv)
local put=make_put(srv)

	if not srv.is_admin(user) then -- adminfail
		return srv.redirect("/dumid?continue="..srv.url)
	end
	
	if      srv.vars.cmd=="read" then
	
		local limit=tonumber(srv.vars.limit or 100 )
		local offset=tonumber(srv.vars.offset or 0 )
		local kind=tostring(srv.vars.kind or "waka.pages" )
		
	
		local r=dat.query({
			kind=kind,
			limit=limit,
			offset=offset,
--				{"sort","id","ASC"},
			})
	
		srv.set_mimetype("text/plain; charset=UTF-8")
		put(json.encode({list=r.list,result="OK"}))
		
	elseif srv.vars.cmd=="write" then
	
		local j=json.decode(srv.posts.json)

		
		if j then
			local jj=json.decode(j.props.json)
			local call_hooks_changed
			local d
			if j.key.kind:sub(-#"blog.pages")=="waka.pages" then
			
				d=require("waka.pages")
				call_hooks_changed=require("waka").call_hooks_changed
				
				pcall(function() require("comic") end) -- make sure we have hooks?
				
			elseif j.key.kind:sub(-#"blog.pages")=="blog.pages" then
			
				d=require("blog.pages")

			elseif j.key.kind:sub(-#"note.comments")=="note.comments" then
			
				d=require("note.comments")
				
				call_hooks_changed=function(srv,id,e)
					if tostring(e.props.group=="0") then
						d.update_reply_cache(srv,e.props.url,e.key.id) -- find and fix any replies to us
					else
						d.update_reply_cache(srv,e.props.url,e.props.group) -- find and fix master we are a reply to
					end
					
					require("dumid.users").manifest_userid(srv,e.props.author)
					
					d.update_meta_cache(srv,e.props.url)
				end
				
			end
			if d then
				local f=function(srv,e)
					for i,v in pairs(jj) do -- set
						e.cache[i]=v
					end
					for i,v in pairs(j.props) do -- set
						e.cache[i]=v
					end
					return true
				end
				d.set(srv,j.key.id,f)
				if call_hooks_changed then call_hooks_changed(srv,j.key.id,j) end
				srv.set_mimetype("text/plain; charset=UTF-8")
				put(json.encode({result="OK"}))
				return
			end
		end
	
		srv.set_mimetype("text/plain; charset=UTF-8")
		put(json.encode({result="not implemented"}))
		
	elseif srv.vars.cmd=="delete" then
		srv.set_mimetype("text/plain; charset=UTF-8")
		put(json.encode({result="not implemented"}))
	else
		srv.set_mimetype("text/plain; charset=UTF-8")
		put(json.encode({result="not implemented"}))
	end

end

