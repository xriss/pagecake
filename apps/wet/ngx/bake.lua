-- build or serve an nginx version of an app

local codepath=require("apps").default_paths() -- default search paths so things can easily be found
--if codepath then print("Using code found at : "..codepath.."lua") end

local bake_ngx=require("wetgenes.bake.ngx")

local tab={}
tab.arg={...}
tab.ngx_listen="*:9999"

bake_ngx.build(tab)

