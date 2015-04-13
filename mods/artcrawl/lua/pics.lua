-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require


local whtml=require("wetgenes.html")
local wjson=require("wetgenes.json")
local wstr=require("wetgenes.string")

local log=require("wetgenes.www.any.log").log -- grab the func from the package

local sys=require("wetgenes.www.any.sys")
local dat=require("wetgenes.www.any.data")
local cache=require("wetgenes.www.any.cache")
local users=require("wetgenes.www.any.users")
local fetch=require("wetgenes.www.any.fetch")
local img=require("wetgenes.www.any.img")

local ptwat=require("port.twat")

-- http://www.latlong.net/
local crawls={
	{	tag="dublin",		lat=53.349805,	lng=-6.260310},
	{	tag="bradford",		lat=53.795984,	lng=-1.759398},
	{	tag="leeds",		lat=53.800755,	lng=-1.549077},
}

-- debug functions
local dprint=function(...)print(wstr.dump(...))end
local log=require("wetgenes.www.any.log").log


--local ngx=ngx

--module
local M={ modname=(...) } ; package.loaded[M.modname]=M

M.crawls=crawls -- expose


M.default_props=
{
-- the key/id is the twitter id (a string since the numbers are huge)

	twat_time=0,	-- post time from twitter
	
	screen_name="",	-- screen name of twitter user
	userid="", 		-- who submited the art (twitter user id)

	hot=0,			-- a hot ranking metric for sorting, higher is better
	bad=0,			-- a bad ranking metric for sorting, higher is worse

	day=0,			-- the day this art belongs to (days since 1970 GMT)
					-- (created is an auto prop and is in seconds for precise time)

	valid=0,		-- set to 3 if valid ( contains picture(1) + location(2) + hashtag )
					-- we also keep track of invalid tweets so we know whats been slurped
					
	lat=0,			-- precise location
	lng=0,
	art="",			-- name/id of art location autoguess from lat/lng then maybe admin fixed if that goes bad
	
	pic_url="",		-- url to display picture (we do not host)
	pic_width=0,	-- width of picture
	pic_height=0,	-- height of picture
	
	text="",		-- actual text of tweet

	hashtag="",		-- hashtag, not technically the hashtag, but the subhashtag eg leeds or dublin
					-- as the man hashtag is always artcrawl
}

M.default_cache=
{
	twat={},		-- full json dump of the twat
}

function M.kind(srv)
	return "artcrawl.pics"
end


--------------------------------------------------------------------------------
--
-- check that entity has initial data and set any missing defaults
-- the second return value is false if this is not a valid entity
--
--------------------------------------------------------------------------------
function M.check(srv,ent)

	local ok=true

-- added some fields, patch them up
	local p=ent.props
	p.hot=p.hot or 0
	p.bad=p.bad or 0

	local c=ent.cache
	c.hot=c.hot or 0
	c.bad=c.bad or 0
			
	return ent
end


--------------------------------------------------------------------------------
--
-- list pages
--
--------------------------------------------------------------------------------
function M.list(srv,opts,t)
	opts=opts or {} -- stop opts from being nil
	
	t=t or dat -- use transaction?
	
	local q={
		kind=M.kind(srv),
		limit=opts.limit or 100,
		offset=opts.offset or 0,
	}
	
	dat.build_qq_filters(opts,q,{"valid","day","twat_time","lat","lng","art","userid","hashtag","hot","bad","created"})

	local r=t.query(q)
		
	for i=1,#r.list do local v=r.list[i]
		dat.build_cache(v)
		M.check(srv,v)
	end

	return r.list
end

--------------------------------------------------------------------------------
--
-- perform a search , future and maybe past, cron this activity every few minutes
-- and we will have live updates
--
--------------------------------------------------------------------------------
function M.twat_search(srv,opts,t)
	opts=opts or {} -- stop opts from being nil
	opts.hashtag="#streetart OR #artcrawl OR #art OR #leedsartcrawl OR @leedsartcrawl" -- force artcrawl search
	
	local q={q=opts.hashtag,result_type="recent"}
	
	q.count=opts.count or 100
	q.since_id=opts.since_id
	
	local d=""
	if q.since_id or q.max_id then -- already limited use "0" for since ID to disable limits
		d=d.."Searching for twats "..tostring(q.since_id).."<->"..tostring(q.since_id)
	else
		q.since_id=M.twat_since_id(srv)	-- use the last id we read as a limiter
		d=d.."Searching for twats since "..tostring(q.since_id)
	end
--	q.since_id=0
	
	
	local r=ptwat.search(srv,q)
	d=d.." found "..#r.statuses
	
	local last_stat
	if #r.statuses>0 then -- remember last twat
		local last_stat=r.statuses[1]
		M.twat_since_id(srv,last_stat.id_str)
	end
	
	
	local last_twat
	local ret={}
	local tags={}
	for _,twat in ipairs(r.statuses) do
		local c=M.twat_save(srv,twat)
		if not last_twat then last_twat=c end
--log(os.date("%c",c.twat_time).." : "..c.text)
		if (c.valid==1 or c.valid==3) then -- only valid
			c.twat=nil -- less junk
			ret[#ret+1]=c
			if c.hashtag then
				tags[c.hashtag]=(tags[c.hashtag] or 0) +1
			end
			log(c.text)
		end
	end
	d=d.." of which "..#ret.." are good. ";
	if last_twat then
		d=d.." ( "..os.date("%c",last_twat.twat_time).." ) "
	end
	log(d)
--	log(wstr.dump(tags))
	
	return d
end

--------------------------------------------------------------------------------
--
-- get last or first twat id, for later requests
--
--------------------------------------------------------------------------------
function M.twat_since_id(srv,t)

	local key="key=artcrawl/pics/twat"
	
	if t then -- set and return
		cache.put(srv,key,{str=t})
--		log(t)
		return t
	end
	
	t=cache.get(srv,key) -- try cache frst
	if type(t)=="table" and t.str then
--		log(t.str)
		return t.str
	end

	local r=M.list(srv,{sort="twat_time-",limit=1}) -- then try last saved value
	t=r[1] and r[1].cache.id
	if t then
		cache.put(srv,key,{str=t})
	end

	return t
end


function M.get_hashtag(srv,c)

	local hashtag="#" -- notag
	
	local dist=2*2 -- keep within a radius of 2 which is around 100 miles
	local best

	local t=c.text:lower()
	for i,v in ipairs(crawls) do
		if t:find(v.tag) then
			hashtag=v.tag
			break
		end		
	end					
	
	if hashtag=="#" then
		if c.valid==2 or c.valid==3 or c.valid==6 or c.valid==7 then -- can use lng lat only if we have it
		
			for i,v in ipairs(crawls) do
			
				local d1=v.lat-c.lat
				local d2=v.lng-c.lng
				local dd=d1*d1 + d2*d2 -- very dumb distance check, but it will do
				
				if dist > dd then
					dist=dd
					best=v.tag
				end
				
			end
			
			return best or hashtag
		end
	end

	return hashtag
end
--------------------------------------------------------------------------------
--
-- save this twat that we probably got in a search, or maybe from a read/write cycle
-- the twat 
--
--------------------------------------------------------------------------------
function M.twat_save(srv,twat)

	local e=M.create(srv,twat.id_str)
	local c=e.cache
	
	c.screen_name=twat.user.screen_name
	
	
-- this probably works...
	local t={ string.match(twat.created_at, "%w+ (%w+) 0*(%d+) 0*(%d+):0*(%d+):0*(%d+) ([^%s]+) 0*(%d+)") }
	for i,v in ipairs{'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'} do
		if t[1]==v then t[1]=i end
	end
	c.twat_time=os.time{year=t[7],month=t[1],day=t[2],hour=t[3],min=t[4],sec=t[5]}
	
	c.userid=twat.user.id.."@id.twitter.com"
	
	c.day=math.floor(c.twat_time/(24*60*60))
	
	
	c.valid=0
	if type(twat.entities)=="table" and type(twat.entities.media)=="table" and twat.entities.media[1] and twat.entities.media[1].type=="photo" then
		c.pic_url=twat.entities.media[1].media_url
		c.pic_width=twat.entities.media[1].sizes.medium.w
		c.pic_height=twat.entities.media[1].sizes.medium.h
		c.valid=c.valid+1
	end
	if type(twat.geo)=="table" and twat.geo.coordinates then
		c.lat=twat.geo.coordinates[1]
		c.lng=twat.geo.coordinates[2]
		c.art=""
		c.valid=c.valid+2
	end
	
	c.text=twat.text
	c.twat=twat -- full twat for later

	c.hashtag=M.get_hashtag(srv,c)


	if twat.retweeted_status then -- flag as retweeted (ignore if this flag is set)
		c.valid=c.valid+4
		return c
	else
		local t=twat.text:lower()
		if t:find("artcrawl") then -- its an artcrawl tweet, so its legit
		else -- probably a #art tweet, need to check if it contains a location as well
			local tagged
			for i,v in ipairs(crawls) do
				if t:find(v.tag) then
					tagged=v.tag
					break
				end
			end
			if not tagged then -- a tweet with #art but without #leeds or #bradford etc should be ignored, dont even save as art is a busy tag
				c.valid=c.valid+4
				return c
			end
		end
	end
	
	M.put(srv,e)
	
	return c
end


dat.set_defs(M) -- create basic data handling funcs

dat.setup_db(M) -- make sure DB exists and is ready
