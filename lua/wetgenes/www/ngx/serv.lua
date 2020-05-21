--local g=require("global")

-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require


local log=print
local debug=require("debug")


local cache=require("wetgenes.www.ngx.cache")



local ngx=require("ngx")

-- does this overloading let us just use the socket module?
--[[
local socket=assert(require("socket"))
socket.tcp=ngx.socket.tcp
socket.udp=ngx.socket.udp
socket.connect=ngx.socket.connect
]]

module(...)
local _M=require(...)
package.loaded["wetgenes.www.any.serv"]=_M

function serv()
	local success=true
	xpcall(serv2,function(msg,lev)
		log( msg )
		log( debug.traceback() )
		success=false
	end)
	assert(success)
end

-- work out which is our vhost but do not do any more setup, returns srv
function serv_srv()

	local opts=require("opts")
	if opts.setup then opts.setup() end -- may need to in itialize stuff

	local srv=require("wetgenes.www.ngx.srv").new()
	ngx.ctx=srv -- this is out ctx
	
	for i,v in ipairs(opts.vhosts_map or {} ) do
		srv.vhost=v[2]
		if ngx.var.host:find(v[1],1,true) then break end
	end	
	
--	srv.spam=true -- spam test

	return srv
	
end

function serv2()

	local opts=require("opts")

	if opts.redirect_domains then
		local redir=opts.redirect_domains[ngx.var.host:lower()]
		if redir then
			local colonport=(ngx.var.server_port and ngx.var.server_port~="80") and (":"..ngx.var.server_port) or ""
			return ngx.redirect( ngx.var.scheme.."://"..redir..colonport..ngx.var.uri )
		end
	end
	
	local srv=serv_srv()

	local is_local=function()
		local begins_with=function(s,b) return s:sub(1,#b)==b end
		if srv.ip=="127.0.0.1" then return true end
		if begins_with(srv.ip,"10.42.") then return true end
		if begins_with(srv.ip,"192.168.") then return true end
		return false
	end

-- force redirect to a standard domain if it is set in opts

	local t=opts.vhosts[srv.vhost] or opts
	local domain=ngx.var.host:lower()
	if t.subdomain then -- allow subdomains
		local s,e=domain:find("^[^.]+%.") -- get subdomain
		if s then
			srv.subdomain=domain:sub(1,e-1) -- got a subdomain
			domain=domain:sub(e+1):lower()
		end
	end

	if t.domain and t.domain~=domain then
		if not t.domains[domain] then -- bad base domain
			if srv.subdomain then -- maybe not a subdomain, put it back and try again
				domain=srv.subdomain.."."..domain
				srv.subdomain=nil
			end
			local sd=""
			if domain:sub(-#t.domain)==t.domain then -- push subdomains of the valid domain into the start of the url when we redirect
				sd="/"..domain:sub(1,-#t.domain-2)
				if sd=="/www" then sd="" end -- ignore default www
			end
			if not t.domains[domain] then -- redirect to a standard base domain
				if not is_local() then -- do not redirect if viewing from a local domain ip
log("REDIRECT:"..t.domain.." ("..sd..") FROM "..ngx.var.host)
					local colonport=(ngx.var.server_port and ngx.var.server_port~="80") and (":"..ngx.var.server_port) or ""
					ngx.redirect( ngx.var.scheme.."://"..t.domain..colonport..sd..ngx.var.uri )
				end
			end
		end
	end
--log("domain",":",domain,":",srv.subdomain)
	
	
--	if srv.vhost then log("VHOST = "..srv.vhost) end
	
	srv.opts=function(...)
		local t=opts.vhosts[srv.vhost] or opts
		for i,v in ipairs({...}) do
			t=t and t[v]
		end
		return t
	end
	
	-- shove this basic functions into the global name space
	-- they will work with the opts to serv this app as needed
	local basic=require("base.basic")
	

	if not srv.opts().require_all_done then
		srv.opts().require_all_done=true

--		log("require all mods")

		for n,v in pairs(opts.mods) do
			if type(n)=="string" then
--				log("require "..n)
--				local m,err=pcall(require,n)
				local m,err=xpcall(function() return require(n) end,function(msg)
					log( "require "..n.." failed\n"..tostring(msg) )
					log( debug.traceback() )
				end)
				
				if not m then
				log("require failed on mod "..tostring(n).."\n"..(err or ""))
				end
			end
		end
		
	end

	
	basic.serv(srv)

end
