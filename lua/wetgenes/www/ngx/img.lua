-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local log=require("wetgenes.www.any.log").log
local fetch=require("wetgenes.www.any.fetch")
local wstr=require("wetgenes.string")
--TODO:grd local grd=require("wetgenes.grd")

module(...)
local _M=require(...)
package.loaded["wetgenes.www.any.img"]=_M




function get(data,fmt)
--	log("img.get:")
	

--	local gfmt=grd.HINT_PNG
--	if fmt=="jpeg" or fmt=="image/jpeg" then gfmt=grd.HINT_JPG end
--	if fmt=="gif" or fmt=="image/gif" then gfmt=grd.HINT_GIF end

	local g=grd.create()
	g:load_data(data)

	return g
end

function resize(g,x,y)
--	log("img.resize:")

	if g.width==0 or g.height==0 then return nil end

	g:convert(grd.FMT_U8_RGBA) -- need this format

	if ( x * g.height/g.width ) <= y then -- aspect fits at maximum width

		g:scale( x , x * g.height/g.width , 1 )
	
	else

		g:scale( y * g.width/g.height , y , 1 )
	
	end

	return g
end

function composite(t)
--log("img.composite:",wstr.dump(t))

	local go=grd.create(grd.FMT_U8_RGBA,t.width,t.height,1)
	
	if t.color then
		go:clear(t.color)
	end
	
	for i,v in ipairs(t) do
		v[1]:convert(grd.FMT_U8_RGBA_PREMULT)
		assert(go:blit(v[1],v[2],v[3],v[4],v[5],v[6],v[7]))
	end
	
	return go
end


function memsave(g,fmt)

	local gfmt=grd.HINT_PNG
	if fmt then fmt=fmt:lower() end
	if fmt=="jpeg" then gfmt=grd.HINT_JPG else fmt="png" end
--[[
	local function file_read(filename)
		local fp=assert(io.open(filename,"rb"))
		local d=assert(fp:read("*a"))
		fp:close()
		return d
	end
	
	local filename=os.tmpname()
	
	g:save(filename,gfmt)
	
	g.body=file_read(filename)
	g.format=fmt
	
	os.remove(filename)
]]
	g.body=g:save({fmt=fmt})

	return g
end
