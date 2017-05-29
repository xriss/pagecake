-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local log=require("wetgenes.www.ngx.log").log

local ngx=ngx

module("opts")
local opts=require("opts")

vhosts_map={
--	{"local",      "genes",      "host.local",           subdomain=true,}, -- test this   domain
	{"api",        "genes",      "api.wetgenes.com",     },                -- any  domain with api in it
	{"candy",      "candy",      "candy.wetgenes.com",   },                -- any  domain containing candy
	{"bardslov",   "bardslov",   "bardslov.esyou.com",   },                -- any  domain containing bardslov
	{"roadee",     "roadee",     "roadee.lo4d.net",      },                -- any  domain containing roadee
	{"artcrawl",   "artcrawl",   "artcrawl.club",        subdomain=true,}, -- any  domain containing artcrawl
	{"itstuff",    "itstuff",    "itstuff.org.uk",       },                -- any  domain containing itstuff
	{"poop",       "poop",       "poop.lo4d.net",        },                -- any  domain containing poop
	{"paint",      "paint",      "paint.wetgenes.com",   },                -- any  domain containing paint
	{"littlemiss", "miss",       "littlemiss.esyou.com", },                -- any  domain containing littlemiss
	{"ga-ma-yo",   "gamayo",     "ga-ma-yo.com",         },                -- any  domain containing ga-ma-yo
	{"gamayo",     "gamayo",     "ga-ma-yo.com",         },                -- any  domain containing gamayo
	{"horror",     "horror",     "horrordriv.esyou.com", },                -- any  domain containing horror
	{"cello",      "cello",      "cello.esyou.com",      },                -- any  domain containing cello
	{"play",       "play",       "play.wetgenes.com",    },                -- any  domain containing play
	{"cake",       "cake",       "cake.4lfa.com",        },                -- any  domain containing cake
	{"catch",      "catch",      "catch.4lfa.com",       },                -- any  domain containing catch
	{"cog",        "cog",        "cog.4lfa.com",         },                -- any  domain containing cog
	{"hoe",        "hoe",        "hoe.4lfa.com",         },                -- any  domain containing hoe
	{"bulbaceous", "bulbaceous", "bulbaceous.com",       },                -- any  domain containing bulbaceous
	{"xixs",       "xixs",       "xixs.com",             },                -- any  domain containing xixs
	{"esyou",      "esyou",      "esyou.com",            },                -- any  domain containing esyou
	{"lo4d",       "lo4d",       "lo4d.net",             subdomain=true,}, -- any  domain containing lo4d
	{"4lfa",       "4lfa",       "4lfa.com",             },                -- any  domain containing 4lfa
	{"wet",        "wetgenes",   "wetgenes.com",         },                -- any  domain containing wet
} --(the last vhost is the default)

-- a low level force redirect of some domains, we can probably get away with a /page/or/two as well
redirect_domains={
	[ "tv.wetgenes.com"           ]= "play.wetgenes.com/tv"                     ,
	[ "dike.wetgenes.com"         ]= "play.wetgenes.com/dike"                   ,
	[ "wetdike.wetgenes.com"      ]= "play.wetgenes.com/dike"                   ,
	[ "estension.wetgenes.com"    ]= "play.wetgenes.com/estension"              ,
	[ "asue1.wetgenes.com"        ]= "play.wetgenes.com/asue1"                  ,
	[ "ballclock.wetgenes.com"    ]= "play.wetgenes.com/ballclock"              ,
	[ "romzom.wetgenes.com"       ]= "play.wetgenes.com/romzom"                 ,
	[ "diamonds.wetgenes.com"     ]= "play.wetgenes.com/diamonds"               ,
	[ "gojirama.wetgenes.com"     ]= "play.wetgenes.com/gojirama"               ,
	[ "adventisland.wetgenes.com" ]= "play.wetgenes.com/advent"                 ,
	[ "advent.wetgenes.com"       ]= "play.wetgenes.com/advent"                 ,
	[ "batwsball.wetgenes.com"    ]= "play.wetgenes.com/batwsball"              ,
	[ "bowwow.wetgenes.com"       ]= "play.wetgenes.com/bowwow"                 ,
	[ "basement.wetgenes.com"     ]= "play.wetgenes.com/basement"               ,
	[ "mute.wetgenes.com"         ]= "play.wetgenes.com/mute"                   ,
	[ "asue2.wetgenes.com"        ]= "play.wetgenes.com/asue2"                  ,
	[ "take1.wetgenes.com"        ]= "play.wetgenes.com/take1"                  ,
	[ "pixlcoop.wetgenes.com"     ]= "play.wetgenes.com/pixlcoop"               ,
	[ "itsacoop.wetgenes.com"     ]= "play.wetgenes.com/itsacoop"               ,
	[ "rgbtd0.wetgenes.com"       ]= "play.wetgenes.com/rgbtd0"                 ,
	[ "pief.wetgenes.com"         ]= "play.wetgenes.com/pief"                   ,
	[ "wetcell.wetgenes.com"      ]= "play.wetgenes.com/wetcell"                ,
	[ "only1.wetgenes.com"        ]= "play.wetgenes.com/only1"                  ,
	[ "pokr.wetgenes.com"         ]= "play.wetgenes.com/ville#public.pokr"      ,
	[ "zeegrind.wetgenes.com"     ]= "play.wetgenes.com/ville#public.zeegrind"  ,
	[ "ville.wetgenes.com"        ]= "play.wetgenes.com/ville"                  ,
	[ "forum.wetgenes.com"        ]= "wetgenes.com/forum"                       ,
	[ "join.wetgenes.com"         ]= "api.wetgenes.com/js/genes/join/join.html" ,
}

vhosts={}
for i,v in ipairs(vhosts_map) do
-- setup one table per website (which may have multiple search strings above)
	local t=vhosts[ v[2] ] or {}
	vhosts[ v[2] ]=t
	t.search=t.search or {}
	t.domains=t.domains or {}
-- options
	t.search[v[1]]=true -- valid list search strings that match this domain
	t.domain=v[3] -- force a redirect to this domain if domain is invalid (last entry overrides first)
	t.domains[t.domain]=true -- valid list of domains we will serve from
	t.subdomain=t.subdomain or v.subdomain -- flag subdomains as valid eg anything.4lfa.com is a valid 4lfa.com domain
end

local ae_opts=require("wetgenes.www.any.opts")
local dat=require("wetgenes.www.any.data")
local cache=require("wetgenes.www.any.cache")

local wet_string=require("wetgenes.string")
local wstr=wet_string
local str_split=wet_string.str_split
local serialize=wet_string.serialize

log(wstr.dump(vhosts))

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
		["109440170884180647149@id.google.com"]=true,
		["76561197960568486@id.steamcommunity.com"]=true,
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
	setup=nil -- can only run once
	
	math.randomseed( os.time() ) -- try and randomise a little bit better

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

			if n=="4lfa" then -- extra site setup
			
				add_map(v.map,"comic")["#opts"].groups={"can","chow","esc","pms","teh","wetcoma"}
				
			elseif n=="hoe" then -- extra site setup

				add_map(v.map,"hoe")

			elseif n=="lo4d" then -- extra site setup

				add_map(v.map,"dimeload","dl")

			elseif n=="play" then -- extra site setup

				add_map(v.map,"shadow")

			elseif n=="cake" then -- extra site setup

				add_map(v.map,"dice")
				
			elseif n=="paint" then -- extra site setup

				add_map(v.map,"paint","paint")
				
			elseif n=="artcrawl" then -- extra site setup

				add_map(v.map,"artcrawl","artcrawl")
				add_map(v.map,"port","port")
				
			elseif n=="roadee" then -- extra site setup

				add_map(v.map,"roadee","roadee")

			elseif n=="wetgenes" then -- extra site setup

				add_map(v.map,"forum","forum") -- test forum

			elseif n=="genes" then -- extra site setup

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
