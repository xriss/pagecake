
console.log("OK");

naclmod = null;  // Global application object.
statusText = 'NO-STATUS';

var image_src_pix;
var image_src_fat;

// Indicate success when the NaCl module has loaded.
function moduleDidLoad(event) {
	$("#progress_nacl").attr("value",1);
  naclmod = document.getElementById('naclmod');
  updateStatus('SUCCESS');
  luasetup();
}

function moduleLoadProgress(event)
{
    var loadPercent = -1.0;
    if (event.lengthComputable && event.total > 0)
    {
		loadPercent = event.loaded / event.total * 100.0;
    }
	$("#progress_nacl").attr("value",loadPercent/100);
}


	function dec(s)
	{
		var s2="";
		if(s)
		{
			try
			{
				s2=s.split("%26").join("&").split("%3d").join("=").split("%25").join("%");
				return s2;
			}
			catch(e)
			{
				return "";
			}
		}
		return "";
	};
	
str_to_msg=function(s) // split a query like string
	{
	var i;
		var msg={};
		
		var aa=s.split("&");
		for(i in aa)
		{
		var v=aa[i];
			var va=v.split("=");
			msg[dec(va[0])]=dec(va[1]);
		}
		
		return msg;
	};
	
	
// Handle a message coming from the NaCl module.
function handleMessage(message_event) {
	if( typeof(message_event.data)=='string' )
	{
		var s=message_event.data;
		var sn=s.indexOf('\n');
		var msg=s.substring(0,sn);
		var dat=s.substring(sn+1);
//			console.log(msg);
		var m=str_to_msg(msg);
		if(m.cmd=="print") // basic print command
		{
			console.log(dat);
		}
		else
		if(m.cmd=="pix")
		{
			image_src_pix="data:image/png;base64,"+dat;
			$("#img_pix").attr("src",image_src_pix);
		}
		else
		if(m.cmd=="fat")
		{
			image_src_fat="data:image/png;base64,"+dat;
			$("#img_fat").attr("src",image_src_fat);
			
			var d={}
			
			d.pix=image_src_pix;
			d.fat=image_src_fat;
			d.day=Math.floor((new Date()).getTime()/(1000*60*60*24));
			
			var uploaded=function(dat){
				console.log(dat);
				$("#img_status").html(dat.status);
				if( dat.status != "OK" )
				{
					$("#img_pix").attr("src","");
					$("#img_fat").attr("src","");
				}
			};
			
			$.ajax({
				type: "POST",
				url: "/paint/upload",
				data: d,
				success: uploaded,
				dataType: "json"
			});

		}
		else
		if(m.cmd=="loading") // loading progress
		{
			$("#progress_zip").attr("value",Number(m.progress)/Number(m.total));
			if(m.progress==m.total)
			{
				$("#progress_all").hide();
			}
		}
		else
		{
			console.log(s);
		}
	}
}


function luaimg() {
	var t=naclmod.postMessage(
		'cmd=lua\n'+
		'local mime=require("mime")\n'+
		'local win=require("wetgenes.win")\n'+
		'local oven=win.oven\n'+
		'local images=oven.rebake(oven.modname..".images")\n'+
		'local grd=images[images.idx].grd\n'+
		'local s=mime.b64( (grd:save({fmt="png"})) )\n'+
		'win.js_post("cmd=pix\\n"..s)'+
		'local grd=images[images.idx].export_grd().g\n'+
		'local s=mime.b64( (grd:save({fmt="png"})) )\n'+
		'win.js_post("cmd=fat\\n"..s)'+
		'\n');
//	console.log(t);
}

function luasetup() {
	naclmod.postMessage(
		'cmd=lua\n'+
		'local win=require("wetgenes.win")\n'+
		'return win.\n'+
		'nacl_start({\n'+
		'zips={"'+head.fs.swankypaint_zip+'"},progress=function(t,p) win.js_post("cmd=loading&total="..t.."&progress="..p.."\\n") end\n'+
		'})\n');

	var requestAnimationFrame = function(callback,element){
				  window.setTimeout(callback, 1000 / 60);
			  };

	var update;      
		update=function() {
			requestAnimationFrame(update); // we need to always ask to be called again

  naclmod.postMessage('cmd=lua\n return require("wetgenes.win").nacl_pulse() ');

		};
		requestAnimationFrame(update); // start the updates
}

function updateStatus(opt_message) {
  if (opt_message)
	statusText = opt_message;
  var statusField = document.getElementById('statusField');
  if (statusField) {
	statusField.innerHTML = statusText;
  }
}


$(function(){

	console.log("Startin...");

	$('#listener')[0].addEventListener('load', moduleDidLoad,true);
	$('#listener')[0].addEventListener('message', handleMessage,true);
	$('#listener')[0].addEventListener('progress', moduleLoadProgress,true);
	
});
