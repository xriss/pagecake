-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local log=require("wetgenes.www.ngx.log").log

local ngx=ngx

local M={ modname=(...) } ; package.loaded[M.modname]=M
local opts=M


--[[

to test locally copypasta into /etc/hosts

127.0.0.1 api.wetgenes.com
127.0.0.1 candy.wetgenes.com
127.0.0.1 bardslov.esyou.com
127.0.0.1 roadee.lo4d.net
127.0.0.1 artcrawl.lo4d.net
127.0.0.1 itstuff.org.uk
127.0.0.1 poop.lo4d.net
127.0.0.1 paint.wetgenes.com
127.0.0.1 littlemiss.esyou.com
127.0.0.1 gamayo.wetgenes.com
127.0.0.1 gamayo.wetgenes.com
127.0.0.1 horrordriv.esyou.com
127.0.0.1 cello.esyou.com
127.0.0.1 play.wetgenes.com
127.0.0.1 cake.4lfa.com
127.0.0.1 catch.4lfa.com
127.0.0.1 cog.4lfa.com
127.0.0.1 hoe.4lfa.com
127.0.0.1 bulbaceous.com
127.0.0.1 xixs.com
127.0.0.1 esyou.com
127.0.0.1 lo4d.net
127.0.0.1 4lfa.com
127.0.0.1 wetgenes.com
127.0.0.1 itwrong.4lfa.com


]]

opts.mods={} -- modules we require

opts.init=function()

	print("initialisation time")
	
	

	opts.vhosts_map={
	{"api",           "genes",      "api.wetgenes.com",     },                -- any  domain with api in it
	{"candy",         "candy",      "candy.wetgenes.com",   },                -- any  domain containing candy
	{"bardslov",      "bardslov",   "bardslov.esyou.com",   },                -- any  domain containing bardslov
	{"roadee",        "roadee",     "roadee.lo4d.net",      },                -- any  domain containing roadee
	{"artcrawl",      "artcrawl",   "artcrawl.lo4d.net",    subdomain=true,}, -- any  domain containing artcrawl
	{"itstuff",       "itstuff",    "itstuff.org.uk",       empty=true},      -- any  domain containing itstuff
	{"poop",          "poop",       "poop.lo4d.net",        },                -- any  domain containing poop
	{"paint",         "paint",      "paint.wetgenes.com",   },                -- any  domain containing paint
	{"littlemiss",    "miss",       "littlemiss.esyou.com", },                -- any  domain containing littlemiss
	{"ga-ma-yo",      "gamayo",     "gamayo.wetgenes.com",  },                -- any  domain containing ga-ma-yo
	{"gamayo",        "gamayo",     "gamayo.wetgenes.com",  },                -- any  domain containing gamayo
	{"horror",        "horror",     "horrordriv.esyou.com", },                -- any  domain containing horror
	{"cello",         "cello",      "cello.esyou.com",      },                -- any  domain containing cello
	{"play",          "play",       "play.wetgenes.com",    },                -- any  domain containing play
	{"cake",          "cake",       "cake.4lfa.com",        },                -- any  domain containing cake
	{"catch",         "catch",      "catch.4lfa.com",       },                -- any  domain containing catch
	{"cog",           "cog",        "cog.4lfa.com",         },                -- any  domain containing cog
	{"hoe",           "hoe",        "hoe.4lfa.com",         },                -- any  domain containing hoe
	{"bulbaceous",    "bulbaceous", "bulbaceous.com",       },                -- any  domain containing bulbaceous
	{"xixs",          "xixs",       "xixs.com",             empty=true},      -- any  domain containing xixs
	{"esyou",         "esyou",      "esyou.com",            },                -- any  domain containing esyou
	{"lo4d",          "lo4d",       "lo4d.net",             subdomain=true,}, -- any  domain containing lo4d
	{"4lfa",          "4lfa",       "4lfa.com",             empty=true},      -- any  domain containing 4lfa
	{"wet",           "wetgenes",   "wetgenes.com",         },                -- any  domain containing wet
	{"itwrong",       "itwrong",    "itwrong.4lfa.com",     empty=true},      -- any  domain containing itwrong
	{"local",         "wetgenes",   "localhost",            subdomain=true,}, -- test this domain
	{"192.168.56.56", "wetgenes",   "192.168.56.56",        subdomain=true,}, -- test this domain (vagrant)
	} --(the last vhost is the default)

	-- a low level force redirect of some domains, we can probably get away with a /page/or/two as well
	opts.redirect_domains={
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
	[ "join.wetgenes.com"         ]= "wetgenes.com/js/genes/join/join.html"     ,
	[ "wetgenes.4lfa.com"         ]= "wetgenes.com"                             ,
	}

	local vhosts={}
	for i,v in ipairs(opts.vhosts_map) do
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
		t.empty=t.empty or v.empty
	end



-- add a mapping to the map table
	local function add_map(map,name,tab,tabextra)

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
		if tabextra then
			for n,v in pairs(tabextra) do tab[n]=v end
		end
		map[mapname]=tab	
		return tab
	end



	for n,v in pairs(vhosts) do --we need to load up each vhost for initial setup
	
		v.mail_from="spam@wetgenes.com"
		v.mail_admin={"notshi@gmail.com","krissd@gmail.com",}

		v.admin={
			["2@id.wetgenes.com"]=true,
			["14@id.wetgenes.com"]=true,
			["109440170884180647149@id.google.com"]=true,
			["76561197960568486@id.steamcommunity.com"]=true,
			["shi@esyou.com"]=true,
			["kriss@xixs.com"]=true,
		}

		v.mysql={
			path="/var/run/mysqld/mysqld.sock",
--			host="127.0.0.1",
--			port=3306
			user="kriss",
			password="ke63pSEQzNnjEe",
		}


		if v.empty then
		
			v.map={}
		
		else
		
			local map={ -- base lookup table 
			["#index"]		=	"welcome", 
			["#default"]	=	"waka", 		-- no badlinks, everything defaults to a wikipage
			["#opts"]		=	{
									url="/",
								},
			}
			add_map(map,"admin")
			add_map(map.admin,"console")["#opts"].input=[[
print("test")
]]
			add_map(map,"dumid")
			add_map(map,"data")
			add_map(map,"note")
			add_map(map,"profile")
			add_map(map,"blog")
			add_map(map,"thumbcache",nil,{["#nolimit"]=true})

			v.map=map

		end
			
		if n=="hoe" then -- extra site setup

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
			add_map(v.map,"genes","genes")

		elseif n=="genes" then -- extra site setup

			add_map(v.map,"genes","genes")
			
			opts.map=v.map -- remember this one globally to stop crashes in old code
		end
					
		local mods={}
		-- find each mod
		for i,v in pairs(v.map) do
			if type(v)=="table" then
				local name=v["#default"]
				if name then
					mods[name]=v["#opts"] or {}
					opts.mods[name]=true
				end
			end
		end
		v.mods=mods -- build mods pointers from the map

print( " init "..n )

	end


	opts.vhosts=vhosts

print(" vhosts has been initailised ")

end



opts.setup=function()

	if ngx then

	opts.setup=nil -- can only run once
	
	math.randomseed( os.time() ) -- try and randomise a little bit better

--make sure we setup each database
		local ae_opts=require("wetgenes.www.any.opts")
		local dat=require("wetgenes.www.any.data")
	
		local srv=ngx.ctx
		
		local old_vhost=srv.vhost

		for n,v in pairs(opts.vhosts) do --we need to load up each vhost for initial setup
		
			srv.vhost=n
			
			dat.set_defs(ae_opts)
			dat.setup_db(ae_opts)
			v.lua = ae_opts.get_dat("lua") -- this needs to be per vhost
			if v.lua then
				local f=loadstring(v.lua)
				if f then
					setfenv(f,v)
					pcall( f )
				end
			end

		end

		srv.vhost=old_vhost

	end

end


