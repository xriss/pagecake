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
	payer="",    	-- payer_email     -- who sent it
	receiver="", 	-- receiver_email  -- check it was sent to *us*
	gross=0,		-- mc_gross        -- how much
	currency="USD",	-- mc_currency     -- which currency? should only accept USD
	custom="",		-- custom          -- dumid string of player that we gave to paypal (where to credit dimes)
}

M.default_cache=
{
}







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

--------------------------------------------------------------------------------
--
-- Load a list
--
--------------------------------------------------------------------------------
function M.list(srv,opts)
opts=opts or {}

	local list={}
	
	local q={
		kind=M.kind(srv),
		limit=opts.limit or 10,
		offset=0,
		}
	q[#q+1]={"sort","updated","DESC"}
	if opts.custom then
		q[#q+1]={"filter","custom","==",opts.custom}
	end
	
	local ret=dat.query(q)
		
	for i=1,#ret.list do local v=ret.list[i]
		dat.build_cache(v)
	end

	return ret.list
end


--------------------------------------------------------------------------------
--
-- build a htlm list of payments
--
--------------------------------------------------------------------------------
function M.paylist(srv,opts)

local t={}
local l=M.list(srv,{custom=opts.custom,limit=100})

	if l[1] then

		t[#t+1]=[[
		<ul class="paylist">
]]
		for i,v in ipairs(l) do
			local c=v.cache
			t[#t+1]=wstr.replace([[
			<li lass="paylist_item" >{amount} from {payer} on {date}</li>
]],{
	amount= (c.currency=="USD" and "$" or c.currency)..c.gross,
	payer=c.payer,
	date=os.date("%c",c.created),
})
		end
		t[#t+1]=[[
		</ul>
]]
	end

	return table.concat(t,"")
end

function M.button(srv,d)
	
	d.receiver=srv.opts("paypal","receiver")
	d.ipn=srv.url_base.."paypal/ipn"
	d.ret=srv.url_base.."paypal"
	d.quantity=d.quantity or 100

	return wstr.replace([[
<script src="/js/dimeload/paypal-button.min.js?merchant={receiver}" 
    data-button="buynow" 
    data-name="Dimes" 
    data-quantity="{quantity}" 
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
></script>
]],d)

--[[
    data-env="sandbox"
]]

end


local function url_encode(t)
	local l={}
	for n,v in pairs(t) do
		l[#l+1]=n.."="..whtml.url_esc(v)
	end
	return table.concat(l,"&")
end

function M.ipn(srv)

-- srv.body is expected to be the urlencoded data that paypal just sent us

	local test=fetch.get("https://www.paypal.com/cgi-bin/webscr?cmd=_notify-validate&"..srv.body)
	
	if test.body=="VERIFIED" then -- data is good

		local p={}
		local a=wstr.split(srv.body,"&")
		for i,v in ipairs(a) do
			if v~="" then
				local s=wstr.split(v,"=")
				if s[1] and s[2] then
					p[ s[1] ]=wstr.url_decode( s[2] )
				end
			end
		end
--log(wstr.dump(p))
	-- first some sanity to make sure that we received this payment, ignore it if it wasnt for us
	-- this is an easy malicous thing to do in order to fake payment
		if p.receiver_email and p.receiver_email==srv.opts("paypal","receiver") and p.txn_id and p.payment_status then
			local id=p.txn_id.."_"..p.payment_status
			local it=M.set(srv,id,function(srv,e) -- create or update
				local c=e.cache
				
				c.msg=srv.body -- raw data
				
				c.status=p.payment_status
				c.payer=p.payer_email
				c.receiver=p.receiver_email
				c.gross=p.mc_gross
				c.currency=p.mc_currency11
				c.custom=p.custom

				return true
			end)
			return it -- return the data we just logged, nil for no data and a bad payment
		end

	end
	
	return nil
end

dat.set_defs(M) -- create basic data handling funcs

dat.setup_db(M) -- make sure DB exists and is ready







