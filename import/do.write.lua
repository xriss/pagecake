
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

local lfs=require("lfs")

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


function upload_waka(wakaname,data)

	local req_body,boundary=multiparts(data)
--put(req_body)
	local res_body={}
	local url="http://"..dest.."/?cmd=edit&page="..wakaname
	local suc, headers, code = socket.http.request{
		url=url,
		method="POST",
		headers={
					["Content-type"]="multipart/form-data; boundary="..boundary,
					["Content-Length"] = #req_body,
					["Cookie"]="wet_session="..sess,
					["Referer"]=url,
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




function dirdata()

	local d="cache/data"
	for id in lfs.dir(d) do
		local fname=d.."/"..id
		
		local id1=tostring(id)
		local id2=id1
		
		local ids=ssplit(".",id1,false)
		
		if #ids>1 then -- use extension as filename
			id2="."..ids[#ids]
			ids[#ids]=nil
			id1=table.concat(ids,".")
		end
		
		
		
		local a=lfs.attributes(fname)
		
		if a.mode=="file" then
		
			local dat=readfile(fname)

	put("Uploading /data/"..id.."\n")

			upload_data({
				submit={data="Upload"},
				dataid={data=id1},
				filename={data=id2},
				mimetype={data=""},
				filedata={mimetype="application/octet-stream;charset=utf-8",encoding="binary",data=dat,filename=id2},
				})

		
		elseif a.mode=="directory" then -- subdir

--[[	
			for vv in lfs.dir(fname) do
			
				local fname=d.."/"..id
				
				local a=lfs.attributes(fname)
				
				if a.mode=="file" then -- only one file

					break
				end
			
			end
]]
		end
	end
end
--	dirdata(d)


	local based="cache/waka"
	function dirwaka(d)
	
		for id in lfs.dir(d) do
			local fname=d.."/"..id
			
			local id1=tostring(id)
			local id2=id1
			
			local ids=ssplit(".",id1,false)
			
			if #ids>1 then -- got extension
				id2="."..ids[#ids]
				ids[#ids]=nil
				id1=table.concat(ids,".")
			end
			
			local a=lfs.attributes(fname)
			
			if a.mode=="file" then
			
				if id2==".txt" then
				
					local dat=readfile(fname)
					
					local wakaname=(d.."/"..id1):sub(#based+2)
					
	put("Editing "..wakaname.."\n")

					upload_waka(wakaname,{
						submit={data="Save"},
						text={data=dat},
						})
						
				end
				
			elseif a.mode=="directory" then -- subdir
			
				if id~="." and id~=".." then -- ignore these
					dirwaka(fname)
				end
			end
		end
	end
	dirwaka(based)

--[[

	local wakaname="test"
	local dat="Screw you hippy!"
	put("Editing "..wakaname.."\n")

	upload_waka(wakaname,{
		submit={data="Save"},
		text={data=dat},
		})

]]
