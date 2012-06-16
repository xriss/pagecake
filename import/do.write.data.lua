
local socket=require("socket")
local http=require("socket.http")

local json=require("wetgenes.json")
local wstr=require("wetgenes.string")
local wsand=require("wetgenes.sandbox")

local lfs=require("lfs")


require_config_dest_sess()



	function dirdata(d)
	
		for id in lfs.dir(d) do
			local fname=d.."/"..id
			
			local id1=tostring(id)
			local id2=id1
			
			local ids=wstr.split(id1,".",false)
			
			if #ids>1 then -- got extension
				id2="."..ids[#ids]
				ids[#ids]=nil
				id1=table.concat(ids,".")
			end
			
			local a=lfs.attributes(fname)
			
			if a.mode=="file" then
			
				if id2==".data" then
				
					local dat=readfile(fname)
					local met=readfile(d.."/"..id1..".lua")
					
					local filename=(d.."/"..id1):sub(#("cache/data")+2)
					
	put("Data "..filename.." "..#dat.."\n")
	
					local m=wsand.lson(met)
					local j=json.decode(m.props.json)
--put(wstr.serialize(m))

				upload_data({
					submit={data="Upload"},
					dataid={data=filename},
					filename={data=j.filename},
					mimetype={data=m.props.mimetype},
					filedata={mimetype="application/octet-stream;charset=utf-8",encoding="binary",data=dat,filename=j.filename},
					})
					
				end
				
			elseif a.mode=="directory" then -- subdir
				if id~="." and id~=".." then -- ignore these
--					dirdata(fname)
				end
			end
		end
	end
	dirdata("cache/data") -- recurse downwards

