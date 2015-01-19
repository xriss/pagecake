-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

-- wetgenes base modules
local json=require("wetgenes.json")
local wstr=require("wetgenes.string")
local whtml=require("wetgenes.html")
local mime=require("mime")

--pagecake base modules
local sys=require("wetgenes.www.any.sys")
local dat=require("wetgenes.www.any.data")
local users=require("wetgenes.www.any.users")
local stash=require("wetgenes.www.any.stash")
local img=require("wetgenes.www.any.img")

--pagecake mods
local d_sess =require("dumid.sess")
local d_users=require("dumid.users")

local note=require("note")
local comments=require("note.comments")

local waka=require("waka")
local wakapages=require("waka.pages")

local data=require("data")

-- debug functions
local dprint=function(...)print(wstr.dump(...))end
local log=require("wetgenes.www.any.log").log


-- sub modules of this mod
local html=require("artcrawl.html")
local pics=require("artcrawl.pics")
local arts=require("artcrawl.arts")




--module
local M={ modname=(...) } ; package.loaded[M.modname]=M


-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-----------------------------------------------------------------------------
function M.serv(srv)

	local cmd=srv.url_slash[ srv.url_slash_idx+0 ]	
	local cmds={
		pic=		M.serv_pic,
		art=		M.serv_art,
		day=		M.serv_day,
		user=		M.serv_user,
		cron=		M.serv_cron,
		admin=		M.serv_admin,
	}
	local f=cmds[ string.lower(cmd or "") ] or cmds.test
	if f then return f(srv) end

-- bad page
	return srv.redirect("/")
end


-----------------------------------------------------------------------------
--
-- all views fill in this stuff
--
-----------------------------------------------------------------------------
function M.get(srv,name)
local sess,user=d_sess.get_viewer_session(srv)

	srv.refined=waka.prepare_refined(srv,name) -- basic root page and setup
	html.fill_cake(srv) -- more local setup

	if srv.is_admin(user) then
		srv.refined.cake.admin="{cake.artcrawl.admin_bar}"
	end
	
	return srv.refined
end

-----------------------------------------------------------------------------
--
-- all views return this html
--
-----------------------------------------------------------------------------
function M.put(srv)
	if srv.refined.opts.flame=="on" then -- add comments to this page
		srv.refined.cake.note.title=srv.refined.it and srv.refined.it.title or "artcrawl"
		srv.refined.cake.note.url=srv.url_local
		comments.build(srv,srv.refined)
	end
	waka.display_refined(srv,srv.refined)	
--	srv.set_mimetype("text/html; charset=UTF-8")
--	srv.put(wstr.macro_replace("{cake.html.plate}",srv.refined))
end

-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-----------------------------------------------------------------------------
function M.serv_admin(srv)
local sess,user=d_sess.get_viewer_session(srv)
	
	local refined

	if not srv.is_admin(user) then
		return srv.redirect("/dumid?continue="..srv.url)
	end

	local posts=srv.posts
	if srv.method=="POST" and not srv:check_referer() then
		return srv.redirect(srv.url) -- bad referer
	end
	
	if posts.cmd=="update pics" then
	
		local its=posts.refresh_checked if type(its)~="table" then its={its} end
		for _,n in ipairs(its) do
print("update:"..n)
			pics.update(srv,n,function(srv,e)
				e.cache.bad=0
				return true
			end)
		end

		local its=posts.bad_checked if type(its)~="table" then its={its} end
		for _,n in ipairs(its) do
print("bad:"..n)
			pics.update(srv,n,function(srv,e)
				e.cache.bad=1
				return true
			end)
		end

		return srv.redirect(srv.url) -- display nothing		

	end

	local cmd=srv.url_slash[ srv.url_slash_idx+1 ]

	if cmd=="recheck" then
		refined=M.get(srv,"artcrawl/admin/recheck")
	
		refined.list={}
		local list=pics.list(srv,{sort="created+",offset=0,limit=-1})
		for i,v in ipairs(list) do local c=v.cache			
			c.date=os.date("%Y-%m-%d",c.created)
			if c.bad>0 then c.bad_checked="checked" end
			refined.list[#refined.list+1]=c
			c.newhashtag=pics.get_hashtag(srv,c)
			if c.newhashtag ~= c.hashtag then -- update
				pics.update(srv,c.id,function(srv,e)
					e.cache.hashtag=c.newhashtag
					return true
				end)
			end
		end
		refined.list_plate=[[
			<tr>
				<td>{it.hashtag}</td>
				<td>{it.newhashtag}</td>
				<td>{it.valid}</td>
				<td>{it.text}</td>
			</tr>
		]]

		refined.list_table=[[
		<table>
			{list:list_plate}
		</table>
		]]
		refined.body="{list_table}"
		M.put(srv)

	elseif cmd=="pics" then
		refined=M.get(srv,"artcrawl/admin/pics")
	
		refined.list_limit=tonumber(srv.gets.limit or 100)
		refined.list_offset=tonumber(srv.gets.offset or 0)
		refined.list_next=refined.list_offset+100
		refined.list_prev=refined.list_offset-100
		if refined.list_offset<0 then refined.list_offset=0 end
		if refined.list_prev<0   then refined.list_prev=0 end

		refined.list={}
		local list=pics.list(srv,{sort="created-",offset=refined.list_offset,limit=refined.list_limit})
		for i,v in ipairs(list) do local c=v.cache			
			c.date=os.date("%Y-%m-%d",c.created)
			if c.bad>0 then c.bad_checked="checked" end
			refined.list[#refined.list+1]=c
		end
		refined.list_plate=[[
			<tr>
				<td><input type="checkbox" name="refresh_checked" value="{it.id}" /></td>
				<td><a href="/artcrawl/day/{it.day}">{it.day}</a></td>
				<td><a href="/artcrawl/pic/{it.id}">{it.id}</a></td>
				<td><a href="/artcrawl/user/{it.userid}">{it.userid}</a></td>
				<td>{it.bad}<input type="checkbox" name="bad_checked" value="{it.id}" {it.bad_checked} /></td>
				<td>{it.hot}</td>
				<td>{it.valid}</td>
				<td>{it.hashtag}</td>
				<td><img src="{it.pic_url}" style="max-height:64px;"/></td>
			</tr>
		]]
		refined.list_table=[[
		<a href="?offset={list_prev}">prev</a> <a href="?offset={list_next}">next</a>
		<form action="" method="POST">
		<input name="cmd" type="submit" value="update pics" />
		<style>
			td {border:3px solid #eee;}
		</style>
		<table>
			<tr>
				<td><input type="checkbox" id="refresh_checked_all" /></td>
				<td>day</td>
				<td>id</td>
				<td>user</td>
				<td>bad</td>
				<td>hot</td>
				<td>flags</td>
				<td>tag</td>
			</tr>
			{list:list_plate}
		</table>
		</form>
		<a href="?offset={list_prev}">prev</a> <a href="?offset={list_next}">next</a>
		<script>

head.js( head.fs.jquery_js, function(){ $(function(){
    $("#refresh_checked_all").toggle(
        function() {
            $("input[name='refresh_checked']").attr("checked","checked");
        },
        function() {
            $("input[name='refresh_checked']").removeAttr('checked');
        }
    );
});});

		</script>
		]]
		refined.body="{list_table}"
		M.put(srv)
	else
		refined=M.get(srv,"artcrawl/admin")

		refined.list={
			{cmd="pics",desc="Edit pics"},
			{cmd="recheck",desc="Recheck cached tweets"},
		}
		refined.list_plate=[[
			<tr>
				<td><a href="/artcrawl/admin/{it.cmd}">{it.cmd}</a></td>
				<td>{it.desc}</td>
			</tr>
		]]
		refined.list_table=[[
		<table>
			<tr>
				<td>link</td>
				<td>description</td>
			</tr>
			{list:list_plate}
		</table>
		]]
		refined.body="{list_table}"
		M.put(srv)
	end
	
	
	
end

-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-----------------------------------------------------------------------------
function M.serv_cron(srv)
local sess,user=d_sess.get_viewer_session(srv)
	
--[[
	if srv.is_admin(user) or srv.is_local() then
	else
		return srv.redirect("/dumid?continue="..srv.url)
	end
]]
	
	local refined=M.get(srv,"artcrawl/cron")
	
	refined.body=pics.twat_search(srv,{})

	M.put(srv)
end


-----------------------------------------------------------------------------
--
-----------------------------------------------------------------------------
function M.serv_user(srv)
local sess,user=d_sess.get_viewer_session(srv)
	
	local userid=srv.url_slash[ srv.url_slash_idx+1 ]

	local refined=M.get(srv,"artcrawl/user")
	
	refined.list_limit=tonumber(srv.gets.limit or 100)
	refined.list_offset=tonumber(srv.gets.offset or 0)
	refined.list_next=refined.list_offset+100
	refined.list_prev=refined.list_offset-100
	if refined.list_offset<0 then refined.list_offset=0 end
	if refined.list_prev<0   then refined.list_prev=0 end

	refined.pics={}
	local list=pics.list(srv,{sort="created-",bad=0,valid={1,3},offset=refined.list_offset,limit=refined.list_limit,hashtag="leeds",userid=userid})
	for i,v in ipairs(list) do local c=v.cache			
		c.date=os.date("%Y-%m-%d",c.created)
		refined.pics[#refined.pics+1]=c
	end
	
	local user=d_users.get(srv,userid) -- get user from userid
	refined.user=user and user.cache
	
	refined.example=[[
		<pre> { user } ={user}</pre>
		<pre> { pics } ={pics}</pre>
]]
	if wstr.trim(refined.body) == "MISSING CONTENT<br/>" then
		refined.body="{example}"
	end
	
-- redirect to root on bad user, must have logged in or posted pics
	if not refined.user and not refined.pics[1] then
		return srv.redirect("/")
	end

	M.put(srv)
end

-----------------------------------------------------------------------------
--
-----------------------------------------------------------------------------
function M.serv_day(srv)
local sess,user=d_sess.get_viewer_session(srv)

	local day=math.floor( tonumber( srv.url_slash[ srv.url_slash_idx+1 ] or 0 ) or 0 )
	if (day==0) or (day~=day) then
		return srv.redirect("/")
	end

	local refined=M.get(srv,"artcrawl/day")

	refined.list_limit=tonumber(srv.gets.limit or 100)
	refined.list_offset=tonumber(srv.gets.offset or 0)
	refined.list_next=refined.list_offset+100
	refined.list_prev=refined.list_offset-100
	if refined.list_offset<0 then refined.list_offset=0 end
	if refined.list_prev<0   then refined.list_prev=0 end

	refined.pics={}
	local list=pics.list(srv,{sort="created-",bad=0,valid={1,3},offset=refined.list_offset,limit=refined.list_limit,hashtag="leeds",day=day})
	for i,v in ipairs(list) do local c=v.cache			
		c.date=os.date("%Y-%m-%d",c.created)
		refined.pics[#refined.pics+1]=c
	end
	
	refined.example=[[
		<pre> { pics } ={pics}</pre>
]]
	if wstr.trim(refined.body) == "MISSING CONTENT<br/>" then
		refined.body="{example}"
	end
	
-- redirect to root on bad day, must have some pics
	if not refined.pics[1] then
		return srv.redirect("/")
	end

	M.put(srv)
end

-----------------------------------------------------------------------------
--
-----------------------------------------------------------------------------
function M.serv_pic(srv)
local sess,user=d_sess.get_viewer_session(srv)
	
	local id=srv.url_slash[ srv.url_slash_idx+1 ]
	
	local pic=pics.get(srv,id)
	if not pic then
		return srv.redirect("/")
	end
	
	local refined=M.get(srv,"artcrawl/pic")
	
	refined.pic=pic.cache

	refined.example=[[
		<pre> { pic } ={pic}</pre>
]]
	if wstr.trim(refined.body) == "MISSING CONTENT<br/>" then
		refined.body="{example}"
	end
	
	M.put(srv)
end

-----------------------------------------------------------------------------
--
-----------------------------------------------------------------------------
function M.serv_art(srv)
local sess,user=d_sess.get_viewer_session(srv)
	
	local refined=M.get(srv,"artcrawl/art")

	M.put(srv)
end

-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-----------------------------------------------------------------------------
function M.serv_test(srv)
local sess,user=d_sess.get_viewer_session(srv)
	
	local refined=M.get(srv,"artcrawl/test")

	if not srv.is_admin(user) then
		return srv.redirect("/dumid?continue="..srv.url)
	end

	refined.title="art test"
	refined.listplate=[[
	<div>
	<img src="{it.pic_url}"/>
	<div><a href="http://twitter.com/{it.screen_name}/status/{it.id}">{it.text}</a></div>
	<div><a href="http://maps.google.com/?q={it.lat},{it.lng}">{it.lat} : {it.lng}</a></div>
	</div>
	]]

	refined.body="{-list:listplate}<pre>{list}</pre>"
	
	local le=pics.list(srv,{hashtag="leeds",bad=0,valid={1,3},sort="twat_time-"})
	local l={}
	for i,v in ipairs(le) do
		local c=v.cache
		c.twat=nil
		l[#l+1]=c
	end
	refined.list=l

	M.put(srv)
end

-----------------------------------------------------------------------------
--
-- get image detail in a list
--
-----------------------------------------------------------------------------
function M.chunk_import(srv,opts)
opts=opts or {}

	local ret={}
	for i,v in pairs(opts) do ret[i]=v end -- copy opts into the return

	if opts.cmd=="list" then

		local list=pics.list(srv,opts)

		for i,v in ipairs(list) do
		
			local c=v.cache
			
			c.date=os.date("%Y-%m-%d",c.twat_time)
			c.time=os.date("%h:%M:%s",c.twat_time)
			
			c.thumb_url=c.pic_url:sub(8) -- skip http://

			if type(opts.hook) == "function" then -- fix up each item?
				opts.hook(v,{class="list"})
			end
			
			ret[#ret+1]=c
		end
	end
	
	return ret		
end


