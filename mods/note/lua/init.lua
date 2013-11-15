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


module("note")

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
-- the serv function, where the action happens.
--
-----------------------------------------------------------------------------
function serv(srv)

	local cmd=srv.url_slash[srv.url_slash_idx+0]
	if cmd=="import" then
		return serv_import(srv)
	elseif cmd=="api" then
		return serv_api(srv)
	end

--local sess,user=d_sess.get_viewer_session(srv)
--local posts=make_posts(srv)

	local refined=waka.fill_refined(srv,"note")

	refined.body="{comments}"	
	refined.comments=comments.recent_refined(srv, comments.get_recent(srv,50))

	srv.set_mimetype("text/html; charset=UTF-8")
	srv.put(wstr.macro_replace("{cake.html.plate}",refined))

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
		srv.put("header",{title="import notes ",user=user,sess=sess,bar=""})
		srv.put("footer",{about="",report="",bar="",})
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
			c.name=head.name
if ngx then
			c.group="0"
else
			c.group=0
end
--c.url="/forum/spam"
			return true
		end)

-- and these are applied to that master

		local idlookup={}
		local replyids={}
		
		for i=2,#thread do local v=thread[i]
		
			local group="0"
			if v.parent then group=idlookup[v.parent] or "0" end
			
			replyids[group]=true
if not ngx then
	if group=="0" then group=0 end
end			
			local com=comments.manifest_uid(srv , v.uid , function(srv,e)
				local c=e.cache
				c.created=v.created
				c.updated=v.updated
				c.url=head.url.."/"..master.key.id
				c.uid=v.uid
				c.text=v.text
				c.author=v.author
				c.name=v.name
				c.group=group
				c.reply_updated=srv.time -- fake this flag as we force rebuild later
--c.url="/forum/spam/"..master.key.id
				return true
			end)
			
			idlookup[com.cache.uid]=com.key.id
		end
		
-- we should come back and fix these cache values later, these should be minimal

		for id,b in pairs(replyids) do -- fix any reply caches
			if id>0 then
print( head.url.."/"..master.key.id .." "..id )
				comments.update_reply_cache(srv, head.url.."/"..master.key.id , id)
			end
		end

--[[
		
		comments.update_meta_cache(srv,head.url.."/"..master.key.id)
		
		forum.rebuild_cache( srv , head.url,master.key.id , #thread-1 )
		
		comments.update_meta_cache(srv,head.url)
]]	
	
	end

	srv.set_mimetype("text/html; charset=UTF-8")
--	put("Testing 123")

end
