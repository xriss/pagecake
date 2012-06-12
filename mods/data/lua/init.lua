-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local wet_html=require("wetgenes.html")

local sys=require("wetgenes.www.any.sys")

local json=require("wetgenes.json")
local dat=require("wetgenes.www.any.data")

local users=require("wetgenes.www.any.users")

local fetch=require("wetgenes.www.any.fetch")

local img=require("wetgenes.www.any.img")

local log=require("wetgenes.www.any.log").log -- grab the func from the package

local wet_string=require("wetgenes.string")
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



-- our options
local opts_mods_blog={} or ( opts and opts.mods and opts.mods.blog )


local LAYER_PUBLISHED = 0
local LAYER_DRAFT     = 1
local LAYER_SHADOW    = 2

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
	
local sess,user=d_sess.get_viewer_session(srv)
local get,put=make_get_put(srv)

--	put(tostring(user and user.cache),{H=H})

--log("srv.postgot\n"..tostring(srv.posts))
--log("admin:"..tostring(user and user.cache and user.cache.admin))

	local num=sanitize_id(srv.url_slash[srv.url_slash_idx+0])
		
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
					
						srv.set_mimetype( (srv.vars.mime or guess_mimetype(name)).."; charset=UTF-8" )
						srv.set_header("Cache-Control","public") -- allow caching of page
						srv.set_header("Expires",os.date("%a, %d %b %Y %H:%M:%S GMT",os.time()+(60*60))) -- one hour cache
						srv.put(data)
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
				srv.set_header("Cache-Control","public") -- allow caching of page
				srv.set_header("Expires",os.date("%a, %d %b %Y %H:%M:%S GMT",os.time()+(60*60))) -- one hour cache

				
				while true do
				
					if ef then
					
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
	
	
	
	if not( user and user.cache and user.cache.admin ) then -- adminfail
		return srv.redirect("/dumid?continue="..srv.url)
	end


--	put(tostring(user and user.cache),{H=H})
	if user and user.cache and user.cache.admin then -- admin
	
		local posts={} -- remove any gunk from the posts input
		if srv.method=="POST" and srv.check_referer(srv.headers.Referer,srv.url) then
			for i,v in pairs(srv.posts) do
				posts[i]=v
			end
		end
		
		posts["filedata"]=srv.uploads["filedata"] -- uploaded file

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
			
			dat.data=posts.filedata and posts.filedata.data
			dat.size=posts.filedata and posts.filedata.size
			dat.name=posts.filedata and posts.filedata.name
			dat.owner=user.cache.email
			
			if posts.mimetype and posts.mimetype~="" then dat.mimetype=posts.mimetype end
			if posts.filename and posts.filename~="" then dat.name=posts.filename end
			
			upload(srv,dat)
			
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
		put("header",{title="data : ",
			H={sess=sess,user=user},
			})
	
		put("data_upload_form",d)
		
		local t=meta.list(srv,{sort="usedate"})
		
		for i,v in ipairs(t) do
		
			put("data_list_item",{H=H,it=v})
		
		end
		
		put("footer")
		
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
