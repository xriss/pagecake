
local os=os
local ae_opts=require("wetgenes.www.any.opts")
local dat=require("wetgenes.www.any.data")
local cache=require("wetgenes.www.any.cache")

local wet_string=require("wetgenes.string")
local str_split=wet_string.str_split
local serialize=wet_string.serialize

local loadstring=loadstring
local setfenv=setfenv
local pcall=pcall
local pairs=pairs
local type=type

module("opts")

local app_name="hoe"

mail={}
mail.from="spam@hoe-house.appspotmail.com"

users={}
users.admin={ -- users with admin rights for this app
	["notshi@gmail.com"]=true,
	["14@id.wetgenes.com"]=true,
	["krissd@gmail.com"]=true,
	["2@id.wetgenes.com"]=true,
}

map={ -- base lookup table 

["#index"]		=	"hoe", 
["#default"]	=	"waka", 		-- no badlinks, everything defaults to a wikipage
["#flavour"]	=	app_name, 			-- use this flavour when serving
["#opts"]		=	{
						url="/",
					},
					
["hoe"]			=	{			-- the base module
						["#default"]	=	"hoe", 		-- no badlinks, we own everything under here
						["#flavour"]	=	app_name, 			-- use this flavour when serving
						["#opts"]		=	{
												url="/hoe",
											},
					},
					
["admin"]		=	{			-- all admin stuff
						["#default"]	=	"admin",
						["#flavour"]	=	app_name, 			-- use this flavour when serving
						["#opts"]		=	{
												url="/admin",
											},
						["console"]		=	{			-- a console module
											["#default"]	=	"console",
											["#flavour"]	=	app_name, 			-- use this flavour when serving
											["#opts"]		=	{
																	url="/admin/console",
																},
											},
					},
					
["dumid"]		=	{			-- a dumid module
						["#default"]	=	"dumid", 		-- no badlinks, we own everything under here
						["#flavour"]	=	app_name, 			-- use this flavour when serving
						["#opts"]		=	{
												url="/dumid",
											},
					},

["thumbcache"]		=	{			-- cache some images
						["#default"]	=	"thumbcache", 		-- no badlinks, we own everything under here
						["#flavour"]	=	app_name, 			-- use this flavour when serving
						["#opts"]		=	{
												url="/thumbcache",
											},
					},
					
["blog"]		=	{			-- a blog module
						["#default"]	=	"blog", 		-- no badlinks, we own everything under here
						["#flavour"]	=	app_name, 			-- use this flavour when serving
						["#opts"]		=	{
												url="/blog",
											},
					},
					
["note"]		=	{			-- a sitewide comment module
						["#default"]	=	"note", 		-- no badlinks, we own everything under here
						["#flavour"]	=	app_name, 			-- use this flavour when serving
						["#opts"]		=	{
												url="/note",
											},
					},

["profile"]		=	{			-- a sitewide comment module
						["#default"]	=	"profile", 		-- no badlinks, we own everything under here
						["#flavour"]	=	app_name, 			-- use this flavour when serving
						["#opts"]		=	{
												url="/profile",
											},
					},

["data"]		=	{			-- a data module
						["#default"]	=	"data", 		-- no badlinks, we own everything under here
						["#flavour"]	=	nil, 			-- use this flavour when serving
						["#opts"]		=	{
												url="/data",
											},
					},

}


mods={}

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

mods.console=mods.console or {}
mods.console.input=
[[
local srv=(...)
local hoe=require("hoe")
local con=require("hoe.con")
local H=hoe.create(srv)

print(con.help(H))
]]

lua = ae_opts.get_dat("lua")
if lua then
	local f=loadstring(lua)
	if f then
		setfenv(f,_M)
		pcall( f )
	end
end
