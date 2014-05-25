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
local wstr=wet_string
local trim=wet_string.trim
local str_split=wet_string.str_split
local serialize=wet_string.serialize
local macro_replace=wet_string.macro_replace
local dprint=function(...)print(wstr.dump(...))end

local mime=require("mime")

local stash=require("wetgenes.www.any.stash")
local img=require("wetgenes.www.any.img")


local wet_waka=require("wetgenes.waka")
local d_sess =require("dumid.sess")
local d_users=require("dumid.users")

-- require all the module sub parts
local html=require("paint.html")

local waka=require("waka")
local note=require("note")

local wakapages=require("waka.pages")
local comments=require("note.comments")

local data=require("data")
local pimages=require("paint.images")
local plots=require("paint.plots")



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
--		test=		M.serv_test,
		upload=		M.serv_upload,
		list=		M.serv_list,
		view=		M.serv_view,
		draw=		M.serv_draw,
		admin=		M.serv_admin,
	}
	local f=cmds[ string.lower(cmd or "") ]
	if f then return f(srv) end

-- bad page
	return srv.redirect("/")
end


-----------------------------------------------------------------------------
--
-- all views fill in this stuff
--
-----------------------------------------------------------------------------
function M.fill_refined(srv,name)

	local refined=waka.fill_refined(srv,name)

	if srv.is_admin(user) then
		refined.cake.admin="{cake.paint.admin_bar}"
	end
	refined.today=M.get_today()
	
	if refined.opts.flame=="on" then -- add comments to this page
		refined.cake.note.title=refined.it and refined.it.title or "swanky"
		refined.cake.note.url=srv.url_local
		comments.build(srv,refined)
	end

	return refined
end

-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-----------------------------------------------------------------------------
function M.serv_admin(srv)
local sess,user=d_sess.get_viewer_session(srv)
	
	local refined=M.fill_refined(srv)

	if not srv.is_admin(user) then
		return srv.redirect("/dumid?continue="..srv.url)
	end

	refined.title="admin"

	refined.body="testting?"


	srv.set_mimetype("text/html; charset=UTF-8")
	srv.put(macro_replace("{cake.html.plate}",refined))

end

-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-----------------------------------------------------------------------------
function M.serv_list(srv)
local sess,user=d_sess.get_viewer_session(srv)
	
	local refined=M.fill_refined(srv,"paint/list")
	
	local id_str=srv.url_slash[ srv.url_slash_idx+1 ] if id_str=="" then id_str=nil end
	local id_num=tonumber(id_str or "") if tostring(id_num)~=id_str then id_num=nil end

	local opts={sort="created-"}
	
	if id_num then
		opts.day=id_num
	elseif id_str then
		opts.userid=id_str
	end
--dprint(opts)
	local list=pimages.list(srv,opts)
--dprint(list)
	refined.list={}
	for i,v in ipairs(list) do
		local c=v.cache
		if c then
			c.date=os.date("%Y-%m-%d",c.created)
			refined.list[#refined.list+1]=c
		end
	end
	if not refined.list[1] then refined.list=nil end
	
	refined.example_plate=[[
	<img src="/data/{it.pix_id}" /><br/>
	<img src="/data/{it.fat_id}" /><br/>
	<h1>{it.title}</h1>
	<h2>by {it.user_name}</h2>
	<a href="/paint/list/{it.day}">more from the same day</a><br/>
	<a href="/paint/list/{it.userid}">more from the same user</a><br/>
	]]
	refined.example=[[
	<pre>{-list}</pre>
	{-list:example_plate}
	]]

	srv.set_mimetype("text/html; charset=UTF-8")
	srv.put(macro_replace("{cake.html.plate}",refined))

end

-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-----------------------------------------------------------------------------
function M.serv_view(srv)
local sess,user=d_sess.get_viewer_session(srv)
	
	local refined=M.fill_refined(srv,"paint/view")
	
	local id_user=srv.url_slash[ srv.url_slash_idx+1 ]	
	local id_day=srv.url_slash[ srv.url_slash_idx+2 ]
	if not id_user or not id_day then
		srv.redirect("/")
	end
	
	local id=id_user.."/"..id_day
	
	local im=pimages.get(srv,id)
	if not im then
		srv.redirect("/")
	end
	refined.it=im.cache
	im.cache.date=os.date("%Y-%m-%d",im.cache.created)

	
	refined.example=[[
	<pre>{it}</pre>
	<img src="/data/{it.pix_id}" /><br/>
	<img src="/data/{it.fat_id}" /><br/>
	<h1>{it.title}</h1>
	<h2>by {it.user_name}</h2>
	<a href="/paint/list/{it.day}">more from the same day</a><br/>
	<a href="/paint/list/{it.userid}">more from the same user</a><br/>
	{-cake.comments}
	]]

		
	srv.set_mimetype("text/html; charset=UTF-8")
	srv.put(macro_replace("{cake.html.plate}",refined))

end

-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-----------------------------------------------------------------------------
function M.serv_draw(srv)
local sess,user=d_sess.get_viewer_session(srv)
	
	if not user then
		return srv.redirect("/dumid?continue="..srv.url)
	end

	local refined=M.fill_refined(srv,"paint/draw")

--dprint(user)

	local id=user.cache.id.."/"..refined.today.day
	local im=pimages.get(srv,id)
	if im and im.cache then
		refined.it=im.cache
	else
		refined.it={}
		local c=refined.it
		for n,v in pairs(refined.today) do c[n]=v end
		c.title=refined.today.title
		c.userid=user.cache.id
		c.user_name=user.cache.name
		c.day=refined.today.day
		c.palette=refined.today.pal.name
		c.shader=refined.today.fat.name

		c.pix_id=("paint_pix_"..user.cache.id.."_"..refined.today.day):gsub("([^%w]+)","_")
		c.pix_width=refined.today.pix.width
		c.pix_height=refined.today.pix.height
		c.pix_depth=refined.today.pix.depth

		c.fat_id=("paint_fat_"..user.cache.id.."_"..refined.today.day):gsub("([^%w]+)","_")
		c.fat_width=refined.today.fat.width
		c.fat_height=refined.today.fat.height
		c.fat_depth=refined.today.fat.depth

	end
	
	refined.swanky=[=[
<div id="paint_draw" style=" width:100%; height:100%; "></div>
<script id="paint_configure" type="text/lua" >--<![CDATA[
{today.lson}
--]]></script>
<script>
paint_draw=function()
{
	head.load("/js/paint/paint.js");
}
</script>
]=]

	refined.example=[[
	{swanky}
<br/>
<br/>
<a href="#" onclick='paint_draw(); this.style.display="none"; return false;'>Draw</a>
<br/>
<br/>
<a href="#" onclick='paint_get_images(); return false;'>Save</a>
<br/>
<span id="img_status"></span>
<br/>
<br/>
<a href="#" onclick='paint_set_image("/data/{it.pix_id}"); return false;'>Load</a>
<br/>
<br/>
Draw {today.title} using the {today.pal.name} palette In {today.pix.width} x {today.pix.height} pixels, stylishly rendered with the {today.fat.name} shader.

	<pre>{it}</pre>
	<img id="img_pix" src="/data/{it.pix_id}" /><br/>
	<img id="img_fat" src="/data/{it.fat_id}" /><br/>
	<h1>{it.title}</h1>
	<h2>by {it.user_name}</h2>

	]]


	srv.set_mimetype("text/html; charset=UTF-8")
	srv.put(macro_replace("{cake.html.plate}",refined))
	
end


-----------------------------------------------------------------------------
--
-- upload an image (possibly replacing what is there already)
-- this is time locked to today GMT only, with a little bit of safezone either side
-- the day challenge changes at midnight GMT eitherway.
--
-----------------------------------------------------------------------------
function M.serv_upload(srv)
local sess,user=d_sess.get_viewer_session(srv)

-- handle posts cleanup
	local posts={} -- remove any gunk from the posts input
	-- check if this post probably came from this page before allowing post params
	if srv.method=="POST" and srv:check_referer() then
		for i,v in pairs(srv.posts) do
			posts[i]=v
		end
	end
	if posts.submit then posts.submit=trim(posts.submit) end
	for n,v in pairs(srv.uploads) do
		posts[n]=v
	end
	
	local d=math.floor( os.time() / (60*60*24) ) -- only accept today
	posts.day=tonumber(posts.day or 0) or 0
--	log(" day=", posts.day, " myday=",d, " pix=", #posts.pix , " fat=",#posts.fat)

	local ret={} -- return this as json
		
	if	( (posts.day)~=(d) )   and
		( (posts.day)~=(d-1) ) then -- allow yesterday as well as today

		ret.status="bad date"
	end
	
	local day=M.get_today(srv,posts.day)
	
	
	if not user then 
		ret.status="need login"
	end
	
	local pix,pix_mimetype
	local fat,fat_mimetype
	pcall(function()

		local aa=wstr.split( posts.pix , "," )
		local mt=aa[1]
		mt=wstr.split( mt , ":" )[2]
		mt=wstr.split( mt , ";" )[1]
		local d=mime.unb64(aa[2])
		if #d < 256*1024 then -- check size
			pix=img.get( d , mt ) -- convert to image
			pix_mimetype=mt
			img.memsave(pix,"png")
		end

		local aa=wstr.split( posts.fat , "," )
		local mt=aa[1]
		mt=wstr.split( mt , ":" )[2]
		mt=wstr.split( mt , ";" )[1]
		local d=mime.unb64(aa[2])
		if #d < 256*1024 then -- check size
			fat=img.get( d , mt ) -- convert to image
			fat_mimetype=mt
			img.memsave(fat,"png")
		end
		

	end)

	if not pix then
		ret.status="bad pix image"
	elseif not fat then
		ret.status="bad fat image"
	end
		
	if not ret.status then -- nothing failed the above checks
	
		local pix_id=("paint_pix_"..user.cache.id.."_"..posts.day):gsub("([^%w]+)","_")
		local fat_id=("paint_fat_"..user.cache.id.."_"..posts.day):gsub("([^%w]+)","_")

		local dpix=data.upload(srv,{
			id=pix_id,
			name="pix.png",
			owner=user.cache.id,
			data=pix.body,
			size=#pix.body,
			mimetype=pix_mimetype,
			group="/paint/",
		})

		if not dpix then
			ret.status="bad pix data upload"
		end

		local dfat=data.upload(srv,{
			id=fat_id,
			name="fat.png",
			owner=user.cache.id,
			data=fat.body,
			size=#fat.body,
			mimetype=fat_mimetype,
			group="/paint/",
		})
		
		if not dfat then
			ret.status="bad fat data upload"
		end


		if not ret.status then -- nothing failed the above 
			local id=user.cache.id.."/"..posts.day
			local it=pimages.set(srv,id,function(srv,e) -- create or update
				local c=e.cache
				
				c.userid=user.cache.id
				c.user_name=user.cache.name
				c.day=day.day
				c.title=day.title
				c.palette=day.pal.name
				c.shader=day.fat.name
				c.rank=0
				
				c.pix_id=pix_id
				c.pix_mimetype=pix_mimetype
				c.pix_width=pix.width
				c.pix_height=pix.height
				c.pix_depth=pix.depth

				c.fat_id=fat_id
				c.fat_mimetype=fat_mimetype
				c.fat_width=fat.width
				c.fat_height=fat.height
				c.fat_depth=fat.depth
				
				ret.cache=c -- remember output

				return true
			end)

			ret.status="OK"
			
		end
	end
	
	srv.set_mimetype("application/json; charset=UTF-8")
	srv.put(json.encode(ret))

end


-----------------------------------------------------------------------------
--
-- get todays plots
--
-----------------------------------------------------------------------------
function M.get_today(srv,num)
	local today=math.floor( os.time() / (60*60*24) ) -- today	
	local day=num or today

	local plot=plots.get(srv,day)
	if plot then return plot.cache end
	
	if day==today then
		local e=plots.create(srv,day)
		local p=require("paint.plots_data")
		local d=p.get(e.cache)
		d.day=day
		for n,v in pairs(d) do e.cache[n]=v end -- copy
		plots.put(srv,e)
	end

	local plot=plots.get(srv,day)
	if plot then return plot.cache end
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

	if opts.paint=="today" then
	
		local d=M.get_today()
		for i,v in pairs(d) do ret[i]=v end -- copy opts into the return
		
	elseif opts.paint=="day" then
	elseif opts.paint=="list" then

		local list=pimages.list(srv,opts)

		
		for i,v in ipairs(list) do
		
			local c=v.cache
			
			c.date=os.date("%Y-%m-%d",c.created)

			if type(opts.hook) == "function" then -- fix up each item?
				opts.hook(v,{class="image"})
			end
			
			ret[#ret+1]=c
		end
	end
	
	return ret		
end


