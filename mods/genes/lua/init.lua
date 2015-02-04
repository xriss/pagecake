-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local lash=require("lash")

local wet_html=require("wetgenes.html")

local sys=require("wetgenes.www.any.sys")

--local dat=require("wetgenes.www.any.data")

--local user=require("wetgenes.www.any.user")

local img=require("wetgenes.www.any.img")

local log=require("wetgenes.www.any.log").log -- grab the func from the package

local iplog=require("wetgenes.www.any.iplog")

local wstr=require("wetgenes.string")
local str_split=wstr.str_split
local serialize=wstr.serialize
local macro_replace=wstr.macro_replace

local json=require("wetgenes.json")

local waka=require("waka")

local cache=require("wetgenes.www.any.cache")
local mail=require("wetgenes.www.any.mail")


local clean_username=function(s)
	local r=s or ""
	r=r:gsub("[^0-9a-zA-Z]+", "_" ) -- only allow numbers/letters in usernames, everything else becomes a _
	r=r:gsub("[_]+", "_" ) -- do not allow multiple _ in usernames
	if r:sub(1,1)=="_" then r=r:sub(2) end -- do not allow starting _
	if r:sub(-1)=="_" then r=r:sub(1,-2) end -- do not allow ending _
	return r
end

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

local qreplace=function(q,a)
	return q:gsub("$(%d+)",function(v)
		local t=a[tonumber(v) or 0]
		if     type(t)=="number" then
			return tostring(t)
		elseif type(t)=="string" then
			return ngx.quote_sql_str(t)
		else
			return "NULL"
		end
	end)
end

local query=function(db,q,...)
	local a={...}
	local res, err, errno, sqlstate = db:query(qreplace(q,a))
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

	if     cmd=="avatar" then
		serv_avatar(srv)
	elseif cmd=="user" then
		serv_user(srv)
	end
end

-----------------------------------------------------------------------------
--
-- api to create / login / update a WETGENES user and user password
--
-- need to be careful not to leak user info here and to slow down any
-- attacks
--
-----------------------------------------------------------------------------
function serv_user(srv)

	local put_json=function(j)
		srv.set_header("Access-Control-Allow-Origin","*")
		srv.set_mimetype("application/json; charset=UTF-8")
		srv.put(json.encode(j) or "{}")
	end

	local cmd=srv.url_slash[srv.url_slash_idx+1]

	if     cmd=="create" then

		if not srv.vars["name"] then
			return put_json{error="name is missing"}
		end

		if not srv.vars["pass"] then
			return put_json{error="pass is missing"}
		end

		if not srv.vars["email"] then
			return put_json{error="email is missing"}
		end


		local name=clean_username(srv.vars["name"])
		local pass=srv.vars["pass"]
		local email=srv.vars["email"]
		
		if name~=srv.vars["name"] then
			return put_json{error="name is invalid",name=name}
		end

		if #name<3 then
			return put_json{error="name is too short",name=name}
		end

		if #name>30 then
			return put_json{error="name is too long",name=name}
		end

		if #pass<3 then
			return put_json{error="pass is too short"}
		end

		local db = assert(connect(srv))	
	
		local user=assert(query(db,[[
			select * from fud26_users
			where login=$1 limit 1]],name
		))[1]

		if user then
			return put_json{error="name is already taken",name=name}
		end

		iplog.ratelimit(srv.ip,10)	-- only slow down fishing of this API for emails, not choosing a valid name
		
		local user=assert(query(db,[[
			select * from fud26_users
			where email=$1 limit 1]],email
		))[1]

		if user then
			return put_json{error="email is already taken",email=email}
		end

-- create a half hour secret token, which can be mailed or smsed etc
-- to confirm that you are the one who owns this identity
-- once you return we consider that email/phone valid

		local token=sys.md5( "signup"..(srv.ip)..math.random()..os.time() )
		cache.put(srv,"genes_ip_token="..srv.ip , json.encode{
			token=token,
			name=name,
			pass=pass,
			email=email,
			command="create",
			time=os.time(),
			} , 60*30 )

		local tokenurl="http://"..srv.domainport.."/js/genes/join/join.html?token="..token
		local domain=srv.domain
		mail.send{
			from="ignoreme@"..domain,
			to={email,"krissd@gmail.com"}, -- send to self as log
			subject="Please confirm this account creation at "..domain.." from "..srv.ip,
			body=[[
Why hello there,


Someone from ]]..srv.ip..[[ is trying to create an account at ]]..domain..[[ using this email address ( ]]..email..[[ ).

If this was not you then all you have to do to cancel the request is ignore this email.


Your token is : ]]..token..[[ bound to ]]..srv.ip..[[

To complete this account creation please visit the following url within the next 30 minutes.

]]..tokenurl..[[ 

Thank you for your cooperation.


				]],
			}

log("CREATE USER TOKEN = "..token)

		return put_json{token="sent to "..email}

	elseif cmd=="token" then

		if not srv.vars["token"] then
			return put_json{error="token is missing"}
		end

		local token=srv.vars["token"]

		local d=cache.get(srv,"genes_ip_token="..srv.ip) -- A hacker can only fish for data sent from their IP
		if not d then
			return put_json{error="invalid token"} -- generic error, do not leak info
		end
		d=json.decode(d)
		if d.token~=token then
			return put_json{error="invalid token"} -- generic error, do not leak info
		end
		if (d.time+(60*30))<os.time() then
			return put_json{error="invalid token"} -- generic error, do not leak info
		end
		cache.del(srv,"genes_ip_token="..srv.ip) -- Token can only be used once, so delete it now

-- so at this point we consider the email confirmed and can create or update a user from the cached data

		if d.command=="update" then -- modify a users, eg new password

			local db = assert(connect(srv))

			local name=clean_username(d.name)
			local pass=d.pass
			local email=d.email
			local salt=token:sub(1,10)
			local passhash=lash.SHA1.string2hex( salt .. lash.SHA1.string2hex(pass) )

			local user=assert(query(db,[[
				select * from fud26_users
				where email=$1 limit 1]],email
			))[1]
			if not user then
				return put_json{error="user does not exist"}
			end
			
			if name:lower()~=user.login:lower() then -- can *only* change case
				name=user.login
			end

			local done=assert(query(db,[[
				UPDATE fud26_users SET login=$1 , alias=$1 , name=$1 , passwd=$2 , salt=$3 WHERE id=$4]],name,passhash,salt,tonumber(user.id)
			))
			local affected_rows=done and done.affected_rows
			if affected_rows~=1 then
				return put_json{error="failed to update user",name=name,email=email}
			end

			return put_json{command="update",name=name,email=email}
			
		elseif d.command=="create" then -- new user

			local db = assert(connect(srv))
			
			local name=clean_username(d.name)
			local pass=d.pass
			local email=d.email
			local salt=token:sub(1,10)
			local passhash=lash.SHA1.string2hex( salt .. lash.SHA1.string2hex(pass) )
			
			-- check user and email again before we try and create a new user
			local user=assert(query(db,[[
				select * from fud26_users
				where login=$1 limit 1]],name
			))[1]
			if user then
				return put_json{error="name is already taken",name=name}
			end		
			local user=assert(query(db,[[
				select * from fud26_users
				where email=$1 limit 1]],email
			))[1]
			if user then
				return put_json{error="email is already taken",email=email}
			end
		
			local done=assert(query(db,[[
				INSERT INTO fud26_users (login,alias,name,email,passwd,salt,join_date,registration_ip,users_opt) VALUES ( $1,$1,$1,$2,$3,$4,$5,$6,$7)]],name,email,passhash,salt,os.time(),srv.ip,
				4+16+32+128+256+512+2048+4096+8192+16384+131072+4194304
			))
			local userid=done and done.insert_id
			if not userid then
				return put_json{error="failed to create user"}
			end
					
			return put_json({command="create",id=userid,name=name,email=email}) -- success
			
		end
		
	elseif cmd=="login" then

		if not srv.vars["name"] then
			return put_json{error="name is missing"}
		end

		if not srv.vars["pass"] then
			return put_json{error="pass is missing"}
		end

		local name=srv.vars["name"]
		local email=srv.vars["email"] or srv.vars["name"]
		local pass=srv.vars["pass"]

		iplog.ratelimit(srv.ip,10)	-- slow down fishing of this API
		local db = assert(connect(srv))	

		local user=assert(query(db,[[
			select * from fud26_users
			where login=$1 OR email=$2 or login=$2 OR email=$1 limit 1]],name,email
		))[1]

		if user then

			local passOK=false -- set to true if the password is correct
			if type(user.salt)=="string" then
			 	passOK = ( user.passwd == lash.SHA1.string2hex( user.salt .. lash.SHA1.string2hex(pass) ) )
			else
				passOK = ( user.passwd == lash.MD5.string2hex(pass) )
			end

			if passOK then -- authentication is a success, create a session and return it

				local session

				assert(query(db,[[
					DELETE FROM fud26_ses WHERE user_id=$1]],user.id
				))
				
				repeat
					session=lash.MD5.string2hex(user.id..user.login..user.email..os.time())
					local session_id=assert(query(db,[[
						INSERT INTO fud26_ses (ses_id, time_sec, sys_id, user_id,ip_addr) VALUES ($1,$2,$3,$4,$5);
						]],session,os.time(),"",user.id,srv.ip
					))
				until session_id -- until session does not clash

				return put_json{session=session,name=user.login,email=user.email} -- return session (ip locked)
				-- for this session to work on the forum then multiple logins must be allowed.
			end
			
			return put_json{error="name and pass do not match"} -- generic error, do not leak email connection
		else
			return put_json{error="name and pass do not match"} -- generic error, do not leak email connection
		end

		return put_json{error="FAIL"}

	elseif cmd=="update" then

		if not srv.vars["pass"] then
			return put_json{error="pass is missing"}
		end

		if not srv.vars["email"] then
			return put_json{error="email is missing"}
		end
		
		local name=clean_username(srv.vars["name"] or srv.vars["email"]) -- optional, may be ignored
		local pass=srv.vars["pass"]
		local email=srv.vars["email"]

		if #pass<3 then
			return put_json{error="pass is too short"}
		end
		
		iplog.ratelimit(srv.ip,100)	-- really slow down abuse of this API
		
		local db = assert(connect(srv))	
	
		local user=assert(query(db,[[
			select * from fud26_users
			where login=$1 OR email=$2 limit 1]],name,email
		))[1]
		if not user then
			return put_json{error="user does not exist"}
		end
		
		email=user.email -- use this official email

-- create a half hour secret token, which can be mailed or smsed etc
-- to confirm that you are the one who owns this identity
-- once you return we consider that email/phone valid

		local token=sys.md5( "signup"..(srv.ip)..math.random()..os.time() )
		cache.put(srv,"genes_ip_token="..srv.ip , json.encode{
			token=token,
			name=name,
			pass=pass,
			email=email,
			command="update",
			time=os.time(),
			} , 60*30 )

		local tokenurl="http://"..srv.domainport.."/js/genes/join/join.html?token="..token
		local domain=srv.domain
		mail.send{
			from="ignoreme@"..domain,
			to=email,
			subject="Please confirm account modification of "..name.." at "..domain.." from "..srv.ip,
			body=[[
Why hello there,


Someone from ]]..srv.ip..[[ is trying to change the password of your account at ]]..domain..[[ using this email address ( ]]..email..[[ ).

This has triggered a confirmation email to you as a verification step.

If this was not you then all you have to do to cancel the request is ignore this email.


Your token is : ]]..token..[[ bound to ]]..srv.ip..[[

To complete this account creation please visit the following url within the next 30 minutes.

]]..tokenurl..[[ 

Thank you for your cooperation.


				]],
			}

log("UPDATE USER TOKEN = "..token)

		return put_json{token="sent to your registered email address"}

	elseif cmd=="session" then

		if not srv.vars["session"] then
			return put_json{error="session is missing"}
		end

		local db = assert(connect(srv))	

		local session=assert(query(db,[[
			SELECT * FROM fud26_ses WHERE ses_id=$1 limit 1]],srv.vars["session"]
		))[1]

		if not session then return put_json{error="invalid session"} end

		local ip=srv.vars["ip"] or srv.ip -- can check an alternative IP against the session
		
		if session.ip_addr~=ip then
			iplog.ratelimit(srv.ip,10)	-- slow down abuse of this API
			return put_json{error="invalid session"}
		end

		local user=assert(query(db,[[
			select * from fud26_users
			where id=$1 limit 1]],session.user_id
		))[1]

		if not user then return put_json{error="invalid session"} end

		return put_json{name=user.login,id=user.id}

	end
end

-----------------------------------------------------------------------------
--
-- redirect to an image/avatar for this user name/id
--
-- any problems and we redirect to a default avatar
--
-----------------------------------------------------------------------------
function serv_avatar(srv)

	local name=srv.url_slash[srv.url_slash_idx+1] or ""
	
	local db = assert(connect(srv))
	
	local res
	
	if name:sub(1,1)=="$" then -- by number
		local num = tonumber(name:sub(2) or 0 ) or 0
		res=assert(query(db,[[
			select id,login,avatar_loc from fud26_users
			where id=$1 limit 1]],num
		))[1]
	else -- by login name
		res=assert(query(db,[[
			select id,login,avatar_loc from fud26_users
			where login=$1 limit 1]],name
		))[1]
	end
		
	if res and type(res.avatar_loc) == "string"then
		local url=string.gmatch(res.avatar_loc,"src=\"([^\"]*)")()
		if url then
			url=string.gsub(url,"www.wetgenes.com","wet.genes.pw") -- hack to new domain so we can remove old server sometime
			return ngx.redirect(url)
		end
	end
	
	return ngx.redirect("http://wet.genes.pw/forum/images/custom_avatars/12.png")
end
	
