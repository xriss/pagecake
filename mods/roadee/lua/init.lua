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
local rlogs=require("roadee.logs")



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
		upload=		M.serv_upload,
		list=		M.serv_list,
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

	local refined=waka.prepare_refined(srv,name) -- basic root page and setup
	html.fill_cake(srv,refined) -- more local setup

	return refined
end

-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-----------------------------------------------------------------------------
function M.serv_list(srv)
local sess,user=d_sess.get_viewer_session(srv)
	
	local refined=M.fill_refined(srv,"roadee/list")
	
	local id_str=srv.url_slash[ srv.url_slash_idx+1 ] if id_str=="" then id_str=nil end
	local id_num=tonumber(id_str or "") if tostring(id_num)~=id_str then id_num=nil end

	local opts={sort="created-",limit=1000}
	
--dprint(opts)
	local list=rlogs.list(srv,opts)
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
	
	refined.example_plate=refined.example_plate or [[
	<a href="/data/{it.data_id}/" />/data/{it.data_id}/</a> <a href="/data/{it.data_id}/{it.data_id}.zip">download</a><br/>
	]]
	refined.example=refined.example or [[
	{-list:example_plate}
	]]

	waka.display_refined(srv,refined)	

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
--	if srv.method=="POST" and srv:check_referer() then
		for i,v in pairs(srv.posts) do
			posts[i]=v
		end
--	end
	if posts.submit then posts.submit=trim(posts.submit) end
	for n,v in pairs(srv.uploads) do
		posts[n]=v
	end
	
	local ret={} -- return this as json
	
	if posts.submit=="Upload" then
	
		local t

		repeat -- this is not a repeat
		
			if type(posts.data)~="table" then
				ret.status="missing file upload"
				break
			end

			if #posts.data.data>1024*1024 then
				ret.status="file is too large"
				break
			end
		
			t=sys.zip_list(posts.data.data)
			if #t==0 then
				ret.status="file must be a valid zip"
				break
			end

			if #t~=2 then
				ret.status="zip must contain only 2 files ("..#t..")"
				break
			end
	
		until true -- this never repeats

	else
		ret.status="unknown command"
	end

	if not ret.status then -- nothing failed the above checks
	
		local id=sys.md5(posts.data.data) -- dumb key generator

		local dd=data.upload(srv,{
			id=id,
			name=id..".zip",
			owner=0,
			data=posts.data.data,
			size=#posts.data.data,
			mimetype="application/zip",
			group="/roadee/",
		})
		
		if not dd then ret.status="bad data upload" end

		if not ret.status then -- nothing failed the above 
			local it=rlogs.set(srv,id,function(srv,e) -- create or update
				local c=e.cache
				c.data_id=dd.id				
				return true
			end)
			
			if it then
				ret.id=id
				ret.status="OK"
			else
				ret.status="ERROR" -- yeah uhm, not sure what happened there
			end
		end
	end
	
	srv.set_mimetype("application/json; charset=UTF-8")
	srv.put(json.encode(ret))

end
