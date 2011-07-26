
local dest=config.args[2]
local sess=config.args[3]

if not dest or not sess then

	put([[
Must specify a site domain eg host.local:8080 and a wet_session with admin permission to upload from your current ip like so

./do.lua write host.local:8080 0123456789abcdef0123456789abcdef

]])
	return

end


put("uploading to http://"..dest.."/ using wet_session "..sess.."\n")


require("ltn12")
require("mime")
require("socket")
require("socket.http")

local sxml=require("wetgenes.simpxml")
local json=require("wetgenes.json")
local wetstring=require("wetgenes.string")

local ssplit=wetstring.str_split

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


function upload_data(data)

	local req_body,boundary=multiparts(data)
--put(req_body)
	local res_body={}
	local suc, headers, code = socket.http.request{
		url="http://"..dest.."/data",
		method="POST",
		headers={
					["Content-type"]="multipart/form-data; boundary="..boundary,
					["Content-Length"] = #req_body,
					["Cookie"]="wet_session="..sess,
					["Referer"]="http://"..dest.."/data",
				},
		source = ltn12.source.string(req_body),
		sink = ltn12.sink.table(res_body),
	}
	put("Received "..suc.." "..headers.." "..#code.."\n")
--	table.foreach(res_body,print)

end


function b64enc(s)

	local source=ltn12.source.string(s)

	local ret={}
	local filter=ltn12.filter.chain(
	  mime.encode("base64"),
	  mime.wrap("base64")
	)
	
	local sink=ltn12.sink.chain(filter, ltn12.sink.table(ret) )
	
	ltn12.pump.all(source ,  sink)

	return table.concat(ret)
end



upload_data({
	submit={data="Upload"},
	dataid={data="0"},
	filename={data="test.txt"},
	mimetype={data="text/plain"},
	filedata={mimetype="application/octet-stream;charset=utf-8",encoding="binary",data=readfile("cache/data/teh.SkyPotatoe.png"),filename="test.txt"},
	})

