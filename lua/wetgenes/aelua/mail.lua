

local core=require("wetgenes.aelua.mail.core")

local os=os

module("wetgenes.aelua.mail")


function send(...)
	return core.send(...)
end
