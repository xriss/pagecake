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
		test=		M.serv_test,
		upload=		M.serv_upload,
	}
	local f=cmds[ string.lower(cmd or "") ]
	if f then return f(srv) end

-- bad page
	return srv.redirect("/")
end



-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-----------------------------------------------------------------------------
function M.serv_test(srv)
local sess,user=d_sess.get_viewer_session(srv)
	
	local refined=waka.fill_refined(srv,"paint")
	html.fill_cake(srv,refined) -- add paint html
	
	if srv.is_admin(user) then
		refined.cake.admin="{cake.paint.admin_bar}"
	end

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
	end
	
	if not fat then
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
		})

		if not dpix then
			ret.status="bad pix image"
		end

		local dfat=data.upload(srv,{
			id=fat_id,
			name="fat.png",
			owner=user.cache.id,
			data=fat.body,
			size=#fat.body,
			mimetype=fat_mimetype,
		})
		
		if not dfat then
			ret.status="bad fat image"
		end


		if not ret.status then -- nothing failed the above 
			local id=user.cache.id.."/"..posts.day
			local it=pimages.set(srv,id,function(srv,e) -- create or update
				local c=e.cache
				
				c.title="test"
				c.userid=user.cache.id
				c.user_name=user.cache.name
				c.day=posts.day
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
-- get image detail in a list
--
-----------------------------------------------------------------------------
function M.chunk_import(srv,opts)
opts=opts or {}

	local list=pimages.list(srv,opts)

	local ret={}
	for i,v in pairs(opts) do ret[i]=v end -- copy opts into the return
	
	for i,v in ipairs(list) do
	
		local c=v.cache
		
		c.date=os.date("%Y-%m-%d %H:%M:%S",c.updated)

		if type(opts.hook) == "function" then -- fix up each item?
			opts.hook(v,{class="image"})
		end
		
		ret[#ret+1]=c
	end
	
	return ret		
end


