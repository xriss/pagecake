-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local ngx=ngx

local wet_html=require("wetgenes.html")

local sys=require("wetgenes.www.any.sys")

local json=require("wetgenes.json")
local dat=require("wetgenes.www.any.data")

local users=require("wetgenes.www.any.users")

local fetch=require("wetgenes.www.any.fetch")

local img=require("wetgenes.www.any.img")

local stash=require("wetgenes.www.any.stash")

local log=require("wetgenes.www.any.log").log -- grab the func from the package

local wet_string=require("wetgenes.string")
local wstring=wet_string
local wstr=wet_string
local replace=wet_string.replace
local macro_replace=wet_string.macro_replace
local trim=wet_string.trim
local str_split=wet_string.str_split
local serialize=wet_string.serialize

local wet_waka=require("wetgenes.waka")
local d_sess =require("dumid.sess")


-- require all the module sub parts
local html=require("data.html")
local meta=require("data.meta")
local file=require("data.file")

-- replacement version of module that does not global
local module=function(modname, ...)
	local ns={ _NAME = modname , _PACKAGE = string.gsub (modname, "[^.]*$", "") }
	ns._M = ns
	package.loaded[modname] = ns
	setfenv (2, ns)
	for _,f in ipairs({...}) do f(ns) end
end
module("data")
local comments=require("note.comments")

-----------------------------------------------------------------------------
--
-- create get and put wrapper functions
--
-----------------------------------------------------------------------------
local function make_get_put(srv)
	local get=function(a,b)
		b=b or {}
		b.srv=srv
		return wet_html.get(html,a,b)
	end
	local put=function(a,b)
		srv.put(get(a,b))
	end
	return get,put
end

-----------------------------------------------------------------------------
--
-- get an id from a string, returns 0 if none
--
-----------------------------------------------------------------------------
function sanitize_id(s)
	local num=math.floor( tonumber( s or 0 ) or 0 )
	if num==0 then
		num=string.gsub(s or "", "[^0-9a-zA-Z%-_%.]+", "" ) -- only allow some chars
		if num=="" or num=="0" then num=0 end
	end
	return num
end

-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-----------------------------------------------------------------------------
function serv(srv)
	if srv.url_slash[srv.url_slash_idx+0]=="" and srv.url_slash[srv.url_slash_idx+1]=="admin" then
--		return serv_admin(srv)
	end
	
--	put(tostring(user and user.cache),{H=H})

--log("srv.postgot\n"..tostring(srv.posts))
--log("admin:"..tostring(user and user.cache and user.cache.admin))

	local num=sanitize_id(srv.url_slash[srv.url_slash_idx+0])
	
	local stash_group=sanitize_id(srv.url_slash[srv.url_slash_idx+0])
	local stash_id
	if srv.url_slash[srv.url_slash_idx+1] then
		stash_id=stash_group
		for i=srv.url_slash_idx+1,#srv.url_slash do
			stash_id=stash_id.."/"..sanitize_id(srv.url_slash[i])
		end
	end
	
	if stash_id then
		local m=stash.get(srv,"data&"..stash_id)
		if m and m.data then
--log("stash got "..stash_id)
			srv.set_mimetype( m.mime )
			srv.set_header("Access-Control-Allow-Origin","*")
			srv.set_header("Cache-Control","public") -- allow caching of page
			srv.set_header("Content-Length",#m.data)
			srv.set_header("Expires",os.date("%a, %d %b %Y %H:%M:%S GMT",os.time()+(60*60))) -- one hour cache
			srv.put(m.data)
			return
		end
	end
	
	if stash_group then
		local m=stash.get(srv,"data&"..stash_group)
		if m then
--log("stash got "..stash_group)
			srv.set_mimetype( m.mime )
			srv.set_header("Access-Control-Allow-Origin","*")
			srv.set_header("Cache-Control","public") -- allow caching of page
			srv.set_header("Content-Length",#data)
			srv.set_header("Expires",os.date("%a, %d %b %Y %H:%M:%S GMT",os.time()+(60*60))) -- one hour cache
			srv.put(m.data)
			return
		end
	end

-- first try to use stash for this data

	

-- finally go get the data and build the cache in the process
	
local sess,user=d_sess.get_viewer_session(srv)
local get,put=make_get_put(srv)

		
	if num~=0 and tostring(num)==srv.url_slash[srv.url_slash_idx+0] then --got us an id
	
		local em=meta.get(srv,num)
		
		if em then -- got a data file to serv
		
			-- if using a real pubname then do not try and list files or srv a file within
			if em.cache.mimetype=="application/zip" and em.cache.pubname~=srv.url:sub(-#em.cache.pubname) then
			
				local ds={}
				local ef=file.get(srv,em.cache.filekey)
				ds[#ds+1]=ef.cache.data
				while ef.cache.nextkey~=0 do
					ef=file.get(srv,ef.cache.nextkey) -- read next part
					ds[#ds+1]=ef.cache.data
				end
				local zip=sys.bytes_join(ds) -- join them together
				

				if srv.url_slash[srv.url_slash_idx+1] then -- try requesting file inside
					local t={}
					for i=srv.url_slash_idx+1 , #srv.url_slash do
						t[#t+1]=srv.url_slash[i]
					end
					local name=table.concat(t,"/") -- this is the name we want					
					local data=sys.zip_read(zip,name)
					if data then
					
						local meta={
								mime=(srv.vars.mime or guess_mimetype(name)).."; charset=UTF-8",
								data=data,
								group="data&"..tostring(num),
							}
						srv.set_mimetype( mime )
						srv.set_header("Access-Control-Allow-Origin","*")
						srv.set_header("Cache-Control","public") -- allow caching of page
						srv.set_header("Content-Length",#data)
						srv.set_header("Expires",os.date("%a, %d %b %Y %H:%M:%S GMT",os.time()+(60*60))) -- one hour cache
						srv.put(data)
--log("stash put "..stash_id)
						stash.put(srv,"data&"..stash_id,meta) -- save in cache for later
						
						return
					end
				end

				
-- by default we just try and list the contents
				
-- upload / list for admin

				srv.set_mimetype("text/html; charset=UTF-8")
	
				local t=sys.zip_list(zip)
				
				srv.set_mimetype("text/html".."; charset=UTF-8")
--				srv.set_header("Cache-Control","public") -- allow caching of page
--				srv.set_header("Expires",os.date("%a, %d %b %Y %H:%M:%S GMT",os.time()+(60*60))) -- one hour cache

				srv.put("<html><head></head><body>\n") -- very bare contents list

				for i,v in ipairs(t or {}) do
				
					srv.put(v.size.." : <a href=\""..v.name.."\">"..v.name.."</a><br/>\n")
					
				end

				srv.put("</body></html>\n")
				return
				
			else
		
				local ef=file.cache_get_data(srv,em.cache.filekey)
				
				srv.set_mimetype( (srv.vars.mime or em.cache.mimetype).."; charset=UTF-8")				
				srv.set_header("Access-Control-Allow-Origin","*")
				srv.set_header("Cache-Control","public") -- allow caching of page
				srv.set_header("Content-Length",em.cache.size)
				srv.set_header("Expires",os.date("%a, %d %b %Y %H:%M:%S GMT",os.time()+(60*60))) -- one hour cache
				
				while true do
				
					if ef and ef.cache then
					
						srv.put(ef.cache.data or "ERROR:"..wstr.serialize(ef))
						
						if ef.cache.nextkey==0 then return end -- last chunk
						
						ef=file.get(srv,ef.cache.nextkey) -- read next part
						
					else
						return -- error
					end
				end
				
			end
		end
		
	end
	
-- should we error?
	do
		local t=srv.url_slash[srv.url_slash_idx+0] -- request id or name
		if t and (t~="") then -- it was a bad request so return missing file
		
			ngx.exit( ngx.HTTP_NOT_FOUND )
		end
	end

-- demand admin from this point on	
	if not srv.is_admin(user) then -- adminfail
		return srv.redirect("/dumid?continue="..srv.url)
	end

--	put(tostring(user and user.cache),{H=H})
	if srv.is_admin(user) then -- admin
	
		local posts={} -- remove any gunk from the posts input
		if srv.method=="POST" and srv:check_referer() then
			for i,v in pairs(srv.posts) do
				posts[i]=v
			end
		end
		
		posts["filedata"]=srv.uploads["filedata"] or srv.posts["filedata"] -- uploaded file

		for i,v in pairs({"filename","mimetype","submit"}) do
			if posts[v] then posts[v]=trim(posts[v]) end
		end
		for i,v in pairs({"dataid"}) do
			if posts[v] then posts[v]=sanitize_id(posts[v]) end
		end
	
--		put(tostring(posts).."<br/>",{H=H})
		
--log("postgot\n"..tostring(posts))
		
		if posts.submit=="Upload" then
			local dat={}
			dat.id=( (posts.dataid~="") and posts.dataid ) or 0
			
			local fd=posts.filedata
		
			dat.data=(fd and fd.data) or fd
			dat.size=(fd and fd.size) or (fd and #fd)
			dat.name=(fd and fd.name) or posts.filename
			dat.owner=user.cache.email
			
			if posts.mimetype and posts.mimetype~="" then dat.mimetype=posts.mimetype end
			if posts.filename and posts.filename~="" then dat.name=posts.filename end
			
			local d=upload(srv,dat)
--log("stash clear "..d.id)
			stash.delgroup(srv,"data&"..d.id)

			return srv.redirect("/data")
			
		elseif posts.submit=="DELETE" then
			local dat={}
			dat.id=( (posts.dataid~="") and posts.dataid ) or 0
			
			local fd=posts.filedata
		
			dat.data=(fd and fd.data) or fd
			dat.size=(fd and fd.size) or (fd and #fd)
			dat.name=(fd and fd.name) or posts.filename
			dat.owner=user.cache.email
			
			if posts.mimetype and posts.mimetype~="" then dat.mimetype=posts.mimetype end
			if posts.filename and posts.filename~="" then dat.name=posts.filename end
			
			delete(srv,dat)
--log("stash clear "..d.id)
			stash.delgroup(srv,"data&"..dat.id)

			return srv.redirect("/data")
			
		end
		
--		put("<img src=\"/data{pubname}\" />",{H=H,pubname=pubname})
		
		local d={H=H}
		if srv.url_slash[srv.url_slash_idx+0]=="" then --//commanands
			if srv.url_slash[srv.url_slash_idx+1]=="edit" then
				d.id=sanitize_id( srv.url_slash[srv.url_slash_idx+2] )

				local em=meta.get(srv,d.id)
				
				if em then -- got a data file to serv
					d.filename=em.cache.pubname:match("([^/]*)$")
					d.mimetype=em.cache.mimetype
				end
				
			end
		end
		
-- upload / list for admin

		srv.set_mimetype("text/html; charset=UTF-8")
--[[
		put("header",{title="data : ",
			H={sess=sess,user=user},
			})
]]
	
		put("data_upload_form",d)
		
		
		local page={}		
		page.size=math.floor( tonumber(srv.gets.len) or 100)
		page.show=math.floor( tonumber(srv.gets.off) or 0)
		if page.size<1 then page.show=1 end	-- no small sizes
		if page.show<0 then page.show=0 end	-- no negative offsets
		
		local t=meta.list(srv,{sort="usedate",limit=page.size,offset=page.show,group=srv.gets.group or "/"})

		page.next=page.show+page.size
		page.prev=page.show-page.size

		if page.prev<0 then page.prev=0 end -- and prev does not go below 0 either	
		if t and (#t < page.size) then page.next=0 end -- looks like the last page so set next to 0
		
		put("data_list_foot",{H=H,page=page})
		for i,v in ipairs(t) do
		
			put("data_list_item",{H=H,it=v})
		
		end
		put("data_list_foot",{H=H,page=page})
		
		
	end
	
	
end

-----------------------------------------------------------------------------
--
-- upload a file to the database (ie a file upload) returns data id,entity,url etc
-- so it can now be displayed if it was a successful upload
--
-- incoming requirements are
--
-- data = the data of the file
-- size = the size of the file
-- name = the name of the file
-- owner = file owner, defaults to user.cache.email
--
-- optional parts are
--
-- id = numerical datakey, pass in 0 or nil to create a new one, otherwise we update the given
-- mimetype = mimetype to use when serving, we try to guess this from the name if not supplied
--
-- return values are
--
-- ent = the meta entity which we created / updated
-- id = the numerical datakey
-- url = the url we can access this file at, relative to this server base so begins with "/"
--
-----------------------------------------------------------------------------
function read(srv,id)

	local num=sanitize_id(id)

	local em=meta.get(srv,num)
	
	if em then -- got a data file to serv
	
		local ef=file.get(srv,em.cache.filekey)
		
		local c=em.cache
		
		c.data={}
		
		while true do
		
			if ef then
			
				c.data[#c.data+1]=ef.cache.data
				
				if ef.cache.nextkey==0 then
					c.data=c.data[1] -- concat chunks TODO just grab first chunk for now since two chunks will be too big and break the image handler anyhow :)
					return c
				end -- last chunk
				
				ef=file.get(srv,ef.cache.nextkey) -- read next part
				
			else
				return -- error
			end
		end
		
	end

end

-----------------------------------------------------------------------------
--
-- upload a file to the database (ie a file upload) returns data id,entity,url etc
-- so it can now be displayed if it was a successful upload
--
-- incoming requirements are
--
-- data = the data of the file
-- size = the size of the file
-- name = the name of the file
-- owner = file owner, defaults to user.cache.email
--
-- optional parts are
--
-- id = numerical datakey, pass in 0 or nil to create a new one, otherwise we update the given
-- mimetype = mimetype to use when serving, we try to guess this from the name if not supplied
-- group = group this data, eg by where it comes from, default it "/"
--
-- return values are
--
-- ent = the meta entity which we created / updated
-- id = the numerical datakey
-- url = the url we can access this file at, relative to this server base so begins with "/"
--
-----------------------------------------------------------------------------
function upload(srv,dat)

local em
local emc

	if ( not dat.id ) or dat.id==0 or dat.id=="" then -- a new file

		em=meta.create(srv)
		emc=em.cache
	
	else -- editing an old file

		em=meta.get(srv,dat.id)
		if not em then -- failed to get an entity to update so make a new one with custom id

			em=meta.create(srv)
			emc=em.cache		
			em.key.id=dat.id
			emc.id=em.key.id
		end
		emc=em.cache

	end
	
	dat.ent=em
			
	if (not dat.mimetype) or (dat.mimetype=="") then
		emc.mimetype=guess_mimetype(dat.name)
	else
		emc.mimetype=dat.mimetype
	end

	emc.filename=dat.name

	if dat.data then -- got a file to create

		file.delete(srv,emc.filekey) -- remove any old file data
		
		emc.size=dat.size
		emc.owner=dat.owner
		emc.group=dat.group or emc.group or "/"
							
		if not emc.id or emc.id==0 or emc.id=="" then
			meta.put(srv,em)  -- write once to get an id for the meta
			emc=em.cache
			dat.id=emc.id -- new id
		end
		
		local dd=sys.bytes_split(dat.data,1000*1000) -- need smaller 1meg chunks
		
		for i,v in ipairs(dd) do

			v.ef=file.create(srv)
			local efc=v.ef.cache
			
			efc.size=v.size
			
			efc.metakey=emc.id -- the meta id
			file.put(srv,v.ef) -- save this data, to get an id
			efc=v.ef.cache
			
			if i==1 then
				emc.filekey=efc.id -- remember the id, of the first chunk only
			end
			
		end
		
-- write the real data this time and save the next/prev keys

		for i,v in ipairs(dd) do
		

			local efc=v.ef.cache

			efc.data=v.data
			
			if dd[i-1] then
				if dd[i-1].ef then
					efc.prevkey=dd[i-1].ef.cache.id
				end
			end

			if dd[i+1] then
				efc.nextkey=dd[i+1].ef.cache.id
			end
			
			file.put(srv,v.ef) -- save the data, for real
		end
	end
	
	if dat.pubname then
		emc.pubname=dat.pubname
	else
		emc.pubname="/".. emc.id .."/".. (dat.name or "")-- default url
	end

	meta.put(srv,em)  -- save the meta
	emc=em.cache
	
-- output data

	dat.url="/data/"..emc.pubname -- where to reference this file

	return dat
end

-----------------------------------------------------------------------------
--
-- upload a file to the database (ie a file upload) returns data id,entity,url etc
-- so it can now be displayed if it was a successful upload
--
-- incoming requirements are
--
-- data = the data of the file
-- size = the size of the file
-- name = the name of the file
-- owner = file owner, defaults to user.cache.email
--
-- optional parts are
--
-- id = numerical datakey, pass in 0 or nil to create a new one, otherwise we update the given
-- mimetype = mimetype to use when serving, we try to guess this from the name if not supplied
--
-- return values are
--
-- ent = the meta entity which we created / updated
-- id = the numerical datakey
-- url = the url we can access this file at, relative to this server base so begins with "/"
--
-----------------------------------------------------------------------------
function delete(srv,dat)

local em
local emc

	if ( not dat.id ) or dat.id==0 or dat.id=="" then -- a new file
	else -- editing an old file

		em=meta.get(srv,dat.id)
		if em then
			emc=em.cache
			file.delete(srv,emc.filekey) -- remove any old file data	
			meta.del(srv,em)  -- save the meta
		end
	end
	

	return dat
end

--
-- guess a mimetype given a filename
--
local guess_mimetype_lookup={
	[".jpg"]="image/jpeg",
	[".jpeg"]="image/jpeg",
	[".png"]="image/png",
	[".gif"]="image/gif",
	[".bmp"]="image/bmp",
	[".tif"]="image/tiff",
	[".tiff"]="image/tiff",
	[".pcx"]="image/x-pcx",
	[".txt"]="text/plain",
	[".css"]="text/css",
	[".htm"]="text/html",
	[".html"]="text/html",
	[".js"]="text/javascript",
	[".zip"]="application/zip",
	[".pdf"]="application/pdf",
	[".flac"]="audio/flac",
	[".ogv"]="video/ogg",
	[".ogg"]="audio/ogg",
	[".oga"]="audio/ogg",
	[".mp3"]="audio/mp3",
	[".manifest"]="text/cache-manifest",
}
function guess_mimetype(name)
	local ext=name:match("%.[^%.]+$") -- get extension of filename, including .
	if ext then ext=ext:lower() else ext="" end
	return guess_mimetype_lookup[ ext ] or "application/octet-stream"
end
