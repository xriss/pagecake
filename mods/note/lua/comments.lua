-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local wet_html=require("wetgenes.html")
local url_esc=wet_html.url_esc

local sys=require("wetgenes.www.any.sys")

local json=require("wetgenes.json")
local dat=require("wetgenes.www.any.data")
local cache=require("wetgenes.www.any.cache")
local stash=require("wetgenes.www.any.stash")

local users=require("wetgenes.www.any.users")

local fetch=require("wetgenes.www.any.fetch")
local mail=require("wetgenes.www.any.mail")

local img=require("wetgenes.www.any.img")


local wet_waka=require("wetgenes.waka")
local wet_html=require("wetgenes.html")

local d_users=require("dumid.users")
local d_nags=require("dumid.nags")
local goo=require("port.goo")

local wstr=require("wetgenes.string")
local log=require("wetgenes.www.any.log").log -- grab the func from the package

local str_split=wstr.str_split
local replace  =wstr.replace
local serialize=wstr.serialize


local ngx=ngx

-- opts



module("note.comments")
local _M=require(...)
local wetdata=require("data")


default_props=
{
	uid="",    -- a unique id string
		
	author="", -- the userid of who wrote this comment (can be used to lookup user)
	url="",    -- the site url for which this is a comment on, site comments relative to root begin with "/"
	group="0",   -- the id of our parent or 0 if this is a master comment on a url
	view="public", -- this comment is "public" or maybe not
	type="ok", -- a type string to filter on
				-- ok    - this is a valid comment, display it
				-- spam  - this is pure spam, hidden but not forgotten
				-- anon  -- anonymous, should not show up in user searches

	count=0,       -- number of replies to this comment (could be good to sort by)
--	pagecount=0,   -- number of pagecomments to this comment (this comment is treated as its own page)

-- track some simple vote numbers, to be enabled later?

	good=0, -- number of good content "votes"
	spam=0, -- number of spam "votes"
	
	media=0, -- an associated data.media id link, 0 if no media,
				-- so each post can have eg an image associated with it ala 4chan

}

if not ngx then -- appengine backhax
	default_props.group=0
end

default_cache=
{
	text="", -- this string is the main text of this comment
	cache={}, -- some cached info of other comments/users etc, 
}


function kind(srv)
	return "note.comments" -- this note module is site wide, which means so is the comment table
end

--------------------------------------------------------------------------------
--
-- check that entity has initial data and set any missing defaults
-- the second return value is false if this is not a valid entity
--
--------------------------------------------------------------------------------
function check(srv,ent)

	local ok=true

	local c=ent.cache
--DBG(c)
	if not ngx then -- appengine backhax, for now
		c.group=tonumber(c.group)
	end
			
	return ent
end


-- build some useful values for display
function fix_comment_item(srv,c)

	c.title=c.title or c.url
	c.created=c.created or 0

	c.grouphash=wstr.alpha_munge(c.group or "")
	c.idhash=wstr.alpha_munge(c.id or "")
	c.link=(c.url or "/").."#wetnote"..c.idhash

	c.time=os.date("%Y-%m-%d %H:%M:%S",c.created)
	c.age=wstr.rough_english_duration(os.time()-c.created)
	
	c.user_id=c.cache and c.cache.user and c.cache.user.id
	c.user_name=c.cache and c.cache.user and c.cache.user.name

	c.viewer_id=srv.user and srv.user.cache and srv.user.cache.id
	c.viewer_name=srv.user and srv.user.cache and srv.user.cache.name
	c.viewer_avatar=srv.user and srv.user.cache and d_users.get_avatar_url(srv,srv.user.cache)
	
	if not c.viewer_name then -- flag that we have no logged in viewer
		c.viewer_none_flag=""
	end
	
	c.action_style=""
	c.form_style="display:none;"
	c.post_text="{cake.note.reply_text}"

	c.html=wet_waka.waka_to_html(c.text or "",{base_url="/",escape_html=true,no_slash_links=true})

	if c.media~=0 then -- include a media embed
		c.media_div="{cake.note.item_media}"
	end

	if c.type=="anon" then -- anonymiser
		c.user_name="anon"
		c.user_id=0
		c.avatar="/art/note/anon.jpg"
	end

	c.cache=nil
	
	return c
end

--------------------------------------------------------------------------------
--
-- manifest a meta comment cache for the given url, one will be built if we must
--
--------------------------------------------------------------------------------
function manifest_meta(srv,url)
	local r=stash.get(srv,"note.comments.meta&"..url)
log( "manifest cache for "..(url or "").." : "..srv.time )
log(wstr.dump(r))
	if r and r.build_time and r.build_time+(60*60*24*1) < srv.time then r=nil end -- check build age is less than one day
	if not r then
		r=update_meta_cache(srv,url)
	end
	return r
end

--------------------------------------------------------------------------------
--
-- update and return the meta cache
--
--------------------------------------------------------------------------------
function update_meta_cache(srv,url)

log( "building new comments cache for "..(url or "") )

	local count=0

-- build meta cache			
	local cs=list(srv,{sort_created="DESC",url=url,group="0",type="ok",limit=10}) -- get last 10 comments only
	local comments={}
	local post_time=0
	for i,v in ipairs(cs) do -- and build comment cache
		local c=v.cache
		if c.created>post_time then post_time=c.created end
		comments[i]=c
		count=count+1+v.cache.count
		c.replies=update_reply_cache(srv,url,c.id) -- make sure replies are correct
	end
	if post_time==0 then post_time=srv.time end
	local meta={comments=comments,count=count,build_time=srv.time,post_time=posttime}
	stash.put(srv,"note.comments.meta&"..url,meta)

	return meta
end

--------------------------------------------------------------------------------
--
-- get/manifest - update - put
--
-- this uses a UID which is a unique soft ID string
--
-- f must be a function that changes the entity and returns true on success
--
-- this function is used to insert without replication of forign UIDs
-- and is used by the API when slurping a forum
--
--------------------------------------------------------------------------------
function manifest_uid(srv,uid,f)


	local q={
		kind=kind(srv),
		limit=1,
		offset=0,
		{"filter","uid","==",uid}
	}
	local r=dat.query(q)
--log(tostring(r))
	local e=r and r.list and r.list[1]
	if e then
		dat.build_cache(e)
		return update(srv,e,f)
	end

-- we now update or create and save, there is a possible update hole here so use this function carefully

	local e=create(srv)
	if f(srv,e) then
		put(srv,e)
		return e
	end

	return nil
end


--------------------------------------------------------------------------------
--
-- list comments
--
--------------------------------------------------------------------------------
function list(srv,opts,t)
	opts=opts or {} -- stop opts from being nil
	
	t=t or dat -- use transaction?
	
	if opts.group then opts.group=tostring(opts.group) end
	
	local q={
		kind=kind(srv),
		limit=opts.limit or 100,
		offset=opts.offset or 0,
	}	
	dat.build_q_filters(opts,q,{"author","url","view","group","type","updated","created"})
	local r=t.query(q)

	for i=1,#r.list do local v=r.list[i]
		dat.build_cache(v)
	end

	return r.list
end


--------------------------------------------------------------------------------
--
-- update any replies
--
--------------------------------------------------------------------------------
function update_reply_cache(srv,url,id)

local updated=nil

	local rs=list(srv,{sort_created="DESC",type="ok",url=url,group=id,limit=3}) -- get last 3 replies

	local replies={}

	for i=#rs,1,-1 do -- reverse order
		local c=rs[i].cache
		replies[#replies+1]=c
		if not updated or c.updated > updated then updated=c.updated end
	end
	
-- the reply cache may lose one if multiple people reply at the same time
-- an older cache may get saved, unlikley but possible and it will auto
-- fix itself on the next reply or stash clear

	update(srv,id,function(srv,e)
		e.cache.updated=updated -- adjust the updated stamp?
		e.cache.replies=replies -- save new reply cache
		e.cache.count=#replies -- a number to sort by
		e.cache.reply_updated=srv.time
		return true
	end)

--log("updated replies ",id," : ",#replies)	
	return replies
end
				


--------------------------------------------------------------------------------
--
-- post data to this comment url if we have valid post info
-- if post worked or if there was no post attempt then return nothing
-- otherwise return some error html to display to the user
--
-- pass in get,set,posts,user,sess using the tab table
-- also set tab.url to the url
--
--------------------------------------------------------------------------------
function post(srv,refined)

	local tab={
		title=refined.cake.note.title,
		url=refined.cake.note.url,
		sess=srv.sess,
		user=srv.user,
		posts=srv.posts,
		}
	
	if not tab.url then
		if refined.cake.note.meta and refined.cake.note.meta.comments and refined.cake.note.meta.comments[1] then
			tab.url=refined.cake.note.meta.comments[1].url
		end
	end
	
	if refined.cake.note.opts_view then -- set to private?
		tab.view=refined.cake.note.opts_view
	end

	if refined.cake.note.opts_admin then -- only this user can update
		tab.admin=refined.cake.note.opts_admin
		tab.lock="admin"
		if refined.cake.note.opts_saveas then -- and also update users status?
			tab.saveas="status"
		end
	end
	
	local user=(tab.user and tab.user.cache)
	
	if tab.posts then
	
		if user and tab.posts.wetnote_comment_submit then -- add this comment
		
			local posted
			
			if tab.lock and tab.admin~=user.id then
				local id=wstr.trim(tab.posts.wetnote_comment_id)
				if id=="0" then -- main posts blocked, but can still reply
					return([[
					<div class="wetnote_error">
					Sorry but your cannot post here.
					</div>
					]])
				end
			end
		
			if #tab.posts.wetnote_comment_text > 4096 then
				return([[
				<div class="wetnote_error">
				Sorry but your comment was too long (>4096 chars) to be accepted.
				</div>
				]])
			end

			if #tab.posts.wetnote_comment_text <1 then
				return([[
				<div class="wetnote_error">
				Sorry but your comment was empty.
				</div>
				]])
			end

			local image
			if tab.posts.filedata and tab.posts.filedata.size>0 then
			
				if tab.posts.filedata.size>=1000000 then
					return([[
					<div class="wetnote_error">
					Sorry but your upload must not be bigger than 1000000 bytes in size.
					</div>
					]])
				end
				
				image=img.get(tab.posts.filedata.data) -- convert to image
				
				if not image then
					return([[
					<div class="wetnote_error">
					Sorry but your upload must be a valid image.
					</div>
					]])
				else
					if image.width>1024 or image.height>1024 then -- resize, keep aspect
						image=img.resize(image,1024,1024,"JPEG") -- resize image
						tab.posts.filedata.data=image.data
						tab.posts.filedata.size=image.size
						tab.posts.filedata.name=tab.posts.filedata.name..".jpg" -- make sure its a jpg
					end
				end
			end
			
			local id=wstr.trim(tab.posts.wetnote_comment_id)
			local e=create(srv)
			local c=e.cache
			
			local title=tab.title-- the title of the page we are commenting upon,can be null
			if title then
				if #title>32 then -- left most 32 chars
					title=title:sub(1,29).."..."
				end
			else
				title=tab.url
				if title then
					if #title>32 then -- right most 32 chars
						title="..."..title:sub(-29)
					end
				end
			end
			if title then -- url escape it
				if #title < 3 then title="this" end
				title=wet_html.esc(title)
			end
			c.cache.user=tab.user.cache
			c.avatar=d_users.get_avatar_url(srv,tab.user.cache or "") -- this can be expensive so we cache it
			c.author=tab.user.cache.id
			c.url=tab.url
			c.group=id
			c.text=tab.posts.wetnote_comment_text
			c.title=title

			c.view=tab.view or "public"

			if tab.posts.filedata and tab.posts.filedata.size>0 then -- got a file
				local dat={}
				dat.id=0
				
				dat.data=tab.posts.filedata and tab.posts.filedata.data
				dat.size=tab.posts.filedata and tab.posts.filedata.size
				dat.name=tab.posts.filedata and tab.posts.filedata.name
				dat.owner=user.id
				wetdata.upload(srv,dat)

				c.media=dat.id -- remember id
			end
			
			if tab.image=="force" then -- require image to start thread 
				if (not c.media) or (c.media==0) then
					return([[
					<div class="wetnote_error">
					Sorry but you must include a valid image.
					</div>
					]])
				end
			end
			
			if tab.anon and tab.posts.anon then -- may be flagged as anonymous
				if wstr.trim(tab.posts.anon)=="anon" then -- it is
					c.type="anon"
				end
			end
			
			e.key.id=e.cache.author.."*"..string.format("%1.3f",e.props.created) -- special forced "unique" id
			
			put(srv,e)
			posted=e
			tab.modified=true -- flag that caller should update cache

log("note post "..(e.key.id).." group "..type(e.props.group).." : "..e.props.group)

			if id~="0" then -- this is a comment so apply to master
			
				update_reply_cache(srv,tab.url,id)
		
			else -- this is a master comment
			
				if tab.saveas=="status" then -- we want to save this as a user posted status
					d_users.update(srv,tab.user,function(srv,ent)
							ent.cache.comment_status=c.text
							return true
						end)
				end

			end

			tab.meta=update_meta_cache(srv,tab.url)

			if posted and posted.cache then -- redirect to our new post
			
				cache.del(srv,"kind="..kind(H).."&find=recent&limit="..(50)) -- reset normal recent cache

				local wetnoteid=id
				if tostring(id)=="0" then wetnoteid=posted.cache.id end

				local long_url=srv.url_domain..tab.url.."#wetnote"..wstr.alpha_munge(wetnoteid)

-- finally add a nag to pester us to twat it
				local nag={}
				
				nag.id="note"
				nag.url=long_url
				nag.short_url=long_url
				
				local xlen=(140-2)-20 -- this is one more than we really want
				local s=c.text
				s=string.gsub(s,"%s+"," ") -- replace any range of whitespace with a single space
				s=wstr.trim(s)
				s=s:sub(1,xlen) -- reduce to less chars, we may chop a word
				s=wstr.trim(s) -- remove spaces
				if #s==xlen then -- we need to lose the last word, this makes sure we do not split a word
					s=s:gsub("([^%s]*)$","")
					s=wstr.trim(s)
				end
				
				nag.c140_base=s -- some base text without the url
				nag.c140=s.." : "..long_url -- add a link on the end to the real content
				
				d_nags.save(srv,srv.sess,nag)

-- and send an email to admins if enabled?
				if srv.opts("mail_from") and srv.opts("mail_admin") then
					mail.send{from=srv.opts("mail_from"),to=srv.opts("mail_admin"),subject="New comment by "..posted.cache.cache.user.name.." on "..srv.url_domain..tab.url,body=long_url.."\n\n"..c.text}
--log(posted.cache.cache.user.name)
				end
				
				return srv.redirect(srv.url) -- unpost
			end

		end
		
	end
end





--------------------------------------------------------------------------------
--
-- post data to this comment url if we have any
-- display comment form at top so you can comment on this post
-- display comments + replies if we have any
-- with reply links so you can reply to these previous comment threads
--
-- pass in get,set,posts,user,sess using the tab table
-- also set tab.url to the url
--
--------------------------------------------------------------------------------
function build(srv,refined,opts)
	local opts=opts or {}

	local meta

	if opts.offset or opts.limit then -- build live paged views
	
		if refined.cake.note.group then -- a single thread

			local cn=get(srv,refined.cake.note.group)
			local cs=list(srv,{sort_created="ASC",group=refined.cake.note.group,type="ok"})
			if cn then
				refined.cake.note.url=cn.cache.url -- get url from comment
				meta={comments={cn.cache}}
				local replies={}
				for i,v in ipairs(cs) do -- replies
					replies[i]=v.cache
				end
				meta.comments[1].replies=replies
			else
				meta={}
			end
			
			
		else -- all posts on a page
			
			local cs=list(srv,{sort_created="DESC",url=refined.cake.note.url,group="0",type="ok",limit=opts.limit or 10,offset=opts.offset or 0})
			local comments={}
			for i,v in ipairs(cs) do -- and build comment cache
				comments[i]=v.cache
			end
			meta={comments=comments}
			
		end

	else -- standard first page

		meta=manifest_meta(srv,refined.cake.note.url)

	end
	
	refined.cake.note.meta=meta

	local err=post(srv,refined)
	if err then
		refined.cake.notes=err
		return
	end


	refined.cake.note.tick_items=refined.cake.note.tick_items or recent_refined(srv,get_recent(srv,opts.ticks or 50))


	local it={}
	it.id="0"
	it.url=refined.cake.note.url
	fix_comment_item(srv,it)
	it.action_style="display:none;"
	it.form_style=""
	it.post_text="{cake.note.post_text}"
	
refined.cake.note.post={plate="{-cake.note.item_form}{-cake.note.item_login}",it}

if refined.cake.note.opts_admin then
	if not srv.user then
		refined.cake.note.post=""
	elseif refined.cake.note.opts_admin~=srv.user.cache.id then
		refined.cake.note.post=""
	end
end

if meta.comments[1] then

	for i,v in ipairs(meta.comments) do
		fix_comment_item(srv,v)
		if v.replies then
			for i,c in ipairs(v.replies) do
				fix_comment_item(srv,c)
				c.style=""
				c.showhide=""
			end
			if v.replies[1] then
				v.replies.plate="{cake.note.item_reply}"
			else
				v.replies.plate=""
			end
		end
	end
	refined.cake.note.comments=meta.comments
	refined.cake.note.comments.plate="{cake.note.item_thread}"
else
	refined.cake.note.comments=""
end

refined.cake.notes=[[
{cake.note.main}
]]

end

--------------------------------------------------------------------------------
--
-- get num recent comments, cached so this is very fuzzy
--
--------------------------------------------------------------------------------
function get_recent(srv,num)

	-- a unique keyname for this query
	local cachekey="kind="..kind(H).."&find=recent&limit="..num
	
	local r=cache.get(srv,cachekey) -- do we already know the answer?

	if r then -- we cached the answer
		return r
	end

	local recent=list(srv,{limit=num,type="ok",view="public",sort_created="DESC"})

	cache.put(srv,cachekey,recent,2*60) -- save this in cache for 2 minutes
	
	return recent
end

--------------------------------------------------------------------------------
--
-- recent to refined chunk
--
--------------------------------------------------------------------------------
function recent_refined(srv,tab)

	local t={}

	for i,v in ipairs(tab) do
		local c=v.cache
		fix_comment_item(srv,c)
		t[#t+1]=c
	end
	
	t.plate="{cake.note.tick}"
	
	if not t[1] then return "" end -- empty chunk

	return t
end


dat.set_defs(_M) -- create basic data handling funcs

dat.setup_db(_M) -- make sure DB exists and is ready


