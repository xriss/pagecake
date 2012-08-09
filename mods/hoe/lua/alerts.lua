-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local json=require("wetgenes.json")

local wet_html=require("wetgenes.html")

local dat=require("wetgenes.www.any.data")
local cache=require("wetgenes.www.any.cache")

local users=require("wetgenes.www.any.users")

local img=require("wetgenes.www.any.img")

local log=require("wetgenes.www.any.log").log -- grab the func from the package

local wstr=require("wetgenes.string")
local wet_string=wstr
local str_split=wet_string.str_split
local serialize=wet_string.serialize


-- require all the module sub parts
local html  =require("hoe.html")
local rounds=require("hoe.rounds")


-- be alert your country needs more lerts

module("hoe.alerts")

--
-- print all alerts in this table
--
function alerts_to_html(srv,as)
	local H=srv.H

	if not as or #as==0 then return end -- no alerts so do nothing
	
	local t={}
	local function put(a,b)
		t[#t+1]=H.get(a,b)
	end

	put("alert_head_html")
	
	for i,a in ipairs(as) do
	
		if a.form=="speedround_soon" then
		
			a.countdown_name="alert_"..i
			a.countdown_time=math.floor(a.tstart-os.time())
			put("alert_speedround_soon_html",a)
			
		elseif a.form=="round_ending" then
		
			a.countdown_name="alert_"..i
			a.countdown_time=math.floor(a.tend-os.time())
			put("alert_round_ending_html",a)
			
		elseif a.form=="round_over" then
		
			put("alert_round_over_html",a)
			
		end
		
	end

	put("alert_foot_html")
	
	return table.concat(t)
end

--
-- get all global alerts, these can be cached and selectively displayed for each user?
--
function get_alerts(srv)
	local H=srv.H

	local as={}
	function as_add(a) if a then as[#as+1]=a end end

--	as_add(check_speedround(H))
	as_add(check_thisround(srv))

	return as
end

-- this can be globally cached for a few minutes and applies to everyone
function check_speedround(srv)
	local H=srv.H

	local t=os.time()
	local d=os.date("*t",t)
	
	local tday=math.floor(t/(24*60*60))*(24*60*60) -- begining of the day
	
	if d.wday==7 and d.hour<22 then -- warn of new game
	
		local a={}
		
		a.form="speedround_soon"
		a.tstart=tday+(22*60*60) -- the time the game should start
		a.tlen=4032 -- the length of the game
		a.tend=a.tstart+a.tlen -- the time the game should end
		return a
	end

	return nil
end



-- some info about the round we are currently viewing
function check_thisround(srv)
	local H=srv.H

	if not H.round then return nil end -- no round
	
	local r=H.round.cache
	
	if r.state~="active" then -- game over
		local a={}
		a.form="round_over"
		a.round=r.id
		a.tend=r.endtime
		return a
	end

	local t=os.time()
	
	if r.endtime-t < (24*60*60) then -- game ending soon
		local a={}
		a.form="round_ending"
		a.round=r.id
		a.tend=r.endtime
		return a
	end

	return nil
end



