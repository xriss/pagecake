#!../../bin/dbg/lua
-- build or serve an nginx version of an app

local apps=require("apps")
apps.setpaths(nil,{apps.find_bin()})

local bake_ngx=require("wetgenes.bake.ngx")

local tab={}
tab.arg={...}
tab.port=8888

bake_ngx.build(tab)
