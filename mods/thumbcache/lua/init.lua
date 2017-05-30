
--local wet_html=require("wetgenes.html")

local sys=require("wetgenes.www.any.sys")

--local dat=require("wetgenes.www.any.data")

--local user=require("wetgenes.www.any.user")

local img=require("wetgenes.www.any.img")

local fetch=require("wetgenes.www.any.fetch")

local cache=require("wetgenes.www.any.cache")
local iplog=require("wetgenes.www.any.iplog")

local log=require("wetgenes.www.any.log").log -- grab the func from the package

local ngx=ngx

local wstr=require("wetgenes.string")

local pcall=pcall


local math=math
local string=string
local table=table
local os=os

local ipairs=ipairs
local tostring=tostring
local tonumber=tonumber
local type=type
local require=require

module("thumbcache")

-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-- do not cache the srv param localy, make sure it cascades around
--
-----------------------------------------------------------------------------
function serv(srv)

-- try not to bitch about rate limits on the thumbcache.
--	iplog.ratelimit(srv.ip,-1)

	local usecache=true


	local cachename="thumbcache&"..srv.url
	if srv.query and #srv.query>0 then
		cachename=cachename.."?"..srv.query
	end

	local data
	local image

	if srv.uploads["filedata"] then -- special upload and return
		usecache=false
	end
	
	if ngx then -- special ngx codes?
--		usecache=false
	end
	
	for i=1,100 do
	
		if usecache then
			data=cache.get(srv,cachename)
		end
	
		if type(data)=="string" and data=="*" then -- another thread is fetching the image we should wait for them
--log("sleeping")
		
			sys.sleep(1)
		
		elseif data then -- we got an image

--log("cache")
		
			srv.set_mimetype( data.mimetype )
			srv.set_header("Cache-Control","public") -- allow caching of page
			srv.set_header("Expires",os.date("%a, %d %b %Y %H:%M:%S GMT",os.time()+(60*60))) -- one hour cache
			srv.put(data.body)
			return
			
		elseif not data then -- we will go get it-
--log("web")
		
			local s1=srv.url_slash[ srv.url_slash_idx ]
			
			local lastarg=0
			local mode="fit" -- fit into a size, may produce an image of different aspect
			local hx=100
			local hy=100
			
			if s1=="crop" then 
			
				mode="crop" -- we force crop to keep aspect ratio
				hx=tonumber( srv.url_slash[ srv.url_slash_idx+1 ] or 100) or 100
				hy=tonumber( srv.url_slash[ srv.url_slash_idx+2 ] or 100) or 100
				lastarg=3
				
			elseif tonumber(s1) then 
			
				hx=tonumber( srv.url_slash[ srv.url_slash_idx+0 ] or 100) or 100
				hy=tonumber( srv.url_slash[ srv.url_slash_idx+1 ] or 100) or 100
				lastarg=2
				
			end
		
			local t={}
			for i=1,#srv.url_slash do local v=srv.url_slash[i]
				if i>=srv.url_slash_idx+lastarg then
					t[#t+1]=v
				end
			end

			if srv.uploads["filedata"] then -- special upload and return only

				data={ body=srv.uploads.filedata.data }

			elseif usecache then

				cache.put(srv,cachename,"*",10,"ADD_ONLY_IF_NOT_PRESENT") -- get a 10sec lock

			end

			if not data then -- grab from internets
				if t[1]=="data" then -- grab local data
				
					data=require("data").read(srv,t[2]) -- grab our data						
					if data then data.body=data.body or data.data end

				elseif t[1] then
				
					local url="http://"..table.concat(t,"/") -- build the remote request string
					if srv.query and #srv.query>0 then
						url=url.."?"..srv.query
					end
--log("Fetching : "..url)
					data=fetch.get(url) -- get from internets
					
				else
					return --fail
				end
				
			end

--			cache.del(srv,cachename) -- do this here to help clear later errors
				
			if data and data.body then -- we got data to serve
			
				local width=hx or 100
				local height=hy or 100

				if width<1 then width=1 end
				if width>1024 then width=1024 end

				if height<1 then height=1 end
				if height>1024 then height=1024 end

--log("thumb",wstr.dump(data))

				pcall(function()
					image=img.get( data.body , data.mimetype ) -- convert to image
				end)
				
-- crop it to desired aspect ratio and or size?
				local px=0
				local py=0
				local ix=image.width
				local iy=image.height

				if image and image.width>0 and image.height>0 then				
						
					-- adjust image
					if mode=="crop" then
						local sx=width
						local sy=height
						if (ix/iy) > (sx/sy) then -- widthcrop
							ix=math.floor(iy*(sx/sy))
							px=0-math.floor((image.width-ix)/2)
						elseif (iy/ix) > (sy/sx) then -- heightcrop
							iy=math.floor(ix*(sy/sx))
							py=0-math.floor((image.height-iy)/2)
						end

					end
					image=img.composite({
						format="DEFAULT",
						width=ix,
						height=iy,
--						color=0xffffffff, -- white, does not work?
						{image,px,py},
					}) -- and force it to a JPEG with a white? background

					image=img.resize(image,width,height) -- scale to desired size (keeps aspect ratio)

					if img.memsave then
						img.memsave(image,"png")
					else
						image.body=image.data -- rename raw file from data to body
					end
				else
					image=nil
				end
			end
				
			if not image then -- return empty image
				image=img.composite({width=hx or 100,height=hy or 100})
				img.memsave(image,"png")
			end
				
			if usecache then
				cache.put(srv,cachename,{
					body=image.body ,
					size=image.size ,
					width=image.width ,
					height=image.height ,
					format=image.format ,
					mimetype="image/"..string.lower(image.format),
					},60*60)
			end
		
			if usecache then -- controls local cache as well as server cache
				srv.set_header("Cache-Control","public") -- allow caching of page
				srv.set_header("Expires",os.date("%a, %d %b %Y %H:%M:%S GMT",os.time()+(60*60))) -- one hour cache	
			end

			srv.set_mimetype( "image/"..string.lower(image.format) )

			srv.put(image.body)
		
			return
			
		end
	end
end

