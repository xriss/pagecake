
head.fs.gamecake_loader="http://play.4lfa.com/gamecake/gamecake_loader.js";

head.fs.swpaint_cake="http://play.4lfa.com/gamecake/swpaint.cake";
//head.fs.swpaint_cake="http://localhost:9999/swpaint.zip";

head.load(head.fs.jquery_js,head.fs.gamecake_loader,function(){
	
var image_src_pix;
var image_src_fat;

var msg_hook=function(msg,dat)
{
	if(msg.cmd=="pix")
	{
		image_src_pix="data:image/png;base64,"+dat;
		$("#img_pix").attr("src",image_src_pix);
		$("#img_pix").show();
	}
	else
	if(msg.cmd=="fat")
	{
		image_src_fat="data:image/png;base64,"+dat;
		$("#img_fat").attr("src",image_src_fat);
		$("#img_fat").show();
		
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
				$("#img_pix").hide();
				$("#img_fat").hide();
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
}

function IsValidImageUrl(url) {
}


var loaded_hook=function()
{
	var lson=$("#paint_configure");
	if(lson)
	{
		window.paint_configure(lson.text());
	}
	var pix=$("#img_pix");
	if(pix)
	{
		var src=pix.attr("src");
		if(src)
		{
			$("<img>", {
				src: src,
				load: function()
				{
					window.paint_set_image(src);
//					console.log("SRC : "+src);
					$("#img_pix").show();
					$("#img_fat").show();
				}
			});
		}
	}
}

// $("#lson").text()

window.paint_configure=function(lson) {
	var t=gamecake.post_message(
		'cmd=lua\n'+
		'local win=require("wetgenes.win")\n'+
		'local oven=win.oven\n'+
		'local paint=oven.rebake(oven.modname..".main_paint")\n'+
		'paint.quicksave_hook=function()\n'+
		' local images=oven.rebake(oven.modname..".images")\n'+
		' local mime=require("mime")\n'+
		' local grd=images.get().grd\n'+
		' local s=mime.b64( (grd:save({fmt="png"})) )\n'+
		' win.js_post("cmd=pix\\n"..s)'+
		' local grd=images.get().export_grd().g\n'+
		' local s=mime.b64( (grd:save({fmt="png"})) )\n'+
		' win.js_post("cmd=fat\\n"..s)\n'+
		' images.set_modified(false)\n'+
		'end\n'+
		'paint.configure( [==['+lson+']==] )\n');
}

// images will be sent to the msg hook
window.paint_get_images=function() {

	$("#img_status").html("");

	var t=gamecake.post_message(
		'cmd=lua\n'+
		'local win=require("wetgenes.win")\n'+
		'local oven=win.oven\n'+
		'local paint=oven.rebake(oven.modname..".main_paint")\n'+
		'paint.quicksave_hook()\n'+
		'\n');
//	console.log(t);
}

function base64ArrayBuffer(arrayBuffer) {
  var base64    = ''
  var encodings = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
 
  var bytes         = new Uint8Array(arrayBuffer)
  var byteLength    = bytes.byteLength
  var byteRemainder = byteLength % 3
  var mainLength    = byteLength - byteRemainder
 
  var a, b, c, d
  var chunk
 
  // Main loop deals with bytes in chunks of 3
  for (var i = 0; i < mainLength; i = i + 3) {
    // Combine the three bytes into a single integer
    chunk = (bytes[i] << 16) | (bytes[i + 1] << 8) | bytes[i + 2]
 
    // Use bitmasks to extract 6-bit segments from the triplet
    a = (chunk & 16515072) >> 18 // 16515072 = (2^6 - 1) << 18
    b = (chunk & 258048)   >> 12 // 258048   = (2^6 - 1) << 12
    c = (chunk & 4032)     >>  6 // 4032     = (2^6 - 1) << 6
    d = chunk & 63               // 63       = 2^6 - 1
 
    // Convert the raw binary segments to the appropriate ASCII encoding
    base64 += encodings[a] + encodings[b] + encodings[c] + encodings[d]
  }
 
  // Deal with the remaining bytes and padding
  if (byteRemainder == 1) {
    chunk = bytes[mainLength]
 
    a = (chunk & 252) >> 2 // 252 = (2^6 - 1) << 2
 
    // Set the 4 least significant bits to zero
    b = (chunk & 3)   << 4 // 3   = 2^2 - 1
 
    base64 += encodings[a] + encodings[b] + '=='
  } else if (byteRemainder == 2) {
    chunk = (bytes[mainLength] << 8) | bytes[mainLength + 1]
 
    a = (chunk & 64512) >> 10 // 64512 = (2^6 - 1) << 10
    b = (chunk & 1008)  >>  4 // 1008  = (2^6 - 1) << 4
 
    // Set the 2 least significant bits to zero
    c = (chunk & 15)    <<  2 // 15    = 2^4 - 1
 
    base64 += encodings[a] + encodings[b] + encodings[c] + '='
  }
  
  return base64
}

window.paint_set_image=function(url)
{
var xhr = new XMLHttpRequest();
	xhr.open('GET', url, true);
	xhr.responseType = 'arraybuffer';
	xhr.onload = function(e)
	{
		if (this.status == 200)
		{
			var x=base64ArrayBuffer(this.response);
			gamecake.post_message(
				'cmd=lua\n'+
				'local mime=require("mime")\n'+
				'local win=require("wetgenes.win")\n'+
				'local oven=win.oven\n'+
				'local images=oven.rebake(oven.modname..".images")\n'+
				'local paint=oven.rebake(oven.modname..".main_paint")\n'+
				'local image=images.get()\n'+
				'local x=mime.unb64([==['+x+']==])\n'+
				'if paint.done_setup then\n'+
				'image.load_grd( {data=x} )\n'+
				'else\n'+
				'paint.setup_load_this_img={data=x}\n'+
				'end\n'+
				'\n');

		}
	};
	xhr.send();
}

	$("#img_pix").hide(); // show them later if they are valid images
	$("#img_fat").hide();
	var gamecake=gamecake_loader({div:"#paint_draw",cakefile:head.fs.swpaint_cake,msg_hook:msg_hook,loaded_hook:loaded_hook});

});


