
local socket=require("socket")
local http=require("socket.http")

local json=require("wetgenes.json")
local wstr=require("wetgenes.string")




local dest=config.args[3]
local sess=config.args[4]

if not dest or not sess then

	put([[
Must specify a site domain eg host.local:8080 and a wet_session with admin permission to access from your current ip like so

./do.lua read waka http://host.local:8080/ 0123456789abcdef0123456789abcdef

]])
	return

end


function geturl(url,args)

	local sarg={}
	for i,v in pairs(args) do
		sarg[#sarg+1]=tostring(i).."="..tostring(v)
	end
	sarg=table.concat(sarg,"&")

	local res_body={}
	local req_body=""
	local suc, headers, code = socket.http.request{
		url=url.."?"..sarg,
		method="GET",
		headers={
					["Content-Length"] = #req_body,
					["Cookie"]="wet_session="..sess,
					["Referer"]=url,
				},
		source = ltn12.source.string(req_body),
		sink = ltn12.sink.table(res_body),
	}

	return {headers=headers,code=code,body=table.concat(res_body)}
end

local docont=true
local offset=0
local limit=10
local ids={}

while docont do
	docont=false
	local b,t
	b=geturl(dest.."admin/api",{cmd="read",limit=limit,offset=offset,kind="note.comments"})
	t=json.decode(b.body)
	
	for i,v in ipairs(t.list) do
		if v.props.group then
			if tonumber(v.props.group)>=0 then -- ignore meta
			
				ids[tostring(v.key.id)]=v.props.author.."/"..v.props.created
			
				local fname="cache/note/"..v.props.author.."/"..v.props.created
				print( fname )
				
				create_dir_for_file(fname..".json")
				local fp=io.open(fname..".json","w")
				fp:write(json.encode(v))
				fp:close()
			end
			docont=true
		end
	end
	
	offset=offset+limit
end

	local fname="cache/note/ids"
	print( fname )
	
	create_dir_for_file(fname..".json")
	local fp=io.open(fname..".json","w")
	fp:write(json.encode(ids))
	fp:close()

