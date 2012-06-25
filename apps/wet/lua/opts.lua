-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require



module("opts")

vhosts_map={
	{"4lfa%.com","local"},
--	{"4lfa%.com","4lfa"},
}
vhosts={}
for i,v in ipairs(vhosts_map) do
	vhosts[ v[2] ]={}
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

twitter={
key="F9pwnTWA5WEwJwzwkcbw",
secret="zegUtLKtSDtqzIRxG2i5zcCMpltGOzmwLtWcC3i1M",
}

facebook={
id="5335065877",
key="5335065877",
secret="8f214437e701e7203e0ddfb081ac4936",
}

users={admin={
["2@id.wetgenes.com"]=true,
["14@id.wetgenes.com"]=true,
["notshi@gmail.com"]=true,
["krissd@gmail.com"]=true,
}}


local app_name=nil -- best not to use an appname, unless we run multiple apps on one site 


forums={
	{
		id="spam",
		title="General off topic posts.",
	},
}
for i,v in ipairs(forums) do -- create id lookups as well
	forums[v.id]=v
end


map={ -- base lookup table 

["#index"]		=	"welcome", 
["#default"]	=	"waka", 		-- no badlinks, everything defaults to a wikipage
["#flavour"]	=	app_name, 			-- use this flavour when serving
["#opts"]		=	{
						url="/",
					},
										
["wiki"]		=	{			-- redirect
						["#redirect"]	=	"/", 		-- remap this url and below
					},
					
["blog"]		=	{			-- a blog module
						["#default"]	=	"blog", 		-- no badlinks, we own everything under here
						["#flavour"]	=	app_name, 			-- use this flavour when serving
						["#opts"]		=	{
												url="/blog",
												title="blog",
											},
					},

["comic"]		=	{			-- a comic module
						["#default"]	=	"comic", 		-- no badlinks, we own everything under here
						["#flavour"]	=	app_name, 			-- use this flavour when serving
						["#opts"]		=	{
												url="/comic",
												title="comic",
												groups={"can","chow","esc","pms","teh","tshit","wetcoma","teh"},
											},
					},

["score"]		=	{			-- a score module
						["#default"]	=	"score", 		-- no badlinks, we own everything under here
						["#flavour"]	=	app_name, 			-- use this flavour when serving
						["#opts"]		=	{
												url="/score",
												title="score",
											},
					},

["admin"]		=	{			-- all admin stuff
						["#default"]	=	"admin",
						["console"]		=	{			-- a console module
											["#default"]	=	"console",
											["#flavour"]	=	app_name,
											["#opts"]		=	{
																	url="/admin/console/",
																},
											},
					},
					
["dumid"]		=	{			-- a dumid module
						["#default"]	=	"dumid", 		-- no badlinks, we own everything under here
						["#opts"]		=	{
												url="/dumid",
											},
					},
					
					
["data"]		=	{			-- a data module
						["#default"]	=	"data", 		-- no badlinks, we own everything under here
						["#opts"]		=	{
												url="/data",
											},
					},

["note"]		=	{			-- a sitewide comment module
						["#default"]	=	"note", 		-- no badlinks, we own everything under here
						["#opts"]		=	{
												url="/note",
											},
					},

["chan"]		=	{			-- an imageboard module
						["#default"]	=	"chan", 		-- no badlinks, we own everything under here
						["#opts"]		=	{
												url="/chan",
											},
					},

["shoop"]		=	{			-- an image module
						["#default"]	=	"shoop", 		-- no badlinks, we own everything under here
						["#opts"]		=	{
												url="/shoop",
											},
					},

["forum"]		=	{			-- a forum module
						["#default"]	=	"forum", 		-- no badlinks, we own everything under here
						["#opts"]		=	{
												url="/forum",
												forums=forums,
											},
					},

["profile"]		=	{			-- a profile module
						["#default"]	=	"profile", 		-- no badlinks, we own everything under here
						["#opts"]		=	{
												url="/profile",
											},
					},

["dice"]		=	{			-- roll some dice
						["#default"]	=	"dice", 		-- no badlinks, we own everything under here
						["#opts"]		=	{
												url="/dice",
											},
					},

["thumbcache"]		=	{			-- cache some images
						["#default"]	=	"thumbcache", 		-- no badlinks, we own everything under here
						["#opts"]		=	{
												url="/thumbcache",
											},
					},
["mirror"]		=	{			-- talk to talk
						["#default"]	=	"mirror", 		-- no badlinks, we own everything under here
						["#opts"]		=	{
												url="/mirror",
											},
					},
["port"]		=	{			-- port to port
						["#default"]	=	"port", 		-- no badlinks, we own everything under here
						["#opts"]		=	{
												url="/port",
											},
					},
["todo"]		=	{			-- bribes
						["#default"]	=	"todo", 		-- no badlinks, we own everything under here
						["#opts"]		=	{
												url="/todo",
											},
					},
}
local _=require("todo") -- need to initialize waka hooks

mods={}


-- find each mod
for i,v in pairs(map) do
	if type(v)=="table" then
		local name=v["#default"]
		if name then
			local t=mods[name] or {}
			mods[name]=t
			for i,v in pairs( v["#opts"] or {} ) do
				t[i]=v -- copy opts into default for each mod
			end
		end
	end
end

mods.init={}

mods.comic.groups={"can","chow","esc","pms","teh","tshit","wetcoma","teh"}

mods.console=mods.console or {}
mods.console.input=
[[
print("test")
]]

lua = ae_opts.get_dat("lua") -- this needs to be per instance, so need to change the way opts works...
if lua then
	local f=loadstring(lua)
	if f then
		setfenv(f,_M)
		pcall( f )
	end
end
