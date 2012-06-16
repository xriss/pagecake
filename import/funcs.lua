
local socket=require("socket")
local http=require("socket.http")

local json=require("wetgenes.json")
local lfs=require("lfs")
local wstr=require("wetgenes.string")

function require_config_dest_sess()
	config.dest=config.args[3]
	config.sess=config.args[4]

	if not config.dest or not config.sess then

		put([[
	Must specify a site domain eg host.local:8080 and a wet_session with admin permission to access from your current ip like so

	./do.lua read waka http://host.local:8080/ 0123456789abcdef0123456789abcdef

	]])
		return

	end
end

function geturl(url,args)

	local sarg={}
	for i,v in pairs(args) do
		sarg[#sarg+1]=tostring(i).."="..tostring(v)
	end
	if sarg[1] then
		sarg="?"..table.concat(sarg,"&")
	else
		sarg=""
	end
	local res_body={}
	local req_body=""
	local suc, headers, code = socket.http.request{
		url=url..sarg,
		method="GET",
		headers={
					["Content-Length"] = #req_body,
					["Cookie"]="wet_session="..config.sess,
					["Referer"]=url,
				},
		source = ltn12.source.string(req_body),
		sink = ltn12.sink.table(res_body),
	}

	return {headers=headers,code=code,body=table.concat(res_body)}
end

-- make some multiparts data
function multiparts(data)

	local boundary
	local needbound=true
	
	while needbound do -- find a magic string
		boundary = 		math.random(1000,9999) .. 
						math.random(1000,9999) ..
						math.random(1000,9999) ..
						math.random(1000,9999) ..
						math.random(1000,9999) ..
						math.random(1000,9999) ..
						math.random(1000,9999) ..
						math.random(1000,9999)
		needbound=false
		for k,v in pairs(data) do
			if type(v.data)=="string" then
				if v.data:find(boundary,1,true) then -- clash
					needbound=true
				end
			end
		end
	end

	local msg = {}

--	msg[#msg+1] = "Content-Type: multipart/form-data; boundary="..boundary.."\r\n"
--	msg[#msg+1] = "\r\n"
	
	for k,v in pairs(data) do
		msg[#msg+1] = "--"..boundary.."\r\n"
		if v.filename then
			msg[#msg+1] = "Content-Disposition: form-data; name=\""..k.."\"; filename=\""..v.filename.."\"\r\n"
		else
			msg[#msg+1] = "Content-Disposition: form-data; name=\""..k.."\"\r\n"
		end
		msg[#msg+1] = "Content-Type: "..(v.mimetype or "text/plain;charset=utf-8").."\r\n"
		msg[#msg+1] = "Content-Transfer-Encoding: "..(v.encoding or "quoted-printable").."\r\n"
		msg[#msg+1] = "\r\n"
		msg[#msg+1] = tostring(v.data)
		msg[#msg+1] = "\r\n"
	end
	
	msg[#msg+1] = "--"..boundary.."--\r\n"

	return table.concat(msg), boundary
end


function upload_waka(wakaname,data)

	local req_body,boundary=multiparts(data)
--put(req_body)
	local res_body={}
	local url=config.dest.."?cmd=edit&page="..wakaname
	local suc, code , headers = assert(socket.http.request{
		url=url,
		method="POST",
		headers={
					["Content-Type"]="multipart/form-data; boundary="..boundary,
					["Content-Length"] = #req_body,
					["Cookie"]="wet_session="..config.sess,
					["Referer"]=config.dest,
				},
		source = ltn12.source.string(req_body),
		sink = ltn12.sink.table(res_body),
	})
	put("Received "..suc.." "..code.."\n") -- wstr.serialize(headers)
--	table.foreach(res_body,print)

end

function upload_data(data)

	local req_body,boundary=multiparts(data)
--put(req_body)
	local res_body={}
	local suc, code , headers = socket.http.request{
		url=config.dest.."data",
		method="POST",
		headers={
					["Content-type"]="multipart/form-data; boundary="..boundary,
					["Content-Length"] = #req_body,
					["Cookie"]="wet_session="..config.sess,
					["Referer"]=config.dest.."data",
				},
		source = ltn12.source.string(req_body),
		sink = ltn12.sink.table(res_body),
	}
	put("Received "..suc.." "..code.."\n") -- wstr.serialize(headers)
--	table.foreach(res_body,print)

end

-----------------------------------------------------------------------------
--
-- replace {tags} in the string with data provided
-- allow sub table look up with a.b.c.d.etc notation
--
-----------------------------------------------------------------------------
function replace(a,d)

	if not d then return a end -- no lookups possible

-- lookup function

	local replace_lookup
	replace_lookup=function(a,d) -- look up a in table d

		local t=d[a]
		if t then
			return tostring(t) -- simple find, make sure we return a string
		end
	
		local a1,a2=string.find(a, "%.") -- try and split on first "."
		if not a1 then return nil end -- didnt find a dot so return nil
	
		a1=string.sub(a,1,a1-1) -- the bit before the .
		a2=string.sub(a,a2+1) -- the bit after the .
	
		local dd=d[a1] -- use the bit before the dot to find the sub table
	
		if type(dd)=="table" then -- check we got a table
			return replace_lookup(a2,dd) -- tail call this function
		end
	
		return nil -- couldnt find anything return nil
	end

-- perform replace on {strings}

	return (string.gsub( a , "{([%w%._%-]-)}" , function(a)

		return replace_lookup(a,d) or ("{"..a.."}")
	
	end )) -- note gsub is in brackets so we just get its *first* return value

end


-- print a string with optional replacements

put=function(a,d)
	io.write(replace(a,d))
end


--a json cache read/write should be reasonably fast

getcache=function(name)
	local fp=io.open(name,"r")
	local d
	if fp then
		d=fp:read("*all")
		fp:close()
	end
	local r={}
	if d then r=json.decode(d) or {} end
	return r
end

putcache=function(name,tab)
	local s=json.encode(tab)
	local fp=io.open(name,"w")
	fp:write(s)
	fp:close()
	return d
end


-- get the text contents of a file

readfile=function(name)
	local fp=io.open(name,"r")
	local d=fp:read("*all")
	fp:close()
	return d
end

file_exists=function(name)
	local fp=io.open(name,"r")
--print(fp)
	if fp then fp:close() return true end
	return false
end

writefile=function(name,data)
	local fp=io.open(name,"w")
	fp:write(data)
	fp:close()
end

copyfile=function(frm,too)
	local text=readfile(frm)
	writefile(too,text)
end


exec=function(cmdline)
	print(cmdline)
	os.execute(cmdline)
end

--
-- given a filename make sure that its containing directory exists
--
create_dir_for_file=function(n)
	local t={}
	for w in string.gmatch(n, "[^/]+") do t[#t+1]=w end
	local s=""
	t[#t]=nil -- remove the filename
	for i,v in ipairs(t) do
		s=s..v
		lfs.mkdir(s)
		s=s.."/"
	end
end

