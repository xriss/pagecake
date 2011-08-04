local opts=require("opts") -- setup global opts table full of options and overides

local os=os
local dat=require("wetgenes.aelua.data")
local cache=require("wetgenes.aelua.cache")
local fetch=require("wetgenes.aelua.fetch")
local users=require("wetgenes.aelua.users")

local wet_string=require("wetgenes.string")
local str_split=wet_string.str_split
local serialize=wet_string.serialize

local iplog=require("wetgenes.aelua.iplog")

local table=table
local string=string
local type=type
local require=require
local ipairs=ipairs
local pairs=pairs
local pcall=pcall

module("base.basic")

local log=require("wetgenes.aelua.log").log -- grab the func from the package

-----------------------------------------------------------------------------
--
-- an error response
--
-----------------------------------------------------------------------------
function serv_fail(srv)

	srv.set_mimetype("text/html; charset=UTF-8")
	srv.put([[
	
PAGE MISSING<br/>
<br/>
<a href="/">return to the homepage?</a><br/>

]])

end

-----------------------------------------------------------------------------
--
-- the main serv function, named the same as the file it is in
--
-----------------------------------------------------------------------------
function serv(srv)

	srv.check_referer=check_referer

dat.countzero()
cache.countzero()
fetch.countzero()

	srv.clock=os.clock() -- a relative time we started at
	srv.time=os.time() -- the absolute time we started

	srv.url_slash=str_split("/",srv.url) -- break the input url
	srv.crumbs={} -- for crumbs based navigation 

--[[
		if srv.url_slash[4]=="admin" and srv.url_slash[5]=="clearmemcache" then
			srv.put("MEMCACHE CLEARED")
			cache.clear(srv)
			return
		end
]]

	local guser=users.get_google_user() -- google handles its own login
	if guser and guser.admin then -- trigger any special preadmin codes?


	else -- only non admins get rate limited

		local allow,tab=iplog.ratelimit(srv.ip)
		srv.iplog=tab -- iplog info
		if not allow then srv.put("RATELIMITED") return end -- drop request

	end

	
	local lookup=opts.map
	local cmd
	local f
	
	srv.url_slash_idx=4 -- let the caller know which part of the path called them
	srv.flavour=lookup[ "#flavour" ] -- sub modules can use this flavour to seperate themselves depending when called
	
	srv.domainport=srv.url_slash[3]
	if srv.domainport then srv.domain=str_split(":",srv.domainport)[1] end -- lose any port part
		
	srv.url_domain=table.concat({srv.url_slash[1],srv.url_slash[2],srv.url_slash[3]},"/")
	srv.url_local="/"
	srv.slash="/"
	local loop=true
	
	if opts.basedomains then
		for i,v in ipairs(opts.basedomains) do
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
	end

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
		
			srv.url_local=srv.url_local..slash.."/"
			srv.slash=slash -- the last slash table we looked up
			
		elseif type(cmd)=="string" then -- a string so require that module and use its serv func
		
			local m=require(cmd) -- get module, this may load many other modules files at this point
			
			f=m.serv -- get function to call
			
		end
		
		srv.opts=lookup[ "#opts" ] or {}
			
		if lookup[ "#redirect" ] then -- redirect only
			srv.redirect( lookup[ "#redirect" ] .. build_tail( srv.url_slash_idx ) )
			return
		end
	end
	
	if not f then f=serv_fail end -- default

	srv.url_base=srv.url_domain..srv.url_local
	
	f(srv) -- handle this base url
	
end



--is it safe to accept data for this url from this referer?
function check_referer(referer,url)

	-- for unknown reasons the port bit goes missing sometimes on debug servers so remove it...
	function remove_port(a)
		local a1=str_split("/",a or "")
		local a2=str_split(":",a1[3] or "")
		a1[3]=a2[1]
		return table.concat(a1,"/")
	end

	referer=remove_port(referer)
	url=remove_port(url)
	
--log(referer.."=="..url )

	if string.sub(referer,1,string.len(url))==url then return true end

	return false
end


require_all_done=false
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


require_all()



