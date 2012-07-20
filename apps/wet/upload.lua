#!../../bin/exe/lua

local args={...}

function buildxml(name)
local s=[[<appengine-web-app xmlns="http://appengine.google.com/ns/1.0">
  <!-- Replace this with your application id from http://appengine.google.com -->
  <application>]]..name..[[</application>
  <version>1</version>
  <threadsafe>true</threadsafe>
</appengine-web-app>]]
	local fp=assert(io.open("private/WEB-INF/appengine-web.xml","w"))
	fp:write(s)
	fp:close();
end

sites={
--"notshi",
--"comicbang",
"cake-or-games",
--"boot-str",
}

if args[1] then sites=args end


for i,v in ipairs(sites) do

	print("\n***UPLOADING*** "..v.."\n\n")

	buildxml(v)
	
	os.execute("make upload")

end


buildxml("boot-str")
