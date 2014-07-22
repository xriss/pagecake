-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local wet_html=require("wetgenes.html")

local sys=require("wetgenes.www.any.sys")

--local dat=require("wetgenes.www.any.data")

--local user=require("wetgenes.www.any.user")

local img=require("wetgenes.www.any.img")

local log=require("wetgenes.www.any.log").log -- grab the func from the package

local wstr=require("wetgenes.string")
local str_split=wstr.str_split
local serialize=wstr.serialize
local macro_replace=wstr.macro_replace

local waka=require("waka")

-- require all the module sub parts
--local html=require("dice.html")



local ngx=require("ngx")

module("genes")


local connect=function(srv,database_name)
	database_name=database_name or "forum"

	local mysql = require "resty.mysql"
	local db, err = mysql:new()
	if not db then
		return nil , "failed to instantiate mysql: ".. err
	end

	db:set_timeout(1000) -- 1 sec

	local ok, err, errno, sqlstate = db:connect{
		host 			= srv.opts("mysql","host") or "127.0.0.1",
		port 			= srv.opts("mysql","port") or 3306,
		database	 	= database_name,
		user 			= srv.opts("mysql","user") or "root",
		password 		= srv.opts("mysql","password") or "xxx",
--		compact_arrays	=true,
		max_packet_size = 1024 * 1024 }

	if not ok then
		return nil , "failed to connect: "..err..": "..errno.." "..sqlstate
	end
	
	return db
end

local query=function(db,q)
	local res, err, errno, sqlstate = db:query(q)
	if not res then
		return nil , "bad result: "..err..": "..errno..": "..sqlstate.."."
	end
	return res
end

-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-- do not cache the srv param localy, make sure it cascades around
--
-----------------------------------------------------------------------------
function serv(srv)

	local cmd=srv.url_slash[srv.url_slash_idx+0]

	if cmd=="avatar" then
		local name=srv.url_slash[srv.url_slash_idx+1] or ""
		
		local db = assert(connect(srv))
		
		local res
		
		if name:sub(1,1)=="$" then
			local num = tonumber(name:sub(2) or 0 ) or 0
			res=assert(query(db,[[
				select id,login,avatar_loc from fud26_users
				where id=]]..num..[[ limit 1]]
			))
		else
			res=assert(query(db,[[
				select id,login,avatar_loc from fud26_users
				where login=]]..ngx.quote_sql_str(name)..[[ limit 1]]
			))
		end
			
		if res and res[1] then
			if type(res[1].avatar_loc) == "string" then
				local url=string.gmatch(res[1].avatar_loc,"src=\"([^\"]*)")()
				if url then
					ngx.redirect(url)
				end
			end
		end
		
		ngx.redirect("http://www.wetgenes.com/forum/images/custom_avatars/12.png")
		
		return
	end
	
	return

--[=[
-- need the base wiki page, its kind of the main site everything
	local refined=waka.prepare_refined(srv,"genes")

	refined.body="this is a genes test"

	refined.body=refined.body.."CONECTED"

	local res=assert(query([[select id,login,avatar_loc from fud26_users where login="xix" order by id asc limit 100]]))

	refined.body=string.gsub( wstr.dump(res) , "\n" , "<br/>\n" )
    refined.body=refined.body.."<br/>\n#"..#res

	srv.set_mimetype("text/html; charset=UTF-8")
	srv.put(macro_replace("{cake.html.plate}",refined))
]=]

end
