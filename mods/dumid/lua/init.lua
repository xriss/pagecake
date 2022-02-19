-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require



local wet_html=require("wetgenes.html")

local sys=require("wetgenes.www.any.sys")

local json=require("wetgenes.json")
local dat=require("wetgenes.www.any.data")

local users=require("wetgenes.www.any.users")

local mail=require("wetgenes.www.any.mail")
local fetch=require("wetgenes.www.any.fetch")
local cache=require("wetgenes.www.any.cache")
local iplog=require("wetgenes.www.any.iplog")

local img=require("wetgenes.www.any.img")

local log=require("wetgenes.www.any.log").log -- grab the func from the package

local wstr=require("wetgenes.string")
local wet_string=wstr
local str_split=wet_string.str_split
local serialize=wet_string.serialize

local wxml=require("wetgenes.simpxml")


local opts=require("opts")





-- require all the module sub parts
local html=require("dumid.html")

local d_users=require("dumid.users")
local d_sess =require("dumid.sess")
local d_acts =require("dumid.acts")
local d_nags =require("dumid.nags")


local oauth=require("wetgenes.www.any.oauth")



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
module("dumid")
local function make_put(srv)
	return function(a,b)
		b=b or {}
		b.srv=srv
		srv.put(wet_html.get(html,a,b))
	end
end
-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-- do not cache the srv param localy, make sure it cascades around
--
-----------------------------------------------------------------------------
function serv(srv)
local sess,user=d_sess.get_viewer_session(srv)
local put=make_put(srv)

	local cmd=srv.url_slash[ srv.url_slash_idx+0 ]
	
-- functions for each special command
	local cmds={
		login=		serv_login,
		logout=		serv_logout,
		callback=	serv_callback,
		nag=		serv_nag,
		token=		serv_token,
	}
	local f=cmds[ string.lower(cmd or "") ]
	if f then return f(srv) end
	
-- no command given
-- work out what we should do

	return serv_login(srv) -- try login by default?
		
end

-----------------------------------------------------------------------------
--
-- enter some more details
--
-----------------------------------------------------------------------------
function serv_token(srv)
local put=make_put(srv)

	local cmd=srv.url_slash[ srv.url_slash_idx+0 ]
	local dat=srv.url_slash[ srv.url_slash_idx+1 ] or ""

	local continue="/"
	if srv.gets.continue then continue=srv.gets.continue end -- where we wish to end up


	if dat=="send" then -- send a token
	
		local email=srv.gets.email
		
		if email and (email:match("[A-Za-z0-9%.%%%+%-]+@[A-Za-z0-9%.%%%+%-]+%.%w%w%w?%w?")) then

			local token=sys.md5( "login"..(srv.ip)..math.random()..os.time() )
			local tokenurl=srv.url_base.."token/check?token="..token
			
			local domain=srv.url_slash[3]
			domain=domain:gsub(":.*$","")


			cache.put(srv,"dumid_ip_token="..srv.ip , json.encode{
				domain=domain,
				token=token,
				time=os.time(),
				email=email,
				continue=continue,
				} , 60*30 )

			mail.send{
				from="dumid@"..domain,
				to=email,
				subject="dumid login request for "..domain.." from "..srv.ip,
				body=[[
Why hello there,

Someone from ]]..srv.ip..[[ has requested a login token for ]]..domain..[[ using this email address ( ]]..email..[[ ).

if this was not you then I am really sorry! Please just ignore this email.


Your login token is : ]]..token..[[ 

To complete this login please visit the following url within the next 30 minutes.

]]..tokenurl..[[ 

Thank you for your cooperation.


				]],
			}

			iplog.ratelimit(srv.ip,50)	-- allow at max only 4 emails per minute per ip (client)

			return srv.redirect(srv.url_base.."token/check")

		else
			srv.redirect(srv.url_base.."login/email/?error=invalid_email&continue="..wet_html.url_esc(continue))
		end

	elseif dat=="check" then -- check a token
	
		local d=cache.get(srv,"dumid_ip_token="..srv.ip)
		if d then
--			cache.del(srv,"dumid_ip_token="..srv.ip)

			d=json.decode(d)
		end
	
		local token=srv.gets.token or ""
	
		if d and token and d.token==token then -- good token
			cache.del(srv,"dumid_ip_token="..srv.ip)

--log(wstr.dump(d))

			local name=d.email
			name=str_split("@",name)[1] -- get the left bit of any email
			name=string.sub(name,1,32) -- limit length

			return perform_login(srv,{
				flavour="email",
				name=name,
				email=d.email,
				info={email=d.email},
				continue=d.continue,
			})
		end
	
		srv.set_mimetype("text/html; charset=UTF-8")
		put("dumid_header",{})
		put("dumid_token",{continue=continue})
		put("dumid_footer",{})

	end


end

-----------------------------------------------------------------------------
--
-- perform a tye of login, probably an offsite redirect
--
-----------------------------------------------------------------------------
function serv_login(srv)
local put=make_put(srv)

	local cmd=srv.url_slash[ srv.url_slash_idx+0 ]
	local dat=srv.url_slash[ srv.url_slash_idx+1 ] or ""

	local continue="/"
	if srv.gets.continue then continue=srv.gets.continue end -- where we wish to end up
	
--build generic openid query string

local openidquery="openid.ns=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0&"..
"openid.mode=checkid_setup&"..
"openid.identity=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&"..
"openid.claimed_id=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&"..
"openid.ns.sreg=http%3A%2F%2Fopenid.net%2Fextensions%2Fsreg%2F1.1&"..
"openid.return_to="..wet_html.url_esc(srv.url_base.."callback/"..dat.."/?continue="..wet_html.url_esc(continue)).."&"..
"openid.realm="..wet_html.url_esc("http://"..srv.url_slash[3].."/")


	if dat=="jedi" then

		srv.set_mimetype("text/html; charset=UTF-8")
		put("dumid_header",{})
		put("dumid_jedi",{continue=continue})
		put("dumid_footer",{})
		return
		
	elseif dat=="email" then
	
--[[
		mail.send{
			from="notkriss@xixs.com",
			to="kriss@xixs.com",
			subject="hello",
			body="this\nis\na\ntest\n",
		}
		iplog.ratelimit(srv.ip,25)
]]
--		return srv.redirect(srv.url_base.."enter/"..dat.."/?continue="..wet_html.url_esc(continue))
	
		srv.set_mimetype("text/html; charset=UTF-8")
		put("dumid_header",{})
		put("dumid_email",{continue=continue})
		put("dumid_footer",{})

		
		return
		
	elseif dat=="google" then

		openidquery=openidquery..
		"&openid.ns.ax="..wet_html.url_esc("http://openid.net/srv/ax/1.0")..
		"&openid.ax.mode="..("fetch_request")..
		"&openid.ax.required="..("email,firstname,lastname,userid")..
		"&openid.ax.type.email=http://axschema.org/contact/email"..
		"&openid.ax.type.firstname=http://axschema.org/namePerson/first"..
		"&openid.ax.type.lastname=http://axschema.org/namePerson/last"..
		"&openid.ax.type.userid=http://schemas.openid.net/ax/api/user_id"..

--		"&openid.ns.ext2=http://specs.openid.net/extensions/oauth/1.0"..
--		"&openid.ext2.consumer="..(srv.url_slash[3])..
--		"&openid.ext2.scope=https://www.googleapis.com/auth/userinfo.profile"..

		""

		return srv.redirect("https://accounts.google.com/o/openid2/auth?"..openidquery)
		
	elseif dat=="steam" then

		return srv.redirect("https://steamcommunity.com/openid/login?"..openidquery)

	elseif dat=="wetgenes" then
	
		local callback=srv.url_base.."callback/wetgenes/?continue="..wet_html.url_esc(continue)
		local tld="com"
--		if srv.url_slash[3]=="host.local:8080" then tld="local" end
		return srv.redirect("http://lua.wetgenes."..tld.."/dumid.lua?continue="..wet_html.url_esc(callback))
		
	elseif dat=="genes" then
	
		local callback=srv.url_base.."callback/genes/?continue="..wet_html.url_esc(continue)
		return srv.redirect("http://api.wetgenes.com:1408/js/genes/join/join.html?dumid="..wet_html.url_esc(callback))

	elseif dat=="facebook" then
	
		local callback=srv.url_base.."callback/facebook/"..wet_html.url_esc(continue)
		local url="https://www.facebook.com/dialog/oauth?client_id="..
			(srv.opts("facebook","id")or"").."&scope=email,offline_access&redirect_uri="..wet_html.url_esc(callback)

--log(continue)
--log(callback)
--log(url)

		return srv.redirect(url)
		
--	elseif dat=="google" then
	
--		local callback=srv.url_base.."callback/google/?continue="..wet_html.url_esc(continue)
--		return srv.redirect(users.login_url(callback))
		
	elseif dat=="twitter" then
	
		local callback=srv.url_base.."callback/twitter/?continue="..wet_html.url_esc(continue)
		local baseurl="https://twitter.com/oauth/request_token"

		local vars={}
		vars.oauth_timestamp , vars.oauth_nonce = oauth.time_nonce("sekrit")
		vars.oauth_consumer_key = srv.opts("twitter","key")
		vars.oauth_signature_method="HMAC-SHA1"
		vars.oauth_version="1.0"
		vars.oauth_callback=callback
	
		local k,q = oauth.build(vars,{post="GET",url=baseurl,api_secret=srv.opts("twitter","secret")})
		
		local got=fetch.get(baseurl.."?"..q) -- get from internets		
		local gots=oauth.decode(got.body)
		
		if gots.oauth_token then
			cache.put(srv,"oauth_token="..gots.oauth_token,got.body) -- save data for a little while
			return srv.redirect("https://twitter.com/oauth/authorize?oauth_token="..gots.oauth_token)
		end
		
	end

	srv.set_mimetype("text/html; charset=UTF-8")
	put("dumid_header",{})
	put("dumid_choose",{continue=continue,twitter=srv.opts("twitter","key"),facebook=srv.opts("facebook","id")})
	put("dumid_footer",{})
	
end



-----------------------------------------------------------------------------
--
-- callback part, after some magical login elsewhere, build a session then continue
--
-----------------------------------------------------------------------------
function serv_callback(srv)
local put=make_put(srv)

	local cmd= srv.url_slash[ srv.url_slash_idx+0 ]
	local data=srv.url_slash[ srv.url_slash_idx+1 ]

	local continue="/"
	if srv.url_slash[ srv.url_slash_idx+2 ] then
		local t={}
		for i=srv.url_slash_idx+2 , #srv.url_slash do
			t[#t+1]=srv.url_slash[i]
		end
		continue=table.concat(t,"/")
	end
	if srv.gets.continue then continue=srv.gets.continue end -- where we wish to end up


	if continue:sub(1,7) == "http://" then -- this is an ok continue url
	else
		if continue:sub(1,6) == "http:/" then -- facebook? fucks up the redirect url, which is nice, this unfucks it
			continue="http://"..continue:sub(7)
		end
	end

--log(continue)
	
	local user
	local sess
	local email
	local name
	local flavour
	local admin=false
	local authentication={} -- store any values we wish to cache here
	local info={} -- extra data we may have also grabed from authenticator
	
	local checkopenid=function(url)

		local a={}

		for i,v in pairs( srv.gets ) do
			a[i]=(v)
		end
		
		a["openid.mode"]="check_authentication"

		local ai={}
		for i,v in pairs( a ) do
			ai[#ai+1]=i.."="..oauth.esc(v)
		end
		
		local arg=table.concat(ai,"&")

		local got=fetch.get(url.."?"..arg) -- ask for confirmation from server

		if got and type(got.body=="string") then
		
			if string.find(got.body,"is_valid:true",1,true) then -- if all data sent is valid 
			
				return a
				
			end
			
		end
		
	end
	
	if data=="google" then
	
		local valid=checkopenid("https://www.google.com/accounts/o8/ud")

		if valid then

--log( wstr.dump(valid) )

--	'guidedhelpid="profile_photo"><img src="(^\")"'

--log( wstr.dump(hax) )

--	local icon=nil
--	local hax=fetch.get("https://plus.google.com/"..valid["openid.ext1.value.userid"].."/about")
--	if type(hax.body=="string") then
--		hax.body:gsub('guidedhelpid="profile_photo"><img src="([^"]+)', function(a,b) icon="http:"..a end , 1)
--	end
			
			


		if valid["openid.ext1.value.userid"] and valid["openid.ext1.value.email"] and valid["openid.ext1.value.firstname"] and valid["openid.ext1.value.lastname"] then

			info={ gid=valid["openid.ext1.value.userid"] , email=valid["openid.ext1.value.email"] }
			email=info.gid .. "@id.google.com" -- hide real email slightly
			name=valid["openid.ext1.value.firstname"].." "..valid["openid.ext1.value.lastname"]
			flavour="google"
			
		end
			
	end
		
	elseif data=="steam" then
	
		local valid=checkopenid("https://steamcommunity.com/openid/login")

		if valid then
		
			local id=valid["openid.claimed_id"]
			local i,j=string.find(id,"%d+$")
			if i and j then id=(string.sub(id,i,j)) else id=nil end

			if id then
				local dat=fetch.get("http://steamcommunity.com/profiles/"..id.."/?xml=1")
				local x=wxml.parse(dat.body)

				local steamid=wxml.descendent(x,"steamid")
				local realname=wxml.descendent(x,"realname")
				local avatar=wxml.descendent(x,"avatarfull")
				
				if steamid and avatar then

					name=steamid[1]
					email=id.."@id.steamcommunity.com"
					flavour="steam"
							
					authentication.steam={ -- all the steam info we should also keep track of
						name=steamid[1],
						id=id,
						avatar=avatar[1],
						}

				end

			end

		end

	elseif data=="genes" then

		if srv.gets.confirm then
			srv.set_cookie{name="fud_session",value=wet_html.url_esc(srv.gets.confirm),domain=srv.domain,path="/",live=os.time()+(60*60*24*28)}

			local s="http://api.wetgenes.com:1408/genes/user/session?session="..srv.gets.confirm.."&ip="..srv.ip
			local got=fetch.get(s) -- check the session for the ip talking to us (wont work on host.local)
			if got and type(got.body=="string") then
				got=json.decode(got.body)
				if got and got.id then -- we now know who they are
					name=got.name
					email=got.id.."@id.wetgenes.com"
					flavour="wetgenes"
				end
			end
		
		end

	elseif data=="wetgenes" then
	
		if srv.gets.confirm then

			if srv.gets.S then -- remember fud cookie
				srv.set_cookie{name="fud_session",value=wet_html.url_esc(srv.gets.S),domain=srv.domain,path="/",live=os.time()+(60*60*24*28)}		
			end

			local hash=wet_html.url_esc(srv.gets.confirm)
			
			local callback=srv.url_base.."callback/wetgenes/?continue="..wet_html.url_esc(continue)
			local tld="com"
			if srv.url_slash[3]=="host.local:8080" then tld="local" end
			local s="http://lua.wetgenes."..tld.."/dumid.lua?continue="..wet_html.url_esc(callback)
			
			local got=fetch.get(s.."&hash="..hash) -- ask for confirmation from server
			if got and type(got.body=="string") then
				got=json.decode(got.body)
				if got.id then -- we now know who they are
					name=got.name
					email=got.id.."@id.wetgenes.com"
					flavour="wetgenes"
				end
			end
		
		end
			
	elseif data=="facebook" then
			
		local fb_code=srv.gets.code
		assert(fb_code,"need facebook code")

-- use the code to get a token	
		local got=fetch.get("https://graph.facebook.com/oauth/access_token?client_id="..
			(srv.opts("facebook","id")or"").."&redirect_uri="..oauth.esc(srv.url).."&client_secret="..
			(srv.opts("facebook","secret")or"").."&code="..oauth.esc(fb_code))
		
		local fbtoken=oauth.decode(got.body)
		local token=fbtoken.access_token
		assert(token,"need facebook token")

-- fetch user information using this token
		local got=fetch.get("https://graph.facebook.com/me?access_token="..oauth.esc(token))

		if got.body then
			local fbuser=json.decode(got.body)

			if fbuser.id then
				email=fbuser.id .. "@id.facebook.com" -- hide real email slightly
				name=fbuser.name
				name=string.sub(name,1,32) -- limit length
				flavour="facebook"
			
				authentication.facebook={ -- all the facebook info we should also keep track of
					token=token,
					user=fbuser, -- save all user info
					}
					
				info={ email=fbuser.email }
					
			end
		end
		
--[[
	elseif data=="google" then
		local guser=users.get_google_user() -- google handles its own login
		if guser then -- google login OK
			email=guser.gid .. "@id.google.com" -- hide real email slightly
			name=guser.name
			name=str_split("@",name)[1] -- get the left bit of any email like name
			name=string.sub(name,1,32) -- limit length
			admin=guser.admin
			flavour="google"
			info={ gid=guser.gid , fid=guser.fid , email=guser.email }
		end
]]
	elseif data=="twitter" then

		local gots=cache.get(srv,"oauth_token="..srv.gets.oauth_token) -- recover data
		if gots then gots=oauth.decode(gots) else gots={} end -- decode it again
		
-- ok now we get to ask twitter for an actual username using this junk we have collected so far

		local baseurl="https://twitter.com/oauth/access_token"
		
		local vars={}
		vars.oauth_timestamp , vars.oauth_nonce = oauth.time_nonce("sekrit")
		vars.oauth_consumer_key = srv.opts("twitter","key")
		vars.oauth_signature_method="HMAC-SHA1"
		vars.oauth_version="1.0"
		vars.oauth_token=gots.oauth_token
		vars.oauth_verifier=srv.gets.oauth_verifier
	
		local k,q = oauth.build(vars,{post="GET",url=baseurl,
			api_secret=srv.opts("twitter","secret"),tok_secret=gots.oauth_token_secret})
		
		local got=fetch.get(baseurl.."?"..q) -- simple get from internets		
		local data=oauth.decode(got.body or "")
		
		if data.screen_name then -- we got a user

--log(wstr.dump(data))
		
			name=data.screen_name
			email=data.user_id.."@id.twitter.com"
			flavour="twitter"
					
			authentication.twitter={ -- all the twitter info we should also keep track of
				token=data.oauth_token,
				secret=data.oauth_token_secret,
				name=data.screen_name,
				id=data.user_id,
				}

-- fetch user info
				local baseurl="https://api.twitter.com/1.1/users/show.json"
				
				local vars={}
				vars.oauth_timestamp , vars.oauth_nonce = oauth.time_nonce("sekrit")
				vars.oauth_consumer_key = srv.opts("twitter","key")
				vars.oauth_signature_method="HMAC-SHA1"
				vars.oauth_version="1.0"
				vars.oauth_token=authentication.twitter.token
				vars.screen_name=authentication.twitter.name
			
				local k,q = oauth.build(vars,{post="GET",url=baseurl,
					api_secret=srv.opts("twitter","secret"),tok_secret=authentication.twitter.secret})
				
				local got=fetch.get(baseurl.."?"..q) -- simple get from internets		
--				local data=oauth.decode(got.body or "")

--log(wstr.dump(got.body))
				if got and got.body then
					local tmp=json.decode(got.body)
					if tmp then
						for i,v in pairs(tmp) do if type(v)~="string" and type(v)~="number" then tmp[i]=nil end end -- kill all the crap crap
						info=tmp
					end
				end
--log(wstr.dump(tmp))
		
		
		end
	
	end
	

	return perform_login(srv,{
		flavour=flavour,
		name=name,
		email=email,
		info=info,
		authentication=authentication,
		continue=continue,
	})
end


-----------------------------------------------------------------------------
--
-- login using the authenticated data in tab
--
-----------------------------------------------------------------------------
function perform_login(srv,tab)

	local user
	local admin

	if tab.email then -- try and load or create a new user by email

		if srv.opts("admin",tab.email) then admin=true end -- set admin flag to true for these users

		for retry=1,10 do -- get or create user in database
			
			local t=dat.begin()
			
			user=d_users.get(srv,tab.email:lower(),t) -- try and read a current user
			
			if not user then -- didnt get, so make and put a new user?
			
				user=d_users.fill(srv,nil,{userid=tab.email,name=tab.name,flavour=tab.flavour}) -- name can be nil, it will just be created from the userid
				if not d_users.put(srv,user,t) then user=nil end
			end
			
			if user then
				user.cache.name=tab.name -- update?
				user.cache.flavour=tab.flavour
				user.cache.authentication=user.cache.authentication or {} -- may need to create
				for i,v in pairs( tab.authentication or {} ) do -- remember any new special authentication values
					user.cache.authentication[i]=v
				end
			end
			
			user.cache.ip=srv.ip -- remember the last ip we logged in from
			user.cache.admin=admin
			user.cache.info=tab.info -- extra procesed info
			if tab.info and tab.info.email then user.cache.email=tab.info.email end -- real email if available
			if not d_users.put(srv,user,t) then user=nil end -- always write
			
			if user then -- things are looking good try a commit
				if t.commit() then break end -- success
			end
			
			t.rollback()	
		end
				
-- clear cache of the user
		if user then
			d_users.cache_fix(srv,d_users.cache_what(srv,user))
		end
	end
	
	if user then -- we got us a user now save it in a session
	
		-- remove all old sessions associated with this user?	
		d_sess.del(srv,user.cache.id)
	
		-- create a new session for this user
		local hash=sys.md5( "session"..(user.cache.ip)..math.random()..os.time() )

		local sess=d_sess.fill(srv,nil,{user=user,hash=hash})

		d_sess.put(srv,sess)

		if srv.gets.S then
			srv.set_cookie{name="fud_session",value=wet_html.url_esc(srv.gets.S),domain=srv.domain,path="/",live=os.time()+(60*60*24*28)}		
		end
		srv.set_cookie{name="wet_session",value=hash,domain=srv.domain,path="/",live=os.time()+(60*60*24*28)}
	end

	return srv.redirect( tab.continue )

end

-----------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------
function serv_logout(srv)
local sess,user=d_sess.get_viewer_session(srv)
local put=make_put(srv)

	local cmd=srv.url_slash[ srv.url_slash_idx+0 ]
	local data=srv.url_slash[ srv.url_slash_idx+1 ]

	local continue="/"
	if srv.gets.continue then continue=srv.gets.continue end -- where we wish to end up
	
	if user and data then
		if data==sess.key.id then -- simple permission check
			d_sess.del(srv,user.cache.id) -- kill all sessions
		end
	end

-- this logs you out of your gmail account, everywhere, which is anoying...
--	srv.redirect( users.logout_url(continue) )
	srv.redirect( continue )
	
end


-----------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------
function serv_nag(srv)
local sess,user=d_sess.get_viewer_session(srv)

	local continue --="/"
	if srv.gets.continue then continue=srv.gets.continue end -- where we wish to end up
	
	if srv.gets.nag and srv.gets.blanket then
		if sess.cache.nags[srv.gets.nag] then
			local nag=sess.cache.nags[srv.gets.nag]
			if srv.gets.blanket==tostring(nag.blanket) then -- security blanket check to delete the nag
				d_nags.delete(srv,sess,nag)
			end
		end
	end

	if continue then srv.redirect( continue ) end
	
end
