

local dll="so"
local dir="../bin/"


package.cpath=	dir .. "?." .. dll ..
		";" .. dir .. "?/init." .. dll .. ";" ..
		package.cpath


package.path=	dir .. "lua/?.lua" ..
		";" .. dir .. "lua/?/init.lua" ..
		";../lua/?.lua" ..
		";../lua/?/init.lua" ..
		";"..package.path




config={}

