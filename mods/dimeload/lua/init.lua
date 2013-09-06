-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local wet_html=require("wetgenes.html")
local replace=wet_html.replace

local sys=require("wetgenes.www.any.sys")

local json=require("wetgenes.json")
local dat=require("wetgenes.www.any.data")

local users=require("wetgenes.www.any.users")
local iplog=require("wetgenes.www.any.iplog")

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
local dl_paypal=require("dimeload.paypal")

local ngx=ngx

module("dimeload")

local function make_get_put(srv)
	local get=function(a,b)
		b=b or {}
		b.srv=srv
		return wet_html.get(html,a,b)
	end
	return  get , function(a,b) srv.put(get(a,b)) end
end

local function make_posts(srv)
	local url=srv.url_base
	if url:sub(-1)=="/" then url=url:sub(1,-2) end -- trim any trailing /

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
	
	return posts
end

-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-----------------------------------------------------------------------------
function serv(srv)

	local cmd=srv.url_slash[ srv.url_slash_idx+0 ]	
	if cmd and string.sub(cmd,1,2)=="0x" then -- special hexkey
		return serv_hexkey(srv)
	end

-- check flavours
	local cmds={
		api=		serv_api,
		paypal=		serv_paypal,
	}
	local f=cmds[ string.lower(cmd or "") ]
	if f then return f(srv) end
	
-- check for a project with this name
	local lc=string.lower(cmd or "")
	local p=dl_projects.get(srv,lc)
	if p then return serv_project(srv,p) end

	if cmd then -- failed to find anything so just goto base
		return srv.redirect(srv.url_base:sub(1,-2))
	end
	
	return serv_main(srv)
end

-----------------------------------------------------------------------------
--
-- display the main dimeload page, IE a list of projects
--
-----------------------------------------------------------------------------
function serv_main(srv)

	local url_local="/dl"

local sess,user=d_sess.get_viewer_session(srv)
local get,put=make_get_put(srv)
	
	local url=srv.url_base
	if url:sub(-1)=="/" then url=url:sub(1,-2) end -- trim any trailing /
	
	local posts=make_posts(srv)	
	local refined=wakapages.load(srv,"/dl")[0]


	srv.set_mimetype("text/html; charset=UTF-8")
	put("header",refined)
	put("dimeload_bar",refined)
	
	put(macro_replace(refined.plate or "{body}",refined))

	comments.build(srv,{title=refined.title,url=url_local,posts=posts,get=get,put=put,sess=sess,user=user})

	put("footer",refined)

end


-----------------------------------------------------------------------------
--
-- handle API ( returns json results )
--
-----------------------------------------------------------------------------
function serv_api(srv)
local sess,user=d_sess.get_viewer_session(srv)
local get,put=make_get_put(srv)
	
	if srv.method=="POST" and srv.body and srv:check_referer(url) then
		local d=json.decode(srv.body)
		if d then
			put(wstr.dump(d))
		end
	end
	
	return srv.exit(400)
end

-----------------------------------------------------------------------------
--
-- handle magic hexkeys
--
-----------------------------------------------------------------------------
function serv_hexkey(srv)
local sess,user=d_sess.get_viewer_session(srv)
local get,put=make_get_put(srv)
	
	return srv.exit(400)
end

-----------------------------------------------------------------------------
--
-- handle paypal stuff
--
-----------------------------------------------------------------------------
function serv_paypal(srv)
local sess,user=d_sess.get_viewer_session(srv)
local get,put=make_get_put(srv)
	
	local cmd=srv.url_slash[ srv.url_slash_idx+1 ]	

	if cmd=="ipn" then --paypal is talking to us, telling us about a payment
		local p = dl_paypal.ipn( srv )
		if p then -- we can now register this payment as an actual transaction
			log("PAYPAL : "..p.cache.id.." : "..p.cache.msg) -- log another log, to the logs...
			put("OK")
			
-- only automate completed transactions (ignore refunded or anything else)
-- any refunded action must be adjusted manually...
-- The reason is that this may be flakey,
-- so the main reason to refund is a failure for the credit to turn up here

			if p.cache.currency=="USD" and p.cache.status=="Completed" then

				local dimes=math.floor(p.cache.gross/0.1) -- how many dimes
				local userid=p.cache.custom
				
				dl_users.deposit(srv,{
					dimes=dimes,
					userid=userid,
					flavour="paypal",
					source=p.cache.payer,
				})
				
			end
			
			return
		end
	end

	local posts=make_posts(srv)	

	if not user then	-- require a login to view this paypal page (it is private user data)
		return srv.redirect("/dumid?continue="..srv.url)
	end
	

	local url=srv.url_base
	if url:sub(-1)=="/" then url=url:sub(1,-2) end -- trim any trailing /
	
	local refined=wakapages.load(srv,"/dl/paypal")[0]
	refined.page="dl/paypal"
	
	refined.button10 =dl_paypal.button(srv,{custom=user.cache.id,quantity=10})
	refined.button100=dl_paypal.button(srv,{custom=user.cache.id,quantity=100})
	refined.button200=dl_paypal.button(srv,{custom=user.cache.id,quantity=200})
	
	refined.paylist=dl_paypal.paylist(srv,{custom=user.cache.id})

	srv.set_mimetype("text/html; charset=UTF-8")
	put("header",refined)
	put("dimeload_bar",refined)
	put(macro_replace(refined.plate or "{body}",refined))
	put("footer",refined)
	
end

-----------------------------------------------------------------------------
--
-- display a project, or a subpage of the project
--
-----------------------------------------------------------------------------
function serv_project(srv,project)

	if not project then return end

	local page
	local pname=project.cache.id
	local url_local="/dl/"..pname

	local code=srv.url_slash[ srv.url_slash_idx+1 ]
	if code then -- check for code, if code is valid then we are rendering a custom download page
--log(code)	

-- check if the page exists	
		page=dl_pages.get(srv,pname.."/"..code)


		if not page then -- make this an expensive page

			iplog.ratelimit(srv.ip,50)	-- limit the guesswork

			srv.redirect(srv.url_base..pname)

		else

			url_local="/dl/"..pname.."/"..code
		
		end
	end
	

local sess,user=d_sess.get_viewer_session(srv)
local get,put=make_get_put(srv)

local dluser if user then dluser=dl_users.manifest(srv,user.cache.id) end
	
	local url=srv.url_base
	if url:sub(-1)=="/" then url=url:sub(1,-2) end -- trim any trailing /

	local posts=make_posts(srv)		
	local refined=wakapages.load(srv,"/dl/"..pname)[0]
	refined.pagename="dl/"..pname
-- override some parts of the page with things that we know
	refined.user=user and user.cache
	refined.dl_user=dluser and dluser.cache
	refined.dl_project=project.cache
	refined.dl_page=page and page.cache

	refined.json={}
	refined.json.error="null"
	refined.json.user=(refined.user and json.encode(refined.user)) or "null"
	refined.json.dl_user=(refined.dl_user and json.encode(refined.dl_user)) or "null"
	refined.json.dl_project=json.encode(refined.dl_project) or "null"
	refined.json.dl_page=( refined.dl_page and json.encode(refined.dl_page) ) or "null"
	
	local h={}
	for n,v in pairs(refined) do
		if type(n)=="string" and string.sub(n,1,5)=="html_" then
			h[ string.sub(n,6,-1) ] = macro_replace("{"..n.."}",refined)	-- expand the macros
		end
	end
	refined.json.html=json.encode(h)

	if srv.gets.downloads and user and user.cache and user.cache.admin then
	
		local opts={}
		opts.limit=100
		opts.offset=0
		local r=dl_downloads.list(srv,opts)

		srv.set_mimetype("text/html; charset=UTF-8")
		put("header",refined)
		put("dimeload_bar",refined)


		put("There have been {count} downloads<br/><br/>",{count=#r})

		if r then
			for i,v in ipairs(r) do
				local c=v.cache
		put([[
			{created} : {project}/{page}/{file} == {user} : {ip} <br/>
		]],c)

			end 
		end


		put("footer",refined)

		return

	end
	if srv.gets.users and user and user.cache and user.cache.admin then
	
		local opts={}
		opts.limit=100
		opts.offset=0
		local r=d_users.list(srv,opts)

		srv.set_mimetype("text/html; charset=UTF-8")
		put("header",refined)
		put("dimeload_bar",refined)


		put("There are {count} users<br/><br/>",{count=#r})

		if r then
			for i,v in ipairs(r) do
				local c=v.cache
		put([[
			{created} : {id} {email} {name} : {ip} <br/>
		]],c)

	
			end 
		end


		put("footer",refined)

		return

	end


	if srv.gets.sponsor and user and user.cache and user.cache.admin then

	
		if posts.dimes then posts.dimes=tonumber(posts.dimes) end

--log(wstr.dump(posts))
	
		local send={}
		send.project=pname
		send.about=posts.about or (page and page.cache.about) or ""
		send.dimes=posts.dimes or (page and page.cache.dimes) or 1
		send.code=posts.code or code or srv.gets.sponsor
		
		if posts.code then -- lets update stuff

			dl_pages.set(srv,pname.."/"..send.code,function(srv,e)
				local c=e.cache
				
				c.project=send.project
				c.name=send.code
				c.owner=user.cache.id
				c.dimes=send.dimes
				
				c.about=send.about
				
				return true								
			end)

		end


		if not page and type(srv.gets.sponsor)=="string" and #srv.gets.sponsor>=1 then
			page=dl_pages.get(srv,pname.."/"..send.code)
			refined.dl_page=page and page.cache
		end

	
		srv.set_mimetype("text/html; charset=UTF-8")
		put("header",refined)
		put("dimeload_bar",refined)

		put("sponsor",send)
		
		put("footer",refined)
		return
	end

	if srv.gets.download then

		local fname
		for i,f in ipairs( (refined.lua and refined.lua.files) or {} ) do
			for j,v in ipairs( f.versions or {} ) do
				if v==srv.gets.download then
					fname=v
				end
			end
		end
		if fname then
			if not user then

				refined.json.error=[["you must be logged in to download"]]
				
			elseif page and page.cache.available>0 then

-- check for a recent log entry and allow a rety of the download

-- add 1 to the download count
				dl_pages.update(srv,pname.."/"..code,function(srv,e)
					local c=e.cache
					c.downloads=c.downloads+1
					return true								
				end)

-- create log entry
				local d=dl_downloads.create(srv)
				local c=d.cache
				c.user=user.cache.id
				c.ip=user.cache.ip
				c.project=pname
				c.page=page.cache.name
				c.file=fname
				dl_downloads.put(srv,d)

-- secret internal redirect to download a private file
				return ngx.exec("/@private/dimeload/"..pname.."/"..fname)
			else
				refined.json.error=[["no dimes available to download with"]]
			end
		end
		
	end

	srv.set_mimetype("text/html; charset=UTF-8")
	put("header",refined)
	put("dimeload_bar",refined)
	
	put(macro_replace(refined.plate or "{body}",refined))

	comments.build(srv,{title=title,url=url_local,posts=posts,get=get,put=put,sess=sess,user=user})

	put("footer",refined)

end

--
-- Import some dimeload info, direct into the waka system for use on anypage
--
function chunk_import(srv,tab)

	if tab.command=="projects" then -- list info about all projects
		local opts={}
		opts.limit=tab.limit
		opts.offset=tab.offset
		local r=dl_projects.list(srv,opts)
		if r then
			for i,v in ipairs(r) do tab[i]=v.cache end -- copy values only
		end
	end
	
	return tab
end

