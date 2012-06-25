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

local log=require("wetgenes.www.any.log").log -- grab the func from the package

local wet_waka=require("wetgenes.waka")
local wet_html=require("wetgenes.html")

local d_users=require("dumid.users")
local d_nags=require("dumid.nags")
local goo=require("port.goo")


local wstr=require("wetgenes.string")
local str_split=wstr.str_split
local replace  =wstr.replace
local serialize=wstr.serialize

local ngx=ngx

-- opts
local opts_mods_note=(opts and opts.mods and opts.mods.note) or {}
local opts_mail_from=(opts and opts.mail and opts.mail.from)

module("note.comments")
local _M=require(...)
local wetdata=require("data")


default_props=
{
	uid="",    -- a unique id string
		
	author="", -- the userid of who wrote this comment (can be used to lookup user)
	url="",    -- the site url for which this is a comment on, site comments relative to root begin with "/"
	group="0",   -- the id of our parent or 0 if this is a master comment on a url, -1 if it is a meta cache
	type="ok", -- a type string to filter on
				-- ok    - this is a valid comment, display it
				-- spam  - this is pure spam, hidden but not forgotten
				-- meta  - use on fake comments that only contain cached info of other comments
				-- anon  -- anonymous, should not show up in user searches

	count=0,       -- number of replies to this comment (could be good to sort by)
	pagecount=0,   -- number of pagecomments to this comment (this comment is treated as its own page)

-- track some simple vote numbers, to be enabled later?

	good=0, -- number of good content "votes"
	spam=0, -- number of spam "votes"
	
	media=0, -- an associated data.meta id link, 0 if no media,
				-- so each post can have eg an image associated with it ala 4chan
}

if not ngx then
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
-- Create a new local entity filled with initial data
--
--------------------------------------------------------------------------------
--[[
function create(srv)

	local ent={}
	
	ent.key={kind=kind(srv)} -- we will not know the key id until after we save
	ent.props={}
	
	local p=ent.props
	
	p.created=srv.time
	p.updated=srv.time
	
	p.uid=""    -- a unique id string
		
	p.author="" -- the userid of who wrote this comment (can be used to lookup user)
	p.url=""    -- the site url for which this is a comment on, site comments relative to root begin with "/"
	p.group=0   -- the id of our parent or 0 if this is a master comment on a url, -1 if it is a meta cache
	p.type="ok" -- a type string to filter on
				-- ok    - this is a valid comment, display it
				-- spam  - this is pure spam, hidden but not forgotten
				-- meta  - use on fake comments that only contain cached info of other comments
				-- anon  -- anonymous, should not show up in user searches

	p.count=0       -- number of replies to this comment (could be good to sort by)
	p.pagecount=0   -- number of pagecomments to this comment (this comment is treated as its own page)

-- track some simple vote numbers, to be enabled later?

	p.good=0 -- number of good content "votes"
	p.spam=0 -- number of spam "votes"
	
	p.media=0 -- an associated data.meta id link, 0 if no media,
				-- so each post can have eg an image associated with it ala 4chan
	
	dat.build_cache(ent) -- this just copies the props across
	
-- these are json only vars
	local c=ent.cache
	
	c.text="" -- this string is the main text of this comment
	c.cache={} -- some cached info of other comments/users etc, 

	return check(srv,ent)
end
]]

--------------------------------------------------------------------------------
--
-- check that entity has initial data and set any missing defaults
-- the second return value is false if this is not a valid entity
--
--------------------------------------------------------------------------------
function check(srv,ent)

	local ok=true

	local c=ent.cache

	if not ngx then -- appengine backhax, for now
		c.group=tonumber(c.group)
	end
			
	return ent
end


--------------------------------------------------------------------------------
--
-- manifest a meta comment cache for the given url, one will be built if we must
--
--------------------------------------------------------------------------------
function manifest_meta(srv,url)
	local r,e=stash.get(srv,"note.comments.meta&"..url)
	if e and e.cache.updated+(60*60*24*1) < srv.time then r=nil end -- check age is less than one day
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

	local count=0

-- build meta cache			
	local cs=list(srv,{sort_updated="DESC",url=url,group="0"}) -- get all top comments
	local comments={}
	local newtime=0
	for i,v in ipairs(cs) do -- and build comment cache
	
		if v.cache.created>newtime then newtime=v.cache.created end
		
		comments[i]=v.cache
		count=count+1+v.cache.count
	end
	if newtime==0 then newtime=srv.time end
	local meta={comments=comments,count=count,updated=newtime}
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
	
	local q={
		kind=kind(srv),
		limit=opts.limit or 100,
		offset=opts.offset or 0,
	}
-- add filters?
	for i,v in ipairs{"author","url","group","type"} do
		if opts[v] then
			vv=opts[v]
if not ngx then
			if v=="group" then vv=tonumber(vv) end -- hax to work with old and new commwnt ids?
else
			if v=="group" then vv=tostring(vv) end -- hax to work with old and new commwnt ids?
end
			local t=type(vv)
			if t=="string" or t=="number" then
				q[#q+1]={"filter",v,"==",vv}
			elseif t=="table" then
				q[#q+1]={"filter",v,"in",vv}
			end
		end
	end

-- sort by?
-- legacy, do not use, will be removed soon
	if opts.sortdate then
		q[#q+1]={"sort","updated", opts.sortdate }
	end
	if opts.csortdate then
		q[#q+1]={"sort","created", opts.csortdate }
	end
	
-- use these ones :)	
	if opts.sort_updated then
		q[#q+1]={"sort","updated", opts.sort_updated }
	end
	if opts.sort_created then
		q[#q+1]={"sort","created", opts.sort_created }
	end

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

if not ngx then
	id=tonumber(id)
end

	local rs=list(srv,{sort_updated="ASC",url=url,group=id}) -- get all replies
	local replies={}
	for i,v in ipairs(rs) do -- and build reply cache
		replies[i]=v.cache
	end
	
-- the reply cache may lose one if multiple people reply at the same time
-- an older cache may get saved, very unlikley but possible

	set(srv,id,function(srv,e)
		e.cache.updated=nil -- do not change the updated stamp...
		e.cache.replies=replies -- save new reply cache
		e.cache.count=#replies -- a number to sort by
		e.cache.reply_updated=srv.time
		return e
	end)
	
	return replies
end
				


-- display comment code
function build_get_comment(srv,tab,c)

--[[
	if tab.ret and tab.ret.count then -- counter hax
		tab.ret.count=tab.ret.count+1
	end
]]	
	local media=""
	if c.media~=0 then
		media=[[<a href="/data/]]..c.media..[["><img src="]]..srv.url_domain..[[/thumbcache/crop/460/345/data/]]..c.media..[[" class="wetnote_comment_img" /></a>]]
	end
	
	local plink,purl=d_users.get_profile_link(c.author)
	local name=(c.cache and c.cache.user and c.cache.user.name) or c.name

	local vars={
	media=media,
	text=wet_waka.waka_to_html(c.text,{base_url=tab.url,escape_html=true}),
	author=c.author,
	name=name,
	plink=plink,
	purl=purl or "http://google.com/search?q="..name,
	time=os.date("%Y-%m-%d %H:%M:%S",c.created),
	id=wstr.alpha_munge(c.id),
	icon=srv.url_domain..( c.cache.avatar or d_users.get_avatar_url(c.author,nil,nil,srv) ),
	}
	
	if c.type=="anon" then -- anonymiser
		vars.name="anon"
		vars.author=0
		vars.purl=srv.url_domain.."/art/note/anon.jpg"
		vars.icon=srv.url_domain.."/art/note/anon.jpg"
	end
	
	vars.title=tab.get([[posted by {name} on {time}]],vars)
	vars.div_reply=tab.div_reply or ""
	return tab.get([[
<div class="wetnote_comment_div" id="wetnote{id}" >
<div class="wetnote_comment_icon" ><a href="{purl}"><img src="{icon}" width="100" height="100" /></a></div>
<div class="wetnote_comment_head" > posted by <a href="{purl}">{name}</a> on {time} </div>
<div class="wetnote_comment_text" >{media}{text}</div>
<div class="wetnote_comment_tail" ></div>
{div_reply}
</div>
]],vars),vars
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
function post(srv,tab)

	local user=(tab.user and tab.user.cache)
	
	if tab.posts then
	
		if user and tab.posts.wetnote_comment_submit then -- add this comment
		
			local posted
		
			if #tab.posts.wetnote_comment_text > 4096 then
				return([[
				<div class="wetnote_error">
				Sorry but your comment was too long (>4096 chars) to be accepted.
				</div>
				]])
			end

			if #tab.posts.wetnote_comment_text <3 then
				return([[
				<div class="wetnote_error">
				Sorry but your comment was too short (<3 chars) to be accepted.
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
			c.avatar=d_users.get_avatar_url(tab.user.cache or "") -- this can be expensive so we cache it
			c.author=tab.user.cache.id
			c.url=tab.url
			c.group=id
if not ngx then
	if tostring(tonumber(id) or 0) == tostring(id) then
		c.group=tonumber(id)
	end
end
			c.text=tab.posts.wetnote_comment_text
			c.title=title
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
			
			if tab.anon and tab.posts.anon then -- may be anonymous
				if wstr.trim(tab.posts.anon)=="anon" then -- it is
					c.type="anon"
				end
			end
			
			if ngx then -- appengine backhax
				e.key.id=e.cache.author.."*"..string.format("%1.3f",e.props.created) -- special forced "unique" id
			end
			put(srv,e)
			posted=e
			tab.modified=true -- flag that caller should update cache
log("note post "..(e.key.id).." group "..type(e.props.group).." : "..e.props.group)			
			if tostring(id)~="0" then -- this is a comment so apply to master
			
				update_reply_cache(srv,tab.url,id)
--[[
				local rs=list(srv,{sortdate="ASC",url=tab.url,group=id}) -- get all replies
				local replies={}
				for i,v in ipairs(rs) do -- and build reply cache
					replies[i]=v.cache
				end
				
-- the reply cache may lose one if multiple people reply at the same time
-- an older cache may get saved, very unlikley but possible

				update(srv,id,function(srv,e)
					e.cache.replies=replies -- save new reply cache
					e.cache.count=#replies -- a number to sort by
					return true
				end)
]]				
			else -- this is a master comment
			
				if tab.save_post=="status" then -- we want to save this as user posted status
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
--				sys.redirect(srv,tab.url.."?wetnote="..wetnoteid.."#wetnote"..wetnoteid)

				
-- try and get a short url from goo.gl and save it into the comment for later use

				local long_url=srv.url_domain..tab.url.."#wetnote"..wetnoteid
				local short_url=goo.shorten(long_url)
				
				update(srv,posted,function(srv,ent)
						ent.cache.short_url=short_url
						return true
					end)

-- finally add a nag to pester us to twat it
				local nag={}
				
				nag.id="note"
				nag.url=long_url
				nag.short_url=short_url
				
				local xlen=(140-2)-#short_url -- this is one more than we really want
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
				nag.c140=s.." : "..short_url -- add a link on the end to the real content
				
				d_nags.save(srv,srv.sess,nag)

-- and send an email to admins if enabled?
				if opts_mail_from then
					mail.send{from=opts_mail_from,to="admin",subject="New comment by "..posted.cache.cache.user.name.." on "..long_url,text=long_url.."\n\n"..c.text}
log(posted.cache.cache.user.name)
				end
				
				return
			end

		end
		
	end
end



--------------------------------------------------------------------------------
--
-- get a html reply form
--
-- pass in get,set,posts,user,sess using the tab table
-- also set tab.url to the url
--
--------------------------------------------------------------------------------
function get_reply_form(srv,tab,id)

	id=tostring(id or "0")

	local user=(tab.user and tab.user.cache)

	if tab.linkonly then
		return tab.get([[
<div class="wetnote_comment_form_div">
<a href="{url}" ">Reply</a>
</div>]],{
		url=srv.url_domain..tab.url,
		id=wstr.alpha_munge(id),
	})
	end
	
	if not user then -- must login to reply
		return tab.get([[
<div class="wetnote_comment_form_div">
<a href="#" onclick="$(this).hide(400);$('#wetnote_comment_form_{id}').show(400);return false;" style="{actioncss}">Reply</a>
<div id="wetnote_comment_form_{id}" style="{formcss}"> <a href="{url}">You must login to comment.<br/> Click here to login with twitter/gmail/etc...</a>
</div>
</div>]],{
		url="/dumid/login/?continue="..url_esc(tab.url),
		actioncss=(id=="0") and "display:none" or "display:block",
		formcss=(id=="0") and "display:block" or "display:none",
		id=wstr.alpha_munge(id),
	})
	end
	
	local upload=""
	local anon=""
	
	if tab.image or user and user.admin then
		local com=" Please choose an image! "
		if tab.image=="force" then com=" You must choose an image! " end
		upload=[[<div class="wetnote_comment_form_image_div" ><span>]]..com..[[</span><input  class="wetnote_comment_form_image" type="file" name="filedata" /></div>]]
	end
	if tab.anon then
		local checked=""
		if tab.anon=="default" then checked="checked" end -- selected by default
		anon=[[<div class="wetnote_comment_form_anon_dic" ><input  class="wetnote_comment_form_anon_check" type="checkbox" name="anon" value="anon" ]]..checked..[[/><span>Post anonymously?</span></div>]]
	end
	
	local post_text="Express your important opinion"
	
	local reply_text="Reply"
	
	if id=="0" then
		if tab.post_text then post_text=tab.post_text end
	else
		if tab.reply_text then reply_text=tab.reply_text end
	end
	
	local plink,purl=d_users.get_profile_link(user.id or "")

	return tab.get([[
<div class="wetnote_comment_form_div">
<a href="#" onclick="$(this).hide(400);$('#wetnote_comment_form_{id}').show(400);return false;" style="{actioncss}">Reply</a>
<form class="wetnote_comment_form" name="wetnote_comment_form" id="wetnote_comment_form_{id}" action="" method="post" enctype="multipart/form-data" style="{formcss}">
<div class="wetnote_comment_icon" ><a href="{purl}"><img src="{icon}" width="100" height="100" /></a></div>
<div class="wetnote_comment_form_div_cont">
{upload}
{anon}
<textarea class="wetnote_comment_form_text" name="wetnote_comment_text"></textarea>
<input name="wetnote_comment_id" type="hidden" value="{realid}"></input>
<input class="wetnote_comment_post" name="wetnote_comment_submit" type="submit" value="{post_text}"></input>
</div>
</form>
</div>
]],{
	actioncss=(id=="0") and "display:none" or "display:block",
	formcss=(id=="0") and "display:block" or "display:none",
	author=user.id or "",
	name=user.name or "",
	plink=plink,
	purl=purl or "http://google.com/search?q="..(user.name or ""),
	time=os.date("%Y-%m-%d %H:%M:%S"),
	id=wstr.alpha_munge(id),
	realid=id,
	icon=srv.url_domain .. ( d_users.get_avatar_url(user or "") ),
	upload=upload,
	anon=anon,
	post_text=post_text,
	})

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
function build(srv,tab)
local function dput(s) put("<div>"..tostring(s).."</div>") end

	local ret={}
	tab.ret=ret
	ret.count=0
	
	local user=(tab.user and tab.user.cache)
	
	if tab.posts then
		local err=post(srv,tab)
		
		if err then
			tab.put(err)
			return
		end
	end

	
-- reply page link
	local function get_reply_page(num)
		return tab.get([[
<div class="wetnote_comment_form_div">
<a href="{url}">Reply</a>
</div>]],{
			url=srv.url_domain..tab.url.."/"..num
		})
	end
		
-- the meta will contain the cache of everything, we may already have it due to previous updates	
	if not tab.meta then
		tab.meta=manifest_meta(srv,tab.url)
	end

	tab.put([[<div class="wetnote_main">]])
	tab.put([[<div class="wetnote_main2">]])
	
	tab.put([[<div class="wetnote_comments">]])
	
	local show_post=true
	if tab.post_lock=="admin" then
		show_post=false
		if tab.admin then -- who has admin
			if user and user.id==tab.admin then
				show_post=true
			end
		end
	end
	
	if show_post then
if not tab.replyonly then
		tab.put([[<div class="wetnote_comment_form_head"></div>]])
		tab.put(get_reply_form(srv,tab,0))
		tab.put([[<div class="wetnote_comment_form_tail"></div>]])
end
	end
	
	
-- get all top level comments
--	local cs=list(srv,{sort_updated="DESC",url=tab.url,group=0})
	local cs=tab.meta.comments or {}
	
	if tab.headonly then -- just display the forum heads
	
		for i,c in ipairs(cs) do

			local url=srv.url_domain..tab.url.."/"..c.id
			local action="Read and Reply."
			if c.pagecount==1 then			
				action="Read 1 comment and Reply."
			elseif c.pagecount > 1 then
				action="Read "..c.pagecount.." comments and Reply."
			end
			local synopsis=c.pagesynopsis or ""

			tab.put(build_get_comment(srv,tab,c)) -- main comment
			tab.put([[
<div class="wetnote_reply_div">
<div class="wetnote_synopsis_div">]]..synopsis..[[</div>
<a href="]]..url..[["><span>]]..action..[[</span></a>
</div>
]]			
,c)

		end


	elseif tab.toponly then -- just display a top comment field
	
		for i,c in ipairs(cs) do
--			if i>=1 then break end -- 5 only?
			tab.put(build_get_comment(srv,tab,c)) -- main comment
			tab.put([[
<div class="wetnote_reply_div">
]])

--log(" pagecount of " .. tostring(c.pagecount) )

			if c.pagecount > 1 then
					tab.put([[
<div><a href="{url}">View {pagecount} comments.</a></div>
]],{
	pagecount=c.pagecount,
	url=srv.url_domain..tab.url.."/"..c.id,
	})
			end

			local rs=c.pagecomments or {} -- list(srv,{sort_updated="ASC",url=tab.url,group=c.id}) -- replies

			for i=1,1,-1  do -- put last 5? 1? cached comments on page if we have them
				local c=rs[i]
				if c then
					tab.put(build_get_comment(srv,tab,c))
				end
			end
			
			tab.put(get_reply_page(c.id))

			tab.put([[
</div>
]])
		end
	
	else
		
		for i,c in ipairs(cs) do
	
			local dothis=false
			
			if tab.replyonly then -- just display replys to this comment
			
				if c.id == tab.replyonly then dothis=true end
				
			else
				tab.put(build_get_comment(srv,tab,c)) -- main comment
				dothis=true
			end
			
		if dothis then
			tab.put([[
<div class="wetnote_reply_div">
]])

			
			if c.replies and c.reply_updated --[[and c.reply_update<srv.time+(60*60*24*1)]] then
				-- replies probably ok
			else
				if c.id~="0" then -- ok lets bump it
					c.replies=update_reply_cache(srv,c.url,c.id)
				end
			end
			local rs=c.replies or {} -- list(srv,{sort_updated="ASC",url=tab.url,group=c.id}) -- replies
			
			local hide=#rs-5
			if hide<0 then hide=0 end -- nothing to hide
			local hide_state="show"
			
			for i,c in ipairs(rs) do				
	--			local c=v.cache
				if i<=hide then -- hide this one
					if hide_state=="show" then
						hide_state="hide"
						tab.put([[
<div class="wetnote_comment_hide_div">
<a href="#" onclick="if($){$(this).hide(400);$('#wetnote_comment_hide_{id}').show(400);} return false;">Show {hide} hidden comments</a>
<div id="wetnote_comment_hide_{id}" style="display:none">
]],{
		id=wstr.alpha_munge(c.id),
		hide=hide,
		})
					end
				else
					if hide_state=="hide" then
						hide_state="show"
						tab.put([[</div></div>]])
					end
				end
				
				tab.put(build_get_comment(srv,tab,c))
				
			end
		
			tab.put(get_reply_form(srv,tab,c.id))

			tab.put([[
</div>
]])
		end
		end
	end
	
	tab.put([[</div>]])
	
	
	if tab.toponly or tab.linkonly or tab.headonly then
		r={}
	else
		local r=get_recent(srv,50)
		tab.put([[
	<div class="wetnote_ticker">{text}</div>
	]],	{
			text=recent_to_html(srv,r),
		})
	end
	
	
	tab.put([[</div>]])
	tab.put([[</div>]])

	tab.put([[
<script language="javascript" type="text/javascript">
	var doit=function(){
		$(".wetnote_comment_text a").autoembedlink({width:460,height:345});
	};
	head.js(head.fs.jquery_js,head.fs.jquery_wet_js,function(){ $(doit); });
</script>
	]])

	return ret
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

	local recent=list(srv,{limit=num,type="ok",sort_created="DESC"})

-- the lua array + hash for its tables was the problem
-- I have disable the array part lets see if it has a performance impact...

	cache.put(srv,cachekey,recent,2*60) -- save this in cache for 2 minutes
	
	return recent
end



-----------------------------------------------------------------------------
--
-- turn a number of seconds into a rough duration
--
-----------------------------------------------------------------------------
local function rough_english_duration(t)
	t=math.floor(t)
	if t>=2*365*24*60*60 then
		return math.floor(t/(365*24*60*60)).." years"
	elseif t>=2*30*24*60*60 then
		return math.floor(t/(30*24*60*60)).." months" -- approximate months
	elseif t>=2*7*24*60*60 then
		return math.floor(t/(7*24*60*60)).." weeks"
	elseif t>=2*24*60*60 then
		return math.floor(t/(24*60*60)).." days"
	elseif t>=2*60*60 then
		return math.floor(t/(60*60)).." hours"
	elseif t>=2*60 then
		return math.floor(t/(60)).." minutes"
	elseif t>=2 then
		return t.." seconds"
	elseif t==1 then
		return "1 second"
	else
		return "0 seconds"
	end
end

--------------------------------------------------------------------------------
--
-- recent to html
--
--------------------------------------------------------------------------------
function recent_to_html(srv,tab)

	local t={}
	local put=function(str,tab)
		t[#t+1]=replace(str,tab)
	end

	for i,v in ipairs(tab) do
		local c=v.cache
		
		local link=c.url.."#wetnote"
		if tostring(c.group)=="0" then
			link=link..c.id -- link to main comment
		else
			link=link..c.group -- link to what we are commenting on
		end
		if link:sub(1,1)=="/" then link=srv.url_domain..link end -- and make it absolute
		
		local plink,purl=d_users.get_profile_link(c.author)

		local name=(c.cache and c.cache.user and c.cache.user.name) or c.name
		
		put([[
<div class="wetnote_tick">
{time} ago <a href="{purl}">{name}</a> commented on <br/> <a href="{link}">{title}</a>
</div>
]],{
		name=name ,
		time=rough_english_duration(os.time()-c.created),
		title=c.title or c.url,
		link=link,
		purl=srv.url_domain..purl or "http://google.com/search?q="..name,
	})
		
	end

	
	return table.concat(t)
end


dat.set_defs(_M) -- create basic data handling funcs

dat.setup_db(_M) -- make sure DB exists and is ready


