-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local ngx=ngx

module("opts")
local opts=require("opts")

vhosts_map={
	{"4lfa%.com","4lfa"},
}
vhosts={}
for i,v in ipairs(vhosts_map) do
	local t={}
	setmetatable(t,{__index=opts})
	vhosts[ v[2] ]=t
end


local ae_opts=require("wetgenes.www.any.opts")
local dat=require("wetgenes.www.any.data")
local cache=require("wetgenes.www.any.cache")

local wet_string=require("wetgenes.string")
local str_split=wet_string.str_split
local serialize=wet_string.serialize


bootstrapp_version=20110121 -- hand bump to todays date on release

mail={}
mail.from="spam@wet.appspotmail.com"

urls={}

head={} -- stuff to inject into the html header
head.favicon="/favicon.ico" -- the favicon
head.extra_css={} -- more css links
head.extra_js={} -- more js links

-- need some admin users or we will get nowhere
users={admin={
["2@id.wetgenes.com"]=true,
["14@id.wetgenes.com"]=true,
["notshi@gmail.com"]=true,
["krissd@gmail.com"]=true,
}}


local app_name=nil -- best not to use an appname, unless we run multiple apps on one site 

-- look through the mods and save the #opts of each mod used for easy lookup
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

	if not tab then -- just default mod settings
	
		local baseurl=map["#opts"].url
		if baseurl~="/" then baseurl=baseurl.."/" end
		tab={
			["#default"]	=	name, 		-- no badlinks, we own everything under here
			["#opts"]		=	{
									url=baseurl..name,
									title=name,
								},
		}
	end
	map[name]=tab	
	return tab
end

local function default_map()
	local map={ -- base lookup table 
	["#index"]		=	"welcome", 
	["#default"]	=	"waka", 		-- no badlinks, everything defaults to a wikipage
	["#opts"]		=	{
							url="/",
						},
											
	["wiki"]		=	{			-- redirect
							["#redirect"]	=	"/", 		-- remap this old url
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

local forums={
	{
		id="spam",
		title="General off topic posts.",
	},
}
for i,v in ipairs(forums) do -- create id lookups as well
	forums[v.id]=v
end
add_map(map,"forum")["#opts"].forums=forums


--add_map(map,"comic")["#opts"].groups={"can","chow","esc","pms","teh","tshit","wetcoma","teh"}

mods=find_mods(map) -- build mods pointers from the map for default app

if ngx then
	local srv=ngx.ctx
	
	local old_vhost=srv.vhost

	for n,v in pairs(vhosts) do --we need to load up each vhost for initial setup
	
		srv.vhost=n

		v.map=default_map()

		if n=="4lfa" then -- extra site setup, no more admin settings?
		
			add_map(v.map,"comic")["#opts"].groups={"can","chow","esc","pms","teh","tshit","wetcoma","teh"}
			
		end

		v.lua = ae_opts.get_dat("lua") -- this needs to be per instance, so need to change the way opts works...
		if v.lua then
			local f=loadstring(v.lua)
			if f then
				setfenv(f,opts)
				pcall( f )
			end
		end

		v.mods=find_mods(v.map) -- build mods pointers from the map

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
