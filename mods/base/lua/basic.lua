-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local opts=require("opts") -- setup global opts table full of options and overides

local dat=require("wetgenes.www.any.data")
local cache=require("wetgenes.www.any.cache")
local fetch=require("wetgenes.www.any.fetch")
local users=require("wetgenes.www.any.users")


local wstr=require("wetgenes.string")
local wet_string=wstr
local str_split=wet_string.str_split
local serialize=wet_string.serialize

local iplog=require("wetgenes.www.any.iplog")
local ngx=ngx

-- replacement version of module that does not global
local module=function(modname, ...)
	local ns={ _NAME = modname , _PACKAGE = string.gsub (modname, "[^.]*$", "") }
	ns._M = ns
	package.loaded[modname] = ns
	setfenv (2, ns)
	for _,f in ipairs({...}) do f(ns) end
end
module("base.basic")

local log=require("wetgenes.www.any.log").log -- grab the func from the package

-----------------------------------------------------------------------------
--
-- an error response
--
-----------------------------------------------------------------------------
function serv_fail(srv)

	srv.exit(404)

end


-----------------------------------------------------------------------------
--
-- the main serv function, named the same as the file it is in
--
-----------------------------------------------------------------------------
function serv(srv)


	if not ngx then -- gae hax tbh
	
		srv.opts=function(...)
			local t=opts
			for i,v in ipairs({...}) do
				t=t and t[v]
			end
			return t
		end
		
	end

	srv.is_admin = function(user,minimods)
		if user and user.cache then
			if user.cache.admin then return true end -- site admin
			if minimods then -- check named admin list in opts
				if srv.opts(minimods,user.cache.id) then 
					return true
				end
			end
		end
		return false
	end
	
	srv.is_local=function()
		if srv.ip=="127.0.0.1" then return true end
		return false
	end

	srv.check_referer=check_referer

dat.countzero()
cache.countzero()
fetch.countzero()

	srv.clock=os.clock() -- a relative time we started at
	srv.time=os.time() -- the absolute time we started

	srv.url_slash=str_split("/",srv.url) -- break the input url
	srv.crumbs={} -- for crumbs based navigation 

--	local guser=users.get_google_user() -- google handles its own login
--	if guser and guser.admin then -- trigger any special preadmin codes?
--	else -- only non admins get rate limited


--	end

-- check for sitedown fail whale
	local cmd=srv.url_slash[4]
	if cmd~="admin" and cmd~="dumid" then -- admin and dumbid need to *always* work so we can login.
		local sitedown=srv.opts("sitedown")
		if sitedown then
			srv.set_mimetype("text/html; charset=UTF-8")
			srv.put(sitedown)
			return
		end
	end

	
	local lookup=srv.opts("map")
	local cmd
	local f
	local fm
	
	srv.url_slash_idx=4 -- let the caller know which part of the path called them
	srv.flavour=lookup[ "#flavour" ] -- sub modules can use this flavour to seperate themselves depending when called
	
	srv.domainport=srv.url_slash[3]
	if srv.domainport then srv.domain=str_split(":",srv.domainport)[1] end -- lose any port part
		
	srv.url_domain=table.concat({srv.url_slash[1],srv.url_slash[2],srv.url_slash[3]},"/")
	srv.url_base_local="/"
	srv.slash="/"
	local loop=true
	
--[[
	for i,v in ipairs( srv.opts("basedomains") or {} ) do
--			log(srv.url.."=="..srv.url_domain)
		v="."..v.."/"
		if srv.url:sub(-#v)==v then -- bare domain request?
			local aa=srv.url:sub(1,-(#v+1))
			aa=str_split("/",aa)
			aa=aa[#aa] -- remove http:// bit
			aa=str_split(".",aa)
			local ab={}
			for i=#aa,1,-1 do ab[#ab+1]=aa[i] end --reverse
			local ac=table.concat(ab,"/") or ""
			if not (ac=="" or ac=="www") then -- perform a redirect of base address only
				srv.redirect("http://www"..v..ac) -- to the www version
				return
			end
		end
	end
]]

	function build_tail(frm)
			local tail=""
			for i=frm , #srv.url_slash do
				if i~=frm then
					tail=tail.."/"
				end
				tail=tail..srv.url_slash[i]
			end
			if srv.query then
				tail=tail.."?"..srv.query
			end
			return tail
	end
	
	while loop do
			
		loop=false -- end loop unless we change our mind later
		
		local slash=srv.url_slash[ srv.url_slash_idx ]
		
		if slash then
		
			if slash=="" and not srv.query and not srv.url_slash[ srv.url_slash_idx+1 ]  then -- use a default index if all blank
				slash=lookup[ "#index" ] or ""
				if slash~="" then
					local ss=str_split("/",slash)
					for i,v in ipairs(ss) do
						srv.url_slash[ srv.url_slash_idx + i-1]=v
					end
					slash=srv.url_slash[ srv.url_slash_idx ]
				end
			end
		
			cmd=lookup[ slash ] -- lookup the cmd from its flavour
			
			if not cmd then -- missing slash
							
				cmd=lookup[ "#default" ] -- get default from current rule
				
			end
			
		else
		
			cmd=lookup[ "#default" ] -- no slash so get default from current rule
		
		end
		

		if type(cmd)=="table" then -- a table with sub rules
		
			loop=true -- run this loop again with a new lookup table
			
			lookup=cmd -- use this sub table for new lookup
			
			srv.url_slash_idx=srv.url_slash_idx+1 -- move the slash index along one
			srv.flavour=lookup[ "#flavour" ] -- get flavour of this table
		
			srv.url_base_local=srv.url_base_local..slash.."/"
			srv.slash=slash -- the last slash table we looked up
			
		elseif type(cmd)=="string" then -- a string so require that module and use its serv func

--log("requiring "..cmd)		
			local m=require(cmd) -- get module, this may load many other modules files at this point
			
			f=m.serv -- get function to call
			
		end
		
		srv.hashopts=lookup[ "#opts" ] or {}
			
		if lookup[ "#redirect" ] then -- redirect only
			srv.redirect( lookup[ "#redirect" ] .. build_tail( srv.url_slash_idx ) )
			return
		end
	end
	
	if not f then f=serv_fail end -- default

	srv.url_base=srv.url_domain..srv.url_base_local
	
	if not lookup[ "#nolimit" ] then -- can just disable rate limit for a url, eg the thumbcache
		local allow,tab=iplog.ratelimit(srv.ip)
		srv.iplog=tab -- iplog info
		if not allow then
			return srv.exit(429) -- drop request
		end
	end

	f(srv) -- handle this base url
	
end



--is it safe to accept data for this url from this referer?
function check_referer(srv,url,referer)

	if not url then
		-- by default just check domain of default referer
		local a1=str_split("/",srv.url_base or "")
		for i=#a1,4,-1 do a1[i]=nil end -- remove everything after the domain
		url=table.concat(a1,"/")
	end

	referer=referer or srv.headers.referer -- use referer from header

	if string.sub(referer,1,#url)==url then return true end

	return false
end



if not ngx then

-- step through all modules used in opts and make sure they have been required

	function require_all()


		if require_all_done then return end
		require_all_done=true

	log("require all mods")

		for i=1,1 do -- live startup can be a bit squify this repeat may help the files get found?
		
			for n,v in pairs(opts.mods) do
				if type(n)=="string" then
					local m,err=pcall(require,n)
	if not m then
		log("require "..i.." failed on mod "..n.."\n"..(err or ""))
	end
				end
			end
			
		end
		
	end

	require_all_done=false
	require_all()
end


