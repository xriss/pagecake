-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local wet_html=require("wetgenes.html")
local replace=wet_html.replace

local markdown=require("markdown")

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
local dl_projects=require("dimeload.projects")
local dl_pages=require("dimeload.pages")
local dl_hexkeys=require("dimeload.hexkeys")

-- logs
local dl_sponsors=require("dimeload.sponsors")
local dl_downloads=require("dimeload.downloads")
local dl_paypal=require("dimeload.paypal")
local dl_transactions=require("dimeload.transactions")

local ngx=ngx

module("dimeload")

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
		return serv_hexkey(srv,string.sub(cmd,3))
	end

-- check flavours
	local cmds={
		api=		serv_api,
		paypal=		serv_paypal,
		admin=		serv_admin,
		user=		serv_user,
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
	
	local url=srv.url_base
	if url:sub(-1)=="/" then url=url:sub(1,-2) end -- trim any trailing /

	local refined=waka.fill_refined(srv,"dl")
	html.fill_cake(srv,refined)
	if user and user.cache and user.cache.admin then
		refined.cake.admin="{cake.admin_dimeload_bar}"
	end
	refined.cake.notes=waka.build_notes(srv,refined.cake.pagename)
	
	srv.set_mimetype("text/html; charset=UTF-8")
	srv.put(macro_replace("{cake.html.plate}",refined))

end


-----------------------------------------------------------------------------
--
-- handle API ( returns json results )
--
-----------------------------------------------------------------------------
function serv_api(srv)
local sess,user=d_sess.get_viewer_session(srv)
	
	if srv.method=="POST" and srv.body and srv:check_referer(url) then
		local d=json.decode(srv.body)
		if d then
			srv.put(wstr.dump(d))
		end
	end
	
	return srv.exit(400)
end

-----------------------------------------------------------------------------
--
-- handle magic hexkeys
--
-----------------------------------------------------------------------------
function serv_hexkey(srv,hex)
local sess,user=d_sess.get_viewer_session(srv)

	-- require a login
	if not (user) then
		return srv.redirect("/dumid?continue="..srv.url)
	end

	local e=dl_hexkeys.get(srv,hex)
	if not e then
		iplog.ratelimit(srv.ip,50)	-- limit the guesswork
		srv.redirect(srv.url_base)
		return
	end
	local c=e.cache
	
	if c.state=="used" then
		srv.redirect(srv.url_base..c.project.."/"..c.page)
		return	
	end


	local refined=waka.fill_refined(srv,"dl/0x")
	html.fill_cake(srv,refined)
	if user and user.cache and user.cache.admin then
		refined.cake.admin="{cake.admin_dimeload_bar}"
	end
	
	local posts=make_posts(srv)	
	refined.cake.dimeload.post_code=""
	refined.cake.dimeload.project=c.project
	refined.cake.dimeload.dimes=c.dimes
	refined.cake.dimeload.errorwrap="{cake.dimeload.error_text}"


	local send={}
	send.project=c.project
	send.code=string.gsub(posts.code or "","([^0-9a-zA-Z_]*)","")
	send.dimes=tonumber(c.dimes)
	send.id=send.project.."/"..send.code
	send.owner=user.cache.id

	local oldpage=dl_pages.get(srv,send.id)

	if srv.posts.sponsor then
	if #send.code<3 then -- error, code is too short

		refined.cake.dimeload.error_text=[[secret name is too short]]
		
	elseif oldpage then

		refined.cake.dimeload.error_text=[[that secret name is already used by someone else]]	
	
	else
	
		dl_hexkeys.set(srv,hex,function(srv,e)
			local c=e.cache
			
			c.state="used"
			c.page=send.code
			c.owner=send.owner
			c.ip=srv.ip
			
			return true								
		end)
	
		local r=dl_pages.set(srv,send.id,function(srv,e)
			local c=e.cache
			
			c.owner=send.owner
			c.project=send.project
			c.name=send.code
			c.dimes=c.dimes + send.dimes
			c.about=""
			
			return true								
		end)
		return srv.redirect(srv.url_base..send.id)

	end
	end
	
	refined.body="{-cake.dimeload.errorwrap}{cake.dimeload.hexkeypage}{cake.dimeload.js}"
	
	srv.set_mimetype("text/html; charset=UTF-8")
	srv.put(macro_replace("{cake.html.plate}",refined))
end

-----------------------------------------------------------------------------
--
-- handle paypal stuff
--
-----------------------------------------------------------------------------
function serv_paypal(srv)
local sess,user=d_sess.get_viewer_session(srv)
	
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
	
	local refined=waka.fill_refined(srv,"dl/paypal")
	html.fill_cake(srv,refined)
	if user and user.cache and user.cache.admin then
		refined.cake.admin="{cake.admin_dimeload_bar}"
	end
--	refined.cake.notes=waka.build_notes(srv,refined.cake.pagename)

--	local refined=wakapages.load(srv,"/dl/paypal")[0]
--	refined.page="dl/paypal"
	
	refined.button10 =dl_paypal.button(srv,{custom=user.cache.id,quantity=10})
	refined.button100=dl_paypal.button(srv,{custom=user.cache.id,quantity=100})
	refined.button200=dl_paypal.button(srv,{custom=user.cache.id,quantity=200})
	
	refined.paylist=dl_paypal.paylist(srv,{custom=user.cache.id})

	srv.set_mimetype("text/html; charset=UTF-8")
	srv.put(macro_replace("{cake.html.plate}",refined))

--[[
	srv.set_mimetype("text/html; charset=UTF-8")
	put("header",refined)
	put("dimeload_bar",refined)
	put(macro_replace(refined.plate or "{body}",refined))
	put("footer",refined)
]]	
end

-----------------------------------------------------------------------------
--
-- handle user info pages
--
-----------------------------------------------------------------------------
function serv_user(srv)
local sess,user=d_sess.get_viewer_session(srv)

	-- require a login
	if not (user) then
		return srv.redirect("/dumid?continue="..srv.url)
	end
	
	local refined=waka.fill_refined(srv,"dl/user")
	html.fill_cake(srv,refined)
	if user and user.cache and user.cache.admin then
		refined.cake.admin="{cake.admin_dimeload_bar}"
	end
--	refined.cake.notes=waka.build_notes(srv,refined.cake.pagename)

	srv.set_mimetype("text/html; charset=UTF-8")
	srv.put(macro_replace("{cake.html.plate}",refined))
	return
end

-----------------------------------------------------------------------------
--
-- handle admin pages
--
-----------------------------------------------------------------------------
function serv_admin(srv)
local sess,user=d_sess.get_viewer_session(srv)

	local cmd=srv.url_slash[ srv.url_slash_idx+1 ]	

	-- require admin login
	if not (user and user.cache and user.cache.admin ) then
		return srv.redirect("/dumid?continue="..srv.url)
	end

	local refined=waka.fill_refined(srv,"dl/admin")
	html.fill_cake(srv,refined)
	if user and user.cache and user.cache.admin then
		refined.cake.admin="{cake.admin_dimeload_bar}"
	end
--	refined.cake.notes=waka.build_notes(srv,refined.cake.pagename)
	refined.result=""

	if cmd=="hexkeys" then
	
--		log(wstr.dump(srv.posts))
		
		if srv.posts.newhex=="newhexpage" then
		
			local note=srv.posts.note or ""
			local proj=srv.posts.project
			local dime=tonumber(srv.posts.dimes or 0) or 0
			if dime~=dime or dime<0 then dime=0 end
			
			local e=dl_projects.get(src,proj)
			
			local id=sys.md5(note..proj..dime..os.time().."hexkeys")

			if dl_hexkeys.get(srv,id) then -- this should never really happen...
			
				refined.result="error keyclash : "..id
			
			elseif not e then
			
				refined.result="unknown project : "..proj
			
			elseif dime<=0 then
			
				refined.result="dimes must be more than 0 : "..dime

			else
				local e=dl_hexkeys.create(srv)
				local c=e.cache
				e.key.id=id
				c.note=note
				c.project=proj
				c.dimes=dime
				c.state="active"
				c.action="page"
				dl_hexkeys.put(srv,e)
			end
		
		end
	
		local opts={}
		opts.limit=100
		opts.offset=0
		local list={}
		local r=dl_hexkeys.list(srv,opts)
		for i,v in ipairs(r) do
			list[i]=v.cache
		end
		list.plate="{list_plate}"
		refined.list_plate=[[
<tr>
<td> {it.created} </td>
<td> | </td>
<td> {it.id} </td>
<td> | </td>
<td> {it.action}/{it.state} </td>
<td> | </td>
<td> {it.project}/{it.page} </td>
<td> | </td>
<td> {it.dimes} </td>
<td> | </td>
<td> {it.owner} </td>
<td> | </td>
<td> {it.ip} </td>
<td> | </td>
<td> {it.note} </td>
</tr>
]]
	
		refined.list=list
		refined.newhex=[[
<div>
<form action="{cake.url}" method="POST" enctype="multipart/form-data">
<table>
<tr>
	<td>PROJECT : </td><td><input name="project" /></td>
</tr>
<tr>
	<td>DIMES : </td><td><input name="dimes" /></td>
</tr>
<tr>
	<td>NOTE : </td><td><input name="note" /></td>
</tr>
<tr>
	<td><input type="submit" value="newhexpage" name="newhex" /></td>
</tr>
</table>
</form>
</div>
		]]
		refined.delhex=[[
		]]
		refined.resultwrap=[[<h2>{.result}</h2>]]
		refined.body="<h1>HEXKEYS</h1>{-resultwrap}{newhex}{delhex}<br/><table>{list}</table>"
		
	elseif cmd=="downloads" then
		local opts={}
		opts.limit=100
		opts.offset=0
		local list={}
		local r=dl_downloads.list(srv,opts)
		for i,v in ipairs(r) do
			list[i]=v.cache
		end
		list.plate="{list_plate}"
		refined.list_plate=[[
<tr>
<td> {it.created} </td>
<td> | </td>
<td> {it.project}/{it.page}/{it.file} </td>
<td> | </td>
<td> {it.user} </td>
<td> | </td>
<td> {it.ip} </td>
</tr>
]]
		refined.list=list
		refined.body="<h1>DOWNLOADS</h1><table>{list}</table>"
		
	elseif cmd=="users" then

		local opts={}
		opts.limit=100
		opts.offset=0
		local list={}
		local r=d_users.list(srv,opts)
		for i,v in ipairs(r) do
			list[i]=v.cache
		end
		list.plate="{list_plate}"
		refined.list_plate=[[
<tr>
<td> {it.created} </td>
<td> | </td>
<td> {it.id} </td>
<td> | </td>
<td> {it.name} </td>
<td> | </td>
<td> {it.ip} </td>
</tr>
]]
		refined.list=list
		refined.body="<h1>USERS</h1><table>{list}</table>"

	elseif cmd=="dimes" then

		local opts={}
		opts.limit=100
		opts.offset=0
		local list={}
		local r=dl_users.list(srv,opts)
		for i,v in ipairs(r) do
			list[i]=v.cache
		end
		list.plate="{list_plate}"
		refined.list_plate=[[
<tr>
<td> {it.created} </td>
<td> | </td>
<td> {it.id} </td>
<td> | </td>
<td> {it.dimes} </td>
<td> - </td>
<td> {it.spent} </td>
<td> = </td>
<td> {it.avail} </td>
<tr>
]]
		refined.list=list
		refined.newdim=[[
]]
		refined.body="<h1>DIMES</h1>{newdim}<table>{list}</table>"

	else
		refined.body=[[
<h1>ADMIN</h1>
<a href="/dl/admin/downloads" >downloads</a><br/>
<a href="/dl/admin/users" >users</a><br/>
<a href="/dl/admin/dimes" >dimes</a><br/>
<a href="/dl/admin/hexkeys" >hexkeys</a><br/>
]]
	
	end
		
	srv.set_mimetype("text/html; charset=UTF-8")
	srv.put(macro_replace("{cake.html.plate}",refined))
	return
end

-----------------------------------------------------------------------------
--
-- sponsor
--
-----------------------------------------------------------------------------
function refined_project_sponsor(srv,refined)

	local posts=make_posts(srv)		

	refined.cake.dimeload.goto="sponsor"
	

	local send={}
	send.code=string.gsub(posts.code or "","([^0-9a-zA-Z_]*)","")
	send.dimes=math.floor( tonumber(posts.dimes or 0) or 0 ) or 0
	if send.dimes~=send.dimes or send.dimes<0 then send.dimes=0 end -- number sanity

	send.owner=refined.cake.user and refined.cake.user.id
	send.project=refined.cake.dimeload.project.id
	send.about=posts.about or ""
	send.id=send.project.."/"..send.code
	
	local oldpage=dl_pages.get(srv,send.id)
	oldpage=oldpage and oldpage.cache
	
	refined.cake.dimeload.post_code=send.code
	refined.cake.dimeload.post_about=wet_html.esc(send.about)

	if not refined.cake.user then

		refined.cake.dimeload.goto="sponsor"
		refined.cake.dimeload.error_text=[[you must login to sponsor]]

	elseif #send.code<3 then -- error, code is too short

		refined.cake.dimeload.goto="sponsor"
		refined.cake.dimeload.error_text=[[secret name is too short]]
	
	elseif #send.about>4096 then

		refined.cake.dimeload.goto="sponsor"
		refined.cake.dimeload.error_text=[[about text is too long]]
	
	elseif (not oldpage) and send.dimes<1 then
	
		refined.cake.dimeload.goto="sponsor"
		refined.cake.dimeload.error_text=[[must use 1 or more dimes to create a page]]

	elseif send.dimes>refined.cake.dimeload.user.avail then
	
		refined.cake.dimeload.goto="buy"
		refined.cake.dimeload.error_text=[[you need to buy more dimes]]

	elseif oldpage and (oldpage.owner~=send.owner) then

		refined.cake.dimeload.goto="sponsor"
		refined.cake.dimeload.error_text=[[that secret code is already used by someone else]]
	
	else
	
-- create sponsors log entry
		local d=dl_sponsors.create(srv)
		local c=d.cache
		c.user=send.owner
		c.ip=srv.ip
		c.project=send.project
		c.page=send.code
		c.dimes=send.dimes
		dl_sponsors.put(srv,d)
				
-- update user dime count
		dl_users.set(srv,send.owner,function(srv,e)
			local c=e.cache
			c.spent=c.spent+send.dimes
			c.avail=c.avail-send.dimes
			return true
		end)


		local r=dl_pages.set(srv,send.id,function(srv,e)
			local c=e.cache
			
			c.owner=send.owner
			c.project=send.project
			c.name=send.code
			c.dimes=c.dimes + send.dimes
			
			c.about=send.about
			
			return true								
		end)
		r=(r and r.cache)
		if r then -- check if we should redirect to new page?
			if (not refined.cake.dimeload.page) or (r.id~=refined.cake.dimeload.page.id) then -- redirect
				return srv.redirect(srv.url_base..send.id)
			else
				refined.cake.dimeload.page=r
				refined.cake.dimeload.post_code=r.name
				refined.cake.dimeload.post_about=wet_html.esc(r.about)
				refined.cake.dimeload.waka_about=wet_waka.waka_to_html(r.about,{escape_html=true})
			end
		end
	end

	srv.set_mimetype("text/html; charset=UTF-8")
	srv.put(macro_replace("{cake.html.plate}",refined))
	return
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

local dluser if user then dluser=dl_users.manifest(srv,user.cache.id) end
	
	local url=srv.url_base
	if url:sub(-1)=="/" then url=url:sub(1,-2) end -- trim any trailing /

	local posts=make_posts(srv)		

	local refined=waka.fill_refined(srv,"dl/"..pname)
	html.fill_cake(srv,refined)
	if user and user.cache and user.cache.admin then
		refined.cake.admin="{cake.admin_dimeload_bar}"
	end
	refined.cake.notes=waka.build_notes(srv,refined.cake.pagename)

--	local refined=wakapages.load(srv,"/dl/"..pname)[0]
--	refined.pagename="dl/"..pname
	
	
-- override some parts of the page with things that we know
	refined.cake.user=user and user.cache
	refined.cake.dimeload.page=page and page.cache
	refined.cake.dimeload.user=dluser and dluser.cache
	refined.cake.dimeload.project=project.cache
	
	refined.cake.dimeload.post_code=""
	refined.cake.dimeload.post_about=""
	refined.cake.dimeload.waka_about=nil
	refined.cake.dimeload.dimecount="{cake.dimeload.mydimes}"
	refined["cake.dimeload.mydimes_available"]=(dluser and dluser.cache.avail) or 0
	if refined.cake.dimeload.page then -- use dimes from page
		refined.cake.dimeload.dimecount="{cake.dimeload.available}"
		refined.cake.dimeload.post_code=refined.cake.dimeload.page.name
		refined.cake.dimeload.post_about=wet_html.esc(refined.cake.dimeload.page.about)
		refined.cake.dimeload.waka_about=wet_waka.waka_to_html(refined.cake.dimeload.page.about,{escape_html=true})
		
		if user and user.cache.id == page.cache.owner then -- owner defaults to sponsor page
			refined.cake.dimeload.goto="sponsor"
		end
	else -- use personal dimes
		refined["cake.dimeload.page.available"]=0
	end
	
	
	refined.cake.dimeload.list={}
	for i,v in ipairs(refined.lua.files) do
		refined.cake.dimeload.list[i]=refined.lua.files[i]
	end
	refined.cake.dimeload.list.plate="{cake.dimeload.item}"
	
	if not user then
		refined.cake.dimeload.needlogin="{cake.dimeload.login}"
	end

	if srv.gets.sponsor or srv.posts.sponsor then
		refined_project_sponsor(srv,refined)
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
		
--			if not user then
--				refined.cake.dimeload.goto="download"
--				refined.cake.dimeload.error_text=[[You must be logged in to download.]]
				
-- check for a recent log entry and allow a free rety of the download without any extra cost

			if  dl_downloads.allowretry(srv,{project=pname,file=fname}) then

-- secret internal redirect to download a private file
				return ngx.exec("/@private/dimeload/"..pname.."/"..fname)

			elseif page and page.cache.available>0 then -- sponsored download


-- add 1 to the download count
					dl_pages.update(srv,pname.."/"..code,function(srv,e)
						local c=e.cache
						c.downloads=c.downloads+1
						return true								
					end)

-- create log entry
					local d=dl_downloads.create(srv)
					local c=d.cache
					c.user=user and user.cache.id or ""
					c.ip=srv.ip
					c.project=pname
					c.page=page.cache.name
					c.file=fname
					dl_downloads.put(srv,d)

-- secret internal redirect to download a private file
				return ngx.exec("/@private/dimeload/"..pname.."/"..fname)

			elseif (not page) and dluser and dluser.cache.avail>0 then -- personal download (never if on a sponsor page)

-- update user dime count
				dl_users.set(srv,user.cache.id,function(srv,e)
					local c=e.cache
					c.spent=c.spent+1
					c.avail=c.avail-1
					return true
				end)

-- create download log entry
				local d=dl_downloads.create(srv)
				local c=d.cache
				c.user=user.cache.id
				c.ip=srv.ip
				c.project=pname
				c.page=""
				c.file=fname
				dl_downloads.put(srv,d)

-- secret internal redirect to download a private file
				return ngx.exec("/@private/dimeload/"..pname.."/"..fname)

			else
				refined.cake.dimeload.goto="buy"
				refined.cake.dimeload.error_text=[[No dimes available to download with.]]
			end
		end
		
	end
	
	srv.set_mimetype("text/html; charset=UTF-8")
	srv.put(macro_replace("{cake.html.plate}",refined))

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

