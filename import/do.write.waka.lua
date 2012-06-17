
local socket=require("socket")
local http=require("socket.http")

local json=require("wetgenes.json")
local wstr=require("wetgenes.string")
local wsand=require("wetgenes.sandbox")

local lfs=require("lfs")


require_config_dest_sess()



	function dirwaka(d)
	
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
			
				if id2==".lua" then
				
					local wakaname=(d.."/"..id1):sub(#("cache/waka")+2)	
put("Editing "..wakaname.."\n")

					local met=readfile(d.."/"..id1..".lua")
					local m=wsand.lson(met)
					m.props.tags=nil
					local j=json.decode(m.props.json)
					
					local js=json.encode(m)
					upload_entity({
						json={data=js},
						})
				end
				
			elseif a.mode=="directory" then -- subdir
				if id~="." and id~=".." then -- ignore these
					dirwaka(fname)
				end
			end
		end
	end
	dirwaka("cache/waka") -- recurse downwards

