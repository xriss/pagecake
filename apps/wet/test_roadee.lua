local http = require("socket.http")
local ltn12 = require("ltn12")

local dat=io.open("/home/kriss/Downloads/swpaint.zip"):read("*a")

local boundary="BOUNDARY--"..math.random(1000,9999)..math.random(1000,9999)..math.random(1000,9999)..math.random(1000,9999)
repeat
	boundary=boundary..math.random(1000,9999)
until not (string.find(dat,boundary))

local data
local chunks={}
local append_boundary=function() chunks[#chunks+1]=("--%s\r\n"):format(boundary) end
local append_data = function(it)
	append_boundary()
	chunks[#chunks+1]=("Content-Disposition: form-data; name=\"%s\""):format(it.name)
	if it.filename then chunks[#chunks+1]=("; filename=\"%s\""):format(it.filename) end
	if it.type then chunks[#chunks+1]=("\r\nContent-Type: %s"):format(it.type) end
	if it.encoding then chunks[#chunks+1]=("\r\nContent-Transfer-Encoding: %s"):format(it.encoding) end
	chunks[#chunks+1]="\r\n\r\n"
	chunks[#chunks+1]=it.data
	chunks[#chunks+1]="\r\n"
end
local concat_data = function()
	data=table.concat(chunks,"")
end

append_data{data="Upload",name="submit"}
append_data{data=dat,name="data",filename="test.zip"}
append_boundary()
concat_data()

local response_body={}
local  body, code, headers, status = http.request{
    url = "http://host.local:8888/roadee/upload",
    method = "POST",
    headers = {
        ["Content-Type"] =  "multipart/form-data; boundary="..boundary,
        ["Content-Length"] = #data
    },
    source = ltn12.source.string(data),
    sink = ltn12.sink.table(response_body)
}
body=table.concat(response_body)

print('status:' .. tostring(status))
print('code:' .. tostring(code))
print('body:' .. tostring(body))


