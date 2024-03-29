-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local wet_html=require("wetgenes.html")
local replace=wet_html.replace

local sys=require("wetgenes.www.any.sys")

local json=require("wetgenes.json")
local dat=require("wetgenes.www.any.data")

local users=require("wetgenes.www.any.users")

local fetch=require("wetgenes.www.any.fetch")
local stash=require("wetgenes.www.any.stash")

local img=require("wetgenes.www.any.img")

local log=require("wetgenes.www.any.log").log -- grab the func from the package

local ngx=ngx

local wstr=require("wetgenes.string")
local wet_string=require("wetgenes.string")
local trim=wet_string.trim
local str_split=wet_string.str_split
local serialize=wet_string.serialize

local wet_waka=require("wetgenes.waka")

local d_sess =require("dumid.sess")
local d_users=require("dumid.users")
local d_sess=require("dumid.sess")

-- require all the module sub parts
local html=require("note.html")
local comments=require("note.comments")

local waka=require("waka")

-- opts

local dprint=function(...) log(wstr.dump(...)) end

-- replacement version of module that does not global
local module=function(modname, ...)
	local ns={ _NAME = modname , _PACKAGE = string.gsub (modname, "[^.]*$", "") }
	ns._M = ns
	package.loaded[modname] = ns
	setfenv (2, ns)
	for _,f in ipairs({...}) do f(ns) end
end
module("note")
local M=_M

local forum=require("forum")

--[[
local function make_get_put(srv)
	local get=function(a,b)
		b=b or {}
		b.srv=srv
		return wet_html.get(html,a,b)
	end
	return  get , function(a,b) srv.put(get(a,b)) end
end
]]

local function make_url(srv)
	local url=srv.url_base
	if url:sub(-1)=="/" then url=url:sub(1,-2) end -- trim any trailing /
	return url
end

local function make_posts(srv)
	local url=make_url(srv)
	local posts={} -- remove any gunk from the posts input
	-- check if this post probably came from this page before allowing any post params
	if srv.method=="POST" and srv:check_referer(url) then
		for i,v in pairs(srv.posts) do
			posts[i]=v
		end
	end
	if posts.submit then posts.submit=trim(posts.submit) end
	return posts
end

hooks={
	posted={},
}
-----------------------------------------------------------------------------
--
-- handle callbacks
--
-----------------------------------------------------------------------------
function add_posted_hook(pat,func)

	hooks.posted[func]=pat -- use func as the key
	
end


-----------------------------------------------------------------------------
--
-- all views fill in this stuff
--
-----------------------------------------------------------------------------
function M.fill_refined(srv,page,notes,group)
	local sess,user=d_sess.get_viewer_session(srv)

	local refined=waka.prepare_refined(srv,page) -- basic root page and setup
	html.fill_cake(srv,refined) -- more local setup

	if srv.is_admin(user) then
--		refined.cake.admin="{cake.note.admin_bar}"
	end
	
	refined.opts.flame="on"

	refined.opts.limit=math.floor(tonumber(srv.vars.limit or 50) or 50)
--	if refined.opts.limit<1 then refined.opts.limit=1 end
	
	refined.opts.offset=math.floor(tonumber(srv.vars.offset or 0) or 0)
	if refined.opts.offset<0 then refined.opts.offset=0 end
	
	refined.opts.offset_next=refined.opts.offset+refined.opts.limit
	refined.opts.offset_prev=refined.opts.offset-refined.opts.limit
	if refined.opts.offset_prev<0 then refined.opts.offset_prev=0 end
	
	if group then
	
		refined.cake.note.group=group

	else

		refined.cake.note.title=notes
		refined.cake.note.url=notes
		
	end
	

	comments.build(srv,refined,refined.opts) -- simple page system

	refined.cake.note.post="" -- no commenting here, just replying to comments

	return refined
end

-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-----------------------------------------------------------------------------
function M.serv_posts(srv)
	local sess,user=d_sess.get_viewer_session(srv)

	local tt={""}
	for i=srv.url_slash_idx+1,#srv.url_slash do
		tt[#tt+1]=srv.url_slash[i]
	end
	local page=table.concat(tt,"/")

	local refined=M.fill_refined(srv,"note/posts",page,nil)

	refined.cake.note.posts_link=""

	refined.title="{cake.note.posts_title}"
	refined.body="{cake.note.posts_body}"

	return waka.display_refined(srv,refined)	
	
end
-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-----------------------------------------------------------------------------
function M.serv_thread(srv)
	local sess,user=d_sess.get_viewer_session(srv)

	local refined=M.fill_refined(srv,"note/thread",nil,(srv.url_slash[srv.url_slash_idx+1]))
	
	refined.cake.note.thread_link=""

	refined.title="{cake.note.thread_title}"
	refined.body="{cake.note.thread_body}"

	return waka.display_refined(srv,refined)	
	
end
-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-----------------------------------------------------------------------------
function serv(srv)

	local cmd=srv.url_slash[srv.url_slash_idx+0]
	if cmd=="import" then
		return serv_import(srv)
	elseif cmd=="api" then
		return serv_api(srv)
	elseif cmd=="admin" then
		return serv_admin(srv)
	elseif cmd=="posts" then
		return serv_posts(srv)
	elseif cmd=="thread" then
		return serv_thread(srv)
	end

	return serv_admin(srv)

--local sess,user=d_sess.get_viewer_session(srv)
--local posts=make_posts(srv)


--[[
	local refined=waka.prepare_refined(srv,"note")
	refined.body="{comments}"	
	refined.comments=comments.recent_refined(srv, comments.get_recent(srv,50))
	waka.display_refined(srv,refined)	
]]

--	srv.set_mimetype("text/html; charset=UTF-8")
--	srv.put(wstr.macro_replace("{cake.html.plate}",refined))

end


-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-----------------------------------------------------------------------------
function serv_import(srv)

local sess,user=d_sess.get_viewer_session(srv)
--local get,put=make_get_put(srv)
local posts=make_posts(srv)

	local ext
	local aa={}
	for i=srv.url_slash_idx+1,#srv.url_slash do
		aa[#aa+1]=srv.url_slash[i]
	end
	if aa[#aa]=="" then aa[#aa]=nil end-- kill any trailing slash
	if aa[#aa] then
		local ap=str_split(".",aa[#aa])
		if ap[#ap] then
			if ap[#ap]=="js" then -- javascript embed
				ext="js"
			elseif ap[#ap]=="atom" then -- rss feed
				ext="atom"
			elseif ap[#ap]=="frame" then -- special version of this page intended to be embeded in an iframe
				ext="frame"
			end
			if ext then
				ap[#ap]=nil
				aa[#aa]=table.concat(ap,".")
				if aa[#aa]=="" then aa[#aa]=nil end-- kill any trailing slash we may have just created
			end
		end
	end

	local note_url="/"..table.concat(aa,"/") -- this is the url we are talking about


	if ext=="atom" then -- head comments only in feed, comments on comments are ignored
--[=[	
		local function atom_escape(s)

			return string.gsub(s, "([%&%<])",
				function(c)
					if c=="&" then return "&amp;" end
					if c=="<" then return "&lt;" end
					return c
				end)
		end

			local list=comments.list(srv,{csortdate="DESC",url=note_url,group="0"}) -- get all comments
			
			local updated=0
			local author_name=""
			if list[1] then
				updated=list[1].cache.created
				author_name=list[1].cache.cache.user.name
			end
			
			updated=os.date("%Y-%m-%dT%H:%M:%SZ",updated)
			srv.set_mimetype("application/atom+xml; charset=UTF-8")
			put("note_atom_head",{title="notes",updated=updated,author_name=author_name})
			for i,v in ipairs(list) do
				local text,vars=comments.build_get_comment(srv,{url=note_url,get=get},v.cache)
				
				local xlen=(137)+1-- this is one more than we really want
				local s=vars.text:gsub("(%b<>)","") -- kill any tags
				s=string.gsub(s,"%s+"," ") -- replace any range of whitespace with a single space
				s=wet_string.trim(s)
				s=s:sub(1,xlen) -- reduce to less chars, we may chop a word
				s=wet_string.trim(s) -- remove spaces
				if #s==xlen then -- we need to lose the last word, this makes sure we do not split a word
					s=s:gsub("([^%s]*)$","")
					s=wet_string.trim(s)
				end
				s=s.."..."

				vars.script=[[<script type="text/javascript" src="]]..srv.url_domain..[[/note/import]]..note_url..[[/.js?wetnote=]]..v.cache.id..[["></script>]]
				put("note_atom_item",{
					it=v.cache,
					text=atom_escape(vars.media..vars.text..vars.script),
					title=atom_escape(s),
					link=srv.url_domain..note_url.."#wetnote"..wstr.alpha_munge(v.cache.id),
					})
			end
			put("note_atom_foot",{})
]=]
	elseif ext=="js" then
--[=[
		srv.set_mimetype("text/javascript; charset=UTF-8")
		
		local out={}
--		local newput=function(a,b)
--			out[#out+1]=get(a,b)
--		end
		local replyonly
		if srv.gets.wetnote then
			replyonly=(srv.gets.wetnote)
		end
		comments.build(srv,{url=note_url,posts={},get=get,put=newput,sess=sess,user=user,linkonly=true,replyonly=replyonly})
		local s=table.concat(out) -- this is the html string we wish to insert

local function js_encode(str)
    return string.gsub(str, "([\"\'\t\n])", function(c)
        return string.format("\\x%02x", string.byte(c))
    end)
end		
		local surl=srv.url
		local replyonly
		if srv.gets.wetnote then
			replyonly=(srv.gets.wetnote)
		end
		if replyonly then surl=surl.."?wetnote="..replyonly end
		
		put([[
var div = document.createElement('div');
div.id='{url}';
div.innerHTML='{str}';

var scripts = document.getElementsByTagName('script');  
for(var i=0; i<scripts.length; i++)  
{  
    if(scripts[i].src == '{url}')  
    {  
		scripts[i].parentNode.insertBefore(div, scripts[i]);  
        break;  
    }  
}

if (!document.getElementById('{css}'))
{
    var head  = document.getElementsByTagName('head')[0];
    var link  = document.createElement('link');
    link.id   = '{css}';
    link.rel  = 'stylesheet';
    link.type = 'text/css';
    link.href = '{css}';
    link.media = 'all';
    head.appendChild(link);
}

]],
{
	url=surl,
	str=js_encode(s),
	css=srv.url_domain.."/css/note/import.css"
})
]=]
	else
		srv.set_mimetype("text/html; charset=UTF-8")
--		srv.put("header",{title="import notes ",user=user,sess=sess,bar=""})
--		srv.put("footer",{about="",report="",bar="",})
	end
end


-----------------------------------------------------------------------------
--
-- get a html string which is a handful of recent comments,
--
-----------------------------------------------------------------------------
function chunk_import(srv,opts)
opts=opts or {}

--local get,put=make_get_put(srv)

	local t={}
	local css=""
	local list=comments.list(srv,opts)

	local ret={}
	for i,v in pairs(opts) do ret[i]=v end -- copy opts into the return
	
	for i,v in ipairs(list) do
	
		local c=v.cache
		if c.cache.user then
		
			local media=""
			if c.media~=0 then
				media=[[<a href="/data/]]..c.media..[["><img src="]]..srv.url_domain..[[/thumbcache/460/345/data/]]..c.media..[[" class="wetnote_comment_img" /></a>]]
			end	
			local plink,purl=d_users.get_profile_link(c.cache.user.id)
			
			c.media=media -- img tag+link or ""
			
			c.title=""
			c.body=wet_waka.waka_to_html(c.text,{base_url="/",escape_html=true})
			
			c.link=c.url.."?wetnote="..c.id.."#wetnote"..wstr.alpha_munge(c.id)
			
			c.author_name=c.cache.user.name
			c.author_icon=srv.url_domain..( c.cache.avatar or d_users.get_avatar_url(srv,c.cache.user) )		
			c.author_link=purl or "http://google.com/search?q="..c.cache.user.name
			
			c.date=os.date("%Y-%m-%d %H:%M:%S",c.created)
		
		
			if type(opts.hook) == "function" then -- fix up each item?
				opts.hook(v,{class="note"})
			end
			
			ret[#ret+1]=c

		end
	end
	
	return ret

end



-----------------------------------------------------------------------------
--
-- a json admin api for posting and reading
--
-----------------------------------------------------------------------------
function serv_api(srv)

local sess,user=d_sess.get_viewer_session(srv)
--local get,put=make_get_put(srv)
local posts=make_posts(srv)

	if not srv.is_admin(user) then -- adminfail
		return false
	end

--log("note api start")
--log(tostring(posts))

	posts.cmd=trim(posts.cmd)
	posts.json=json.decode(posts.json)
	
--log("note api cmd="..posts.cmd)
	if posts.cmd=="thread" then -- posting an entire forum thread
	
		local thread=posts.json.thread
		
		local head=thread[1]
--log("note api start thread")
--log(tostring(head))

-- head is the master comment

		local master=comments.manifest_uid(srv , head.uid , function(srv,e)
			local c=e.cache
			c.created=head.created
			c.updated=head.updated
			c.url=head.url
			c.uid=head.uid
			c.text=head.text
			c.author=head.author
			c.group="0"
			c.avatar=d_users.get_avatar_url(srv,head.author)
			c.cache.user={id=head.author,name=head.name} -- fake user
			c.id=c.author.."*"..string.format("%1.3f",c.created) -- special forced "unique" id
			e.key.id=c.id
--c.url="/forum/spam"
			return true
		end)

-- and these are applied to that master
		for i=2,#thread do local v=thread[i]
					
			local usr=d_users.manifest_userid(srv,v.author,v.name,"wetgenes") -- make sure user exists
					
			local com=comments.manifest_uid(srv , v.uid , function(srv,e)
				local c=e.cache
				c.created=v.created
				c.updated=v.updated
				c.url=head.url --.."/"..master.key.id
				c.uid=v.uid
				c.text=v.text
				c.author=v.author
				c.group=tostring(master.key.id)
				c.reply_updated=srv.time -- fake this flag as we force rebuild later
				c.avatar=d_users.get_avatar_url(srv,v.author)
				c.cache.user={id=v.author,name=v.name} -- fake user
--c.url="/forum/spam/"..master.key.id
				c.id=c.author.."*"..string.format("%1.3f",c.created) -- special forced "unique" id
				e.key.id=c.id
				return true
			end)
			
		end
		
--		comments.update_reply_cache(srv, head.url, master.key.id)
--		comments.update_meta_cache(srv,head.url)
	
	end

	stash.clear(srv) -- force a rebuild of the meta cache on next view

	srv.set_mimetype("text/html; charset=UTF-8")
--	put("OK")

end


function serv_admin(srv)

	local sess,user=d_sess.get_viewer_session(srv)
	if not srv.is_admin(user) then -- adminfail
		return false
	end
	if srv.method=="POST" and not srv:check_referer() then
		return srv.redirect(srv.url) -- bad referer
	end

	if srv.posts.cmd=="update" then
	
		local change=srv.posts.change if type(change)~="table" then change={change} end
		local spam  =srv.posts.spam   if type(spam)  ~="table" then spam  ={spam}   end
		
		for _,n in ipairs(change) do
--log("change:"..n)
			comments.update(srv,n,function(srv,e)
				e.cache.type="ok"
				return true
			end)
		end

		for _,n in ipairs(spam) do
--log("spam:"..n)
			comments.update(srv,n,function(srv,e)
				e.cache.type="spam"
				return true
			end)
		end

		return srv.redirect(srv.url) -- display nothing		
	end



	local refined=waka.prepare_refined(srv)

	refined.list_limit=tonumber(srv.gets.limit or 100)
	refined.list_offset=tonumber(srv.gets.offset or 0)
	refined.list_next=refined.list_offset+100
	refined.list_prev=refined.list_offset-100
	if refined.list_offset<0 then refined.list_offset=0 end
	if refined.list_prev<0   then refined.list_prev=0 end

	local list=comments.list(srv,{sort_created="DESC",offset=refined.list_offset,limit=refined.list_limit}) -- get all comments
--dprint(list)
	for i=1,#list do
		local c=list[i].cache
		c.time=os.date("%Y/%m/%d %H:%M:%S",c.created)
		c.text=wet_html.esc(c.text)
		list[i]=c
	end
	refined.list=list
	refined.list_head=[[
<tr>
<td>not</td>
<td>spam</td>
<td>url</td>
<td>author</td>
<td>text</td>
</tr>
]]
	refined.list_item=[[
<tr>
<td><input type="checkbox" name="change" value="{it.id}" /></td>
<td><input type="checkbox" name="spam" value="{it.id}" />{it.type}</td>
<td><a href="{it.url}">{it.url}</a></td>
<td>{it.author}</td>
<td>{it.text}</td>
</tr>
]]
	refined.body=[[
		<a href="?offset={list_prev}">prev</a> <a href="?offset={list_next}">next</a>
		<form action="" method="POST">
		<input name="cmd" type="submit" value="update" />
		<a href="/admin/cmd/clearstash">clear stash</a>
		<table class="admin_note">
		{list_head}
		{list:list_item}
		</table>
		</form>
		<style>
		.admin_note td { max-width:200px; overflow:hidden; padding:0px 4px 0px 4px ; white-space:nowrap; }
		</style>
	]]
	
	waka.display_refined(srv,refined)
		
end
