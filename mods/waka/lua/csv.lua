-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local sys=require("wetgenes.www.any.sys")

local wstr=require("wetgenes.string")

local html=require("base.html")

local fetch=require("wetgenes.www.any.fetch")

local cache=require("wetgenes.www.any.cache")

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

	local savebody=false
	local body

	if not body then -- try internet

		local req,err=fetch.get(chunk.url) -- get from internets
		if err then
			log(err)
		end
		if req then body=req.body end -- check
	
		savebody=true
	end
	
	if type(body)=="string" then	

		if savebody then  -- cache string for later
		end

		local dat,ids
		local idx=1
		ids,idx=fromCSV(body,idx)
		if ids then
			repeat
				local done=false
				dat,idx=fromCSV(body,idx)
				if dat then
					local t={}
					for n,id in ipairs(ids) do
						if id and id~="" and dat[n] and dat[n]~="" then
							if dat[n] then
								t[id]=dat[n]
							end
						end
					end
					chunk[#chunk+1]=t
				else
					done=true
				end
			until done or not idx
		end
	end
	
--	chunk.plate="{it.ID} -> {it.URL} <br/>\n"

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

--[[

function getwaka(srv,opts)

	local s=""
	local t,err=get(srv,opts)
	local o={}
	
	if t and t.table and t.table.rows  and t.table.cols then
		for i,v in ipairs(t.table.rows) do
			local tab={}
			for i,v in ipairs(v and v.c or {} ) do
				local id=(t.table.cols[i].id) or i
				local s=(v and v.v) or ""
				
				-- stuff coming in seems to be a bit crazy, this forces it to 7bit ascii
				if type(s)=="string" then s=s:gsub("[^!-~%s]","") end

				tab[id]=s
			end
			if opts.hook then -- update this stuff?
				opts.hook(tab)
			end
			for id,s in pairs(tab) do
				o[#o+1]="{"..id.."=}"
				o[#o+1]=s
				o[#o+1]="{="..id.."}"
			end
			o[#o+1]="{"..(opts.plate or "item").."}"
		end
		s=table.concat(o)
	else
		s=err or "GSHEET IMPORT fail please reload page to try again."
	end

	return s
end

--
-- get a table given the opts
--
function get(srv,opts)

	opts.offset=opts.offset or 0

--"http://spreadsheets.google.com/tq?tq=select+*+limit+10+offset+0+&key=tYrIfWhE3Q1i8t8VLKgEZSA"

	local tq=(opts.query or "select *").." limit "..opts.limit.." offset "..opts.offset
	local url

	url="http://spreadsheets.google.com/tq?key="..opts.key
	url=url.."&v"..opts.v
	url=url.."&tq="..url_esc(tq)

	local cachename="waka_gsheet&"..url_esc(url)
	local datastr
	local err
	
	local data=cache.get(srv,cachename) -- check cache
	if data then return data end
	
	if not datastr then -- we didnt got it from the cache?
		datastr,err=fetch.get(url) -- get from internets
		if err then
			log(err)
		end
		if datastr then datastr=datastr.body end -- check
--log("DATASTR : ",datastr)	
		if type(datastr)=="string" then -- trim some junk get string within the outermost {}
			datastr=datastr:match("^[^{]*(.-)[^}]*$")
		end
	end
	
	
--	local origsize=0
	
	if datastr then

--log("DATASTR : ",datastr)	
--		origsize=datastr:len() or 0
		local suc
		suc,data=pcall(function() return json.decode(datastr) end) -- convert from json, hopefully
		if not suc then data=nil end
		
		if data then cache.put(srv,cachename,data,60*60) end
	end
		
	return data,err
end
]]
