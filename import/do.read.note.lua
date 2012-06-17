
local socket=require("socket")
local http=require("socket.http")

local json=require("wetgenes.json")
local wstr=require("wetgenes.string")



require_config_dest_sess()


local docont=true
local offset=0
local limit=10
local ids={}

while docont do
	docont=false
	local b,t
	b=geturl(config.dest.."admin/api",{cmd="read",limit=limit,offset=offset,kind="note.comments"})
	t=json.decode(b.body)
	
	for i,v in ipairs(t.list) do
		if v.props.group then
			if tonumber(v.props.group)>=0 then -- ignore meta
			
				ids[(v.key.id)]=v.props.author.."*"..string.format("%.3f",v.props.created)
			
				local fname="cache/note/"..v.props.author.."/"..string.format("%.3f",v.props.created)
				print( fname )
				
				create_dir_for_file(fname..".lua")
				local fp=io.open(fname..".lua","w")
				fp:write(wstr.serialize(v))
				fp:close()
			end
			docont=true
		end
	end
	
	offset=offset+limit
end

	local fname="cache/note/ids"
	print( fname )
	
	create_dir_for_file(fname..".lua")
	local fp=io.open(fname..".lua","w")
	fp:write(wstr.serialize(ids))
	fp:close()


