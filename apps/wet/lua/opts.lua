-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local ngx=ngx

module("opts")
local opts=require("opts")

vhosts_map={
	{"cello",	"cello"},			-- any domain with play in it

	{"play",	"play"},			-- any domain with play in it

	{"cake",	"cake"},			-- any domain with cake in it
	{"catch",	"catch"},			-- any domain with catch in it

	{"cog",		"cog"},				-- any domain with cog in it
	{"hoe",		"hoe"},				-- any domain with hoe in it

	{"xixs",	"xixs"},			-- any domain with xixs in it
	{"esyou",	"esyou"},			-- any domain with esyou in it
	{"lo4d",	"lo4d"},			-- any domain with lo4d in it
	{"4lfa",	"4lfa"},			-- any domain with 4lfa in it (the last vhost is also the default)
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


bootstrapp_version=20120706 -- hand bump to todays date on release

mail={}
mail.from="spam@wetgenes.com"

urls={}

head={} -- stuff to inject into the html header
head.favicon="/favicon.ico" -- the favicon
head.extra_css={} -- more css links
head.extra_js={} -- more js links
head.extra={} -- more header junk

-- need some admin users or we will get nowhere
users={admin={
["2@id.wetgenes.com"]=true,
["14@id.wetgenes.com"]=true,
["notshi@gmail.com"]=true,
["krissd@gmail.com"]=true,
}}


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
											
--[[
	["wiki"]		=	{			-- redirect
							["#redirect"]	=	"/", 		-- remap this *old* wiki url to the root
						},
]]

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
	setup=function()end -- can only run once
	
	if ngx then
		local srv=ngx.ctx
		
		local old_vhost=srv.vhost

		for n,v in pairs(vhosts) do --we need to load up each vhost for initial setup
		
			srv.vhost=n

			v.map=default_map()

			if n=="4lfa" then -- extra site setup
			
				add_map(v.map,"comic")["#opts"].groups={"can","chow","esc","pms","teh","wetcoma"}
				
			elseif n=="hoe" then -- extra site setup

				add_map(v.map,"hoe")

			end

			v.lua = ae_opts.get_dat("lua") -- this needs to be per vhost
			if v.lua then
				local f=loadstring(v.lua)
				if f then
					setfenv(f,v)
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

end
