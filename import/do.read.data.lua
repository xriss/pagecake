
local socket=require("socket")
local http=require("socket.http")

local json=require("wetgenes.json")
local wstr=require("wetgenes.string")



require_config_dest_sess()


local docont=true
local offset=0
local limit=10
while docont do
	docont=false
	local b,t
	b=geturl(config.dest.."admin/api",{cmd="read",limit=limit,offset=offset,kind="data.meta"})
	t=json.decode(b.body)
	
	for i,v in ipairs(t.list) do
		local fname="cache/data/"..v.key.id
		print( fname )
		if v.props.json then
			local j=json.decode(v.props.json)
			create_dir_for_file(fname..".lua")
			local fp=io.open(fname..".lua","w")
			fp:write(wstr.serialize(v))
			fp:close()
			local fd=geturl(config.dest.."data"..v.props.pubname,{})
			if fd.body then
				local fp=io.open(fname..".data","wb")
				fp:write(fd.body)
				fp:close()
			end
			docont=true
		end
	end
	
	offset=offset+limit
end


