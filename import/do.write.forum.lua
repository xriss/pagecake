
local dest=config.args[3]
local sess=config.args[4]

if not dest or not sess then

	put([[
Must specify a site domain eg host.local:8080 and a wet_session with admin permission to upload from your current ip like so

./do.lua write note host.local:8080 0123456789abcdef0123456789abcdef

]])
	return

end


put("uploading to http://"..dest.."/ using wet_session "..sess.."\n")

local lfs=require("lfs")

local ltn12=require("ltn12")
local mime=require("mime")
local socket=require("socket")
local http=require("socket.http")

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
			if type(v)=="string" then
				if v:find(boundary,1,true) then -- clash
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
		msg[#msg+1] = tostring(v)
		msg[#msg+1] = "\r\n"
	end
	
	msg[#msg+1] = "--"..boundary.."--\r\n"

	return table.concat(msg), boundary
end


function upload_note(data)

	local req_body,boundary=multiparts(data)
--put(req_body)
	local res_body={}
	local url="http://"..dest.."/note/api"
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
	put("Received "..(suc or "").." "..(headers or "").." "..#(code or "").."\n")
--	table.foreach(res_body,print)

end





	local based="cache/note"
	function dirnote(d)
	
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
			
				if id2==".json" then
				
					local dat=readfile(fname)
					
					local threadname=(d.."/"..id1):sub(#based+2)
					
put("Parsing "..threadname.." this may take a little while...\n")
	
					local threads=json.decode(dat).threads
					
					local ts={}
					for i,v in pairs(threads) do
						ts[#ts+1]=v
					end
					
					for i,v in pairs(ts) do
					
put("Sending thread "..tostring(v[1].uid).." "..i.."/"..(#ts).."\n")

						local d={}
						
						d.json=json.encode({thread=v})
						d.cmd="thread"

						upload_note(d)
						
					end
	
				end
				
			elseif a.mode=="directory" then -- subdir
			
				if id~="." and id~=".." then -- ignore these
					dirnote(fname)
				end
			end
		end
	end
	dirnote(based)
