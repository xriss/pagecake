-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local json=require("wetgenes.json")

local dat=require("wetgenes.www.any.data")
local cache=require("wetgenes.www.any.cache")

local log=require("wetgenes.www.any.log").log -- grab the func from the package

local fetch=require("wetgenes.www.any.fetch")
local sys=require("wetgenes.www.any.sys")

local whtml=require("wetgenes.html")

local wstr=require("wetgenes.string")

--module
local M={ modname=(...) } ; package.loaded[M.modname]=M
function M.kind(srv) return "dimeload.paypal" end

local url_verify="https://www.paypal.com/cgi-bin/webscr?cmd=_notify-validate&"

M.default_props=
{
-- use txn_id/payment_status as the id, since we may? get the same txn_id with differnt statuses.
	msg="",			-- the full msg sent from paypal (VERIFIED)
	status="",   	-- payment_status  -- really only interested in "Completed"
	payer="",    	-- payer_email     -- check it was sent to *us*
	receiver="", 	-- receiver_email  -- who sent it
	gross=0,		-- mc_gross        -- how much
	currency="USD",	-- mc_currency     -- which currency? should only accept USD
	custom="",		-- custom          -- dumid string of player that we gave to paypal (where to credit dimes)
}

M.default_cache=
{
}



--[[
mc_gross=19.95&
protection_eligibility=Eligible&
address_status=confirmed&
payer_id=LPLWNMTBWMFAY&
tax=0.00&
address_street=1+Main+St&
payment_date=20%3A12%3A59+Jan+13%2C+2009+PST&
payment_status=Completed&
charset=windows-1252&
address_zip=95131&
first_name=Test&
mc_fee=0.88&
address_country_code=US&
address_name=Test+User&
notify_version=2.6&
custom=&
payer_status=verified&
address_country=United+States&
address_city=San+Jose&
quantity=1&
verify_sign=AtkOfCXbDm2hu0ZELryHFjY-Vb7PAUvS6nMXgysbElEn9v-1XcmSoGtf&
payer_email=gpmac_1231902590_per%40paypal.com&
txn_id=61E67681CH3238416&
payment_type=instant&
last_name=User&
address_state=CA&
receiver_email=gpmac_1231902686_biz%40paypal.com&
payment_fee=0.88&
receiver_id=S8XGHLYDW9T3S&
txn_type=express_checkout&
item_name=&
mc_currency=USD&
item_number=&
residence_country=US&
test_ipn=1&
handling_amount=0.00&
transaction_subject=&
payment_gross=19.95&
shipping=0.00
]]




--------------------------------------------------------------------------------
--
-- check that entity has initial data and set any missing defaults
-- the second return value is false if this is not a valid entity
--
--------------------------------------------------------------------------------
function M.check(srv,ent)

	local ok=true
	local c=ent.cache
		
	return ent
end


function M.button(srv,d)
	
	d.ipn=srv.url_base.."paypal/ipn"
	d.ret=srv.url_base.."paypal"

	d.custom="2@id.wetgnes.com"

	return wstr.replace([[
<script src="/js/dimeload/paypal-button.min.js?merchant={receiver}" 
    data-button="buynow" 
    data-name="Dimes" 
    data-quantity="100" 
    data-undefined_quantity="1"
    data-amount="0.1" 
    data-currency="USD" 
    data-shipping="0"
    data-no_shipping="1"
    data-no_note
    data-tax="0" 
    data-callback="{ipn}" 
    data-custom="{custom}"
    data-return="{ret}"
    data-env="sandbox"
></script>
]],d)

--[[


]]

end

dat.set_defs(M) -- create basic data handling funcs

dat.setup_db(M) -- make sure DB exists and is ready







