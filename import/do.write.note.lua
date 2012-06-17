
local socket=require("socket")
local http=require("socket.http")

local json=require("wetgenes.json")
local wstr=require("wetgenes.string")
local wsand=require("wetgenes.sandbox")

local lfs=require("lfs")


require_config_dest_sess()


local ids=wsand.lson(readfile("cache/note/ids.lua"))

local notestate="root"

	function note_fixup(m)
		m.key.id=ids[m.key.id]
		m.props.group=ids[m.props.group] or 0
	end
	

	function dirnotedir(d)
	
		for id in lfs.dir(d) do
			local fname=d.."/"..id
			local a=lfs.attributes(fname)
			if a.mode=="directory" then -- subdir
				if id~="." and id~=".." then -- ignore these
					dirnotefile(fname)
				end
			end
		end
	end
			
	function dirnotefile(d)
			
		for id in lfs.dir(d) do
		
			local fname=d.."/"..id
			local a=lfs.attributes(fname)
			
			local id1=tostring(id)
			local id2=id1
			
			local ids=wstr.split(id1,".",false)
			
			if #ids>1 then -- got extension
				id2="."..ids[#ids]
				ids[#ids]=nil
				id1=table.concat(ids,".")
			end
			
			
			if a.mode=="file" then
			
				if id2==".lua" then
				

					local met=readfile(d.."/"..id1..".lua")
					local m=wsand.lson(met)
					
					if notestate=="root" then
					
						if m.props.group==0 then

							put("parsing root "..fname.."\n")

							m.props.tags=nil
							local j=json.decode(m.props.json)
							
							note_fixup(m)
							
							local js=json.encode(m)

							upload_entity({
								json={data=js},
								})
								
						end
						
					else
						if m.props.group>0 then

							put("parsing child "..fname.."\n")
							
							note_fixup(m)
							
							local js=json.encode(m)

							upload_entity({
								json={data=js},
								})
						end
					end
				end
			end
		end
	end
	
	
	notestate="root"
	dirnotedir("cache/note") -- recurse downwards
	notestate="child"
	dirnotedir("cache/note") -- recurse downwards

