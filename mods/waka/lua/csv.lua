-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local sys=require("wetgenes.www.any.sys")

local wstr=require("wetgenes.string")

local html=require("base.html")

local fetch=require("wetgenes.www.any.fetch")
local stash=require("wetgenes.www.any.stash")

local log=require("wetgenes.www.any.log").log -- grab the func from the package

local json=require("wetgenes.json")

module("waka.csv")


-- Used to escape "'s by toCSV
local function escapeCSV (s)
  if string.find(s, '[,"]') then
    s = '"' .. string.gsub(s, '"', '""') .. '"'
  end
  return s
end

-- Convert from CSV string to table (converts a single line of a CSV file)
local function fromCSV (s,fieldstart)
	local t = {}        -- table to collect fields
	fieldstart = fieldstart or 1
	repeat
		-- next field is quoted? (start with `"'?)
		if string.find(s, '^"', fieldstart) then
			local a, c
			local i  = fieldstart
			repeat
				-- find closing quote
				a, i, c = string.find(s, '"("?)', i+1)
			until c ~= '"'    -- quote not followed by quote?
			if not i then return nil,'unmatched "' end
			local f = string.sub(s, fieldstart+1, i-1)
			table.insert(t, (string.gsub(f, '""', '"')))
			fieldstart = string.find(s, "[,\n]", i)
			if fieldstart then fieldstart=fieldstart+1 end
		else                -- unquoted; find next comma
			local nexti = string.find(s, "[,\n]", fieldstart)
			if nexti then
				table.insert(t, string.sub(s, fieldstart, nexti-1))
				fieldstart = nexti + 1
			else
				table.insert(t, string.sub(s, fieldstart))
				fieldstart=nil
			end
		end
	until (not fieldstart) or ( fieldstart > string.len(s) ) or ( s:sub(fieldstart-1,fieldstart-1) == "\n" )
	return t,fieldstart
end

-- Convert from table to CSV string
function toCSV (tt)
  local s = ""
  for _,p in pairs(tt) do
    s = s .. "," .. escapeCSV(p)
  end
  return string.sub(s, 2)      -- remove first comma
end



-- load and cache data stored in an external CSV (google docs lets you publush spreadsheetslike this)

function chunk_import(srv,chunk)

	local data	
	local meta=stash.get(srv,"waka_csv&"..chunk.url)
	
	if meta and meta.updated+(60*60) > os.time() then -- use cache
	
		data=meta.data
--log("using stash")
	
	else -- build cache

		local body

		local req,err=fetch.get(chunk.url) -- get from internets
		if err then
			log(err)
		end
		if req then body=req.body end -- check

		if type(body)=="string" then
		
			data={}
			
			local dat,ids
			local idx=1
			ids,idx=fromCSV(body,idx)
			if ids then
				repeat
					local done=false
					dat,idx=fromCSV(body,idx)
--log(tostring(idx)..":"..wstr.dump(dat))
					if dat then
						local t={}
						for n,id in ipairs(ids) do
							if id and id~="" and dat[n] and dat[n]~="" then
								if dat[n] then
									t[id]=dat[n]
								end
							end
						end
						data[#data+1]=t
					else
						done=true
					end
				until done or not idx
			end
		end
		
		stash.put(srv,"waka_csv&"..chunk.url,{data=data})		
	end

-- copy data into chunk
	if data then for i,v in ipairs(data) do chunk[i]=v end end

	if #chunk>0 then -- something to fix
	
		if chunk.random then
			local t={}
			for i=1,chunk.random do
				if #chunk>0 then
					t[#t+1]=table.remove( chunk , math.random(1,#chunk) )
				end
			end
			while #chunk>0 do table.remove(chunk) end
			for i=1,#t do
				chunk[i]=t[i]
			end
		end

		if chunk.offset and chunk.offset>0 then
			for i=1,chunk.offset do
				table.remove(chunk,1)
			end
		end

		if chunk.limit and chunk.limit>0 then
			while #chunk > chunk.limit do
				table.remove(chunk)
			end
		end

	end

	return chunk
end
