-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local log=require("wetgenes.www.ngx.log").log

local ngx=ngx

module("opts")
local opts=require("opts")

vhosts_map={
	{"local",		"genes",		"host.local",		},			-- test this domain when on localhost or host.local
	{"genes",		"genes",		"wetgenes.com",		},			-- any domain with genes in it
}
vhosts={}
for i,v in ipairs(vhosts_map) do
	local t={}
--	setmetatable(t,{__index=opts})
	vhosts[ v[2] ]=t
	
	t.domain=v[3] -- force redirect to this domain
end


local ae_opts=require("wetgenes.www.any.opts")
local dat=require("wetgenes.www.any.data")
local cache=require("wetgenes.www.any.cache")

local wet_string=require("wetgenes.string")
local wstr=wet_string
local str_split=wet_string.str_split
local serialize=wet_string.serialize


local function default_vars(v)

--	v.bootstrapp_version=20130201 -- hand bump to todays date on release

--	v.mail={}
	v.mail_from="spam@wetgenes.com"
	v.mail_admin={"notshi@gmail.com","krissd@gmail.com",}

--	v.urls={}

--	v.head={} -- stuff to inject into the html header
--	v.head.favicon="/favicon.ico" -- the favicon
--	v.head.extra_css={} -- more css links
--	v.head.extra_js={} -- more js links
--	v.head.extra={} -- more header junk

	-- need some admin users or we will get nowhere
	v.admin={
		["2@id.wetgenes.com"]=true,
		["14@id.wetgenes.com"]=true,
	}
-- possible user ids are, these are unique number ids I'm afraid so its not always easy to get the numbers from the sites

-- ?@id.wetgenes.com		-- forum id
-- ?@id.facebook.com		-- internal user id
-- ?@id.twitter.com			-- internal twitter id
-- ?@id.google.com			-- https://plus.google.com/?/about
-- ?@id.steamcommunity.com	-- http://steamcommunity.com/profiles/?


end

default_vars(opts)

-- look through the mods and save the #opts of each mod used, this is for easy lookup in mod code
-- add assumes you are only using each mod *once* per site
local function find_mods(map)
	local mods={}
	-- find each mod
	for i,v in pairs(map) do
		if type(v)=="table" then
			local name=v["#default"]
			if name then
				mods[name]=v["#opts"] or {}
			end
		end
	end
	return mods
end

-- add a mapping to the map table
local function add_map(map,name,tab)

	local mapname=name
	if type(tab)=="string" then
		mapname=tab
		tab=nil
	end
	
	if type(tab)~="table" then -- just default mod settings
	
		local baseurl=map["#opts"].url
		if baseurl~="/" then baseurl=baseurl.."/" end
		tab={
			["#default"]	=	name, 		-- no badlinks, we own everything under here
			["#opts"]		=	{
									url=baseurl..mapname,
									title=name,
								},
		}
	end
	map[mapname]=tab	
	return tab
end

local function default_map()
	local map={ -- base lookup table 
	["#index"]		=	"welcome", 
	["#default"]	=	"waka", 		-- no badlinks, everything defaults to a wikipage
	["#opts"]		=	{
							url="/",
						},
	}
	add_map(map,"admin")
	add_map(map.admin,"console")["#opts"].input=
[[
print("test")
]]

	add_map(map,"dumid")
	add_map(map,"data")
	add_map(map,"note")
	add_map(map,"profile")
	add_map(map,"blog")
	add_map(map,"thumbcache")

	return map
end

map=default_map()

--add_map("dice")
--add_map("mirror")
--add_map("port")
--add_map("todo")
--add_map("chan")
--add_map("shoop")


-- disable forum code for now...
	local forums={
		{
			id="spam",
			title="General off topic posts.",
		},
	}
	for i,v in ipairs(forums) do -- create id lookups as well
		forums[v.id]=v
	end
--add_map(map,"forum")["#opts"].forums=forums



mods=find_mods(map) -- build mods pointers from the map for default app

setup=function()
	setup=nil -- can only run once
	
	if ngx then
	

--make sure we setup the database
		local dat=require("wetgenes.www.any.data")
--		dat.setup_db(ae_opts)
--before we try and load the opts
	
		local srv=ngx.ctx
		
		local old_vhost=srv.vhost


		for n,v in pairs(vhosts) do --we need to load up each vhost for initial setup
		
			srv.vhost=n
			
			default_vars(v)

			v.map=default_map()

			if n=="genes" then -- extra site setup

				add_map(v.map,"genes","genes")
				
			end
						
			dat.setup_db(ae_opts)
			v.lua = ae_opts.get_dat("lua") -- this needs to be per vhost
			if v.lua then
				local f=loadstring(v.lua)
				if f then
					setfenv(f,v)
					pcall( f )
				end
			end

			v.mods=find_mods(v.map) -- build mods pointers from the map

log(n)

		end

		srv.vhost=old_vhost
	else

		lua = ae_opts.get_dat("lua") -- this needs to be per instance, so need to change the way opts works...
		if lua then
			local f=loadstring(lua)
			if f then
				setfenv(f,opts)
				pcall( f )
			end
		end

	end

end
