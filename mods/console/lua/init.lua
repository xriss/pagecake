-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local wet_html=require("wetgenes.html")

local sys=require("wetgenes.www.any.sys")

--local dat=require("wetgenes.www.any.data")

local users=require("wetgenes.www.any.users")

local img=require("wetgenes.www.any.img")

local log=require("wetgenes.www.any.log").log -- grab the func from the package

local wet_string=require("wetgenes.string")
local str_split=wet_string.str_split
local serialize=wet_string.serialize

local d_sess =require("dumid.sess")

-- require all the module sub parts
local html=require("console.html")



--
-- Which can be overeiden in the global table opts
--



-- replacement version of module that does not global
local module=function(modname, ...)
	local ns={ _NAME = modname , _PACKAGE = string.gsub (modname, "[^.]*$", "") }
	ns._M = ns
	package.loaded[modname] = ns
	setfenv (2, ns)
	for _,f in ipairs({...}) do f(ns) end
end
module("console")

-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-- do not cache the srv param localy, make sure it cascades around
--
-----------------------------------------------------------------------------
function serv(srv)
local sess,user=d_sess.get_viewer_session(srv)

	if not srv.is_admin(user) then -- adminfail
		return false
	end

	local function put(a,b)
		b=b or {}
		b.srv=srv
		srv.put(wet_html.get(html,a,b))
	end

	if not srv.is_admin(user) then -- error must be admin
		srv.set_mimetype("text/html")
		put("header",{})
		put("error_need_admin",{})
		put("footer",{})
		return
	end
	
	if post(srv) then return end -- post handled everything

	local slash=srv.url_slash[ srv.url_slash_idx ]
--	if slash=="image" then return image(srv) end -- image request
		


	srv.set_mimetype("text/html")
	put("header",{user=user})
	
	put("console_form",{output=srv.posts.output or "",input=srv.posts.input or srv.opts("mods","console","input") or ""})
	
	put("footer",{})
	
end


-----------------------------------------------------------------------------
--
-- the post function, looks for post params and handles them
--
-----------------------------------------------------------------------------
function post(srv)

	if srv.posts.input then -- run it
	
		local b,f,r
		local head=
[[local _r={} local function print(s) _r[#_r+1]=tostring(s) end

]]
		local tail=
[[

return table.concat(_r,"\n")

]]
		f,r=loadstring( head..srv.posts.input..tail )
		
		if f then
			b,r=pcall( f , srv )
		end
		
		srv.posts.output=srv.posts.output.."-- \n"..tostring(r)
	
	end

	return false -- keep going anyway

end

