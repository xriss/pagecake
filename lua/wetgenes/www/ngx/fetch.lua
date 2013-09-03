-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local log=require("wetgenes.www.any.log").log
local ngx=require("ngx")

local wstr=require("wetgenes.string")
--local socket=require("socket")
--local http=require("socket.http")
--local ltn12=require("ltn12")

module(...)
local _M=require(...)
package.loaded["wetgenes.www.any.fetch"]=_M

function countzero()
	count=0
	api_time=0
end
countzero()

local kind_props={}	-- default global props mapped to kinds

local start_time -- handle simple api benchmarking of some calls
local function apis()
	start_time=os.time()
end
local function apie(...)
	api_time=api_time+os.time()-start_time
	return ...
end

function get(url,headers,body)
--	log("NEWfetch.get:"..url)


local ret

	for i=1,10 do -- limit redirects

--	log("NEWfetch.get:"..url)

		ret=ngx.location.capture("/_proxy",{
			method=ngx.HTTP_GET,
			body=body,
			ctx={ headers = headers },
			vars={ _url = url },
		})
		ret.code=ret.status ret.status=nil -- rename status to code
		ret.mimetype=ret.header["Content-Type"]
		
		if ret.code>=300 and ret.code<400 then -- follow redirects
		
			url=ret.header.Location
			
		else
			break			
		end
		
	end

--	log("NEWReceived "..tostring(ret.body).."\n")

	return ret
end


function post(url,headers,body)
--	log("NEWfetch.post:"..url)


	local ret=ngx.location.capture("/_proxy",{
		method=ngx.HTTP_POST,
		body=body,
		ctx={ headers = headers },
		vars={ _url = url },
	})
	ret.code=ret.status ret.status=nil -- rename status to code
	ret.mimetype=ret.header["Content-Type"]

--	log("NEWReceived "..tostring(ret.body).."\n")

	return ret
end

