
// load lots of stuffs before we can do anything
head.js(
	head.fs.jquery_js,
	head.fs.ace_js,
	head.fs.ace_theme_eclipse_js,
	head.fs.ace_mode_html_js,
	head.fs.ace_mode_css_js,
	head.fs.ace_mode_javascript_js,
	function() {
		
		
(function($){  

// turn a text string into a bunch of chunks
var split_chunks=function(s){
	var c=[];

	var lines=s.split("\n");
	
	// find a chunk
	var c_find=function(c,n){
		for( var i=0 ; i<c.length ; i++ )
		{
			if(c[i].name==n)
			{
				return c[i];
			}
		}
		return undefined;
	};
	// create new chunk	
	var c_new=function(c,n){
		var r=c_find(c,n); // we auto use old chunk of same name if we can
		if(r===undefined)
		{
			r={};
			r.name=n;
			r.opts="";
			r.lines=[];
			c.push(r);
		}
		return r;
	};
	
	var cc;
	for( var i=0 ; i<lines.length ; i++ )
	{
		var v=lines[i];
		if( (v.substring(0,1)=="#") && (v.substring(1,2)!="#") )
		{
			if( v.substring(1,2)==" " ) // continue chunk
			{
				if(cc==undefined) { cc=c_new(c,"body"); } // default to body
				cc.opts+=" "+v.substring(2); // append opts
			}
			else // new or continue chunk
			{
				var n=v.substring(1);
				n=n.split(" ")[0]; // first word
				cc=c_new(c,n); // create a new chunk (or reuse old)
				cc.opts=v.substring(1+n.length+1); // append opts, skipping the #name
			}
		}
		else
		{
			if(cc==undefined) { cc=c_new(c,"body"); } // default to body
			cc.lines.push(v); // add a content line
		}
	}

	return c;
};

// turn a bunch of chunks into one text string
var join_chunks=function(c){
	var s="";
	var l=[];
	
	for( var i=0 ; i<c.length ; i++ )
	{
		var v=c[i];
		l.push("#"+v.name+" "+v.opts);
		for( var j=0 ; j<v.lines.length ; j++ )
		{
			l.push(v.lines[j]);
		}
	}

	return s=l.join("\n");
};


// turns a text area into a pure waka editing machine using ace

$.fn.wakaedit=function(opts)
{
	var defs = { 
		who: "#wakaedit",
		width:  960,
		height: 480
	};  
	opts = $.extend(defs, opts); 

		var edit_textarea=this;
		var edit_div=$("<div class='field'></div>");
		var edit_select=$("<select name='chunks'></select>");
		
		
//<option value='volvo'>Volvo</option><option value='saab'>Saab</option><option value='fiat'>Fiat</option><option value='audi'>Audi</option>

		var text=edit_textarea.val();
		
		var chunks=split_chunks(text);
		var mode=-1;
		
		var rechunks=function(){
			
			chunks=split_chunks(text);
			edit_select.empty();
			edit_select.append( $("<option value='-1'>Edit All Chunks</option>") );
			for( var i=0 ; i<chunks.length ; i++ )
			{
				var v=chunks[i];
				edit_select.append( $("<option value='"+i+"'>#"+v.name+" "+v.opts+"</option>") );
			}
			
		};
		
		var done_edit=function(){
			if(mode==-1) // build all chunks
			{
				text=editor.getSession().getValue();
				rechunks();
			}
			else
			{
				chunks[mode].lines=editor.getSession().getValue().split("\n");
				text=join_chunks(chunks);
			}
			edit_textarea.val( text );
		};
		
		rechunks();
		
		edit_textarea.after(edit_div);
		edit_textarea.after(edit_select);

		var css={width:opts.width,height:opts.height,position:"relative",margin:"auto",background:"#fff"};

// hide textbox and replace with new editor
		edit_textarea.css(css);
		edit_div.css(css);
		edit_textarea.hide();
		
		var editor = ace.edit(edit_div[0]);
		
// setup my defaults

		editor.getSession().setUseSoftTabs(false);
		editor.getSession().setUseWrapMode(false);
		
		var HtmlMode = require("ace/mode/html").Mode;
		var CssMode = require("ace/mode/css").Mode;
		var JavascriptMode = require("ace/mode/javascript").Mode;
		
		editor.getSession().setMode(new HtmlMode());
		
		editor.setTheme("ace/theme/eclipse");
		
		editor.getSession().setValue(text);
		
		window.aceEditor=editor;
		
		$(opts.who+" input").click(function(){
			done_edit();
			return true;
		});

		edit_select.bind("change keyup",function() {
			
			var num=Math.floor( edit_select.val()*1 );
			
			done_edit();
			mode=num;
			
			edit_select.val(mode+"");
						
			if(num>=0)
			{
				editor.getSession().setValue( chunks[num].lines.join("\n") );
			}
			else
			{
				editor.getSession().setValue(text);
			}


			editor.gotoLine(0);

			return true;
		});

	return this;
}

// magical auto callback
	if(window.auto_wakaedit ){
		var opts=window.auto_wakaedit;
		auto_wakaedit=undefined; // clear to flag as done
		$(opts.who+" textarea").wakaedit(opts);
	}

})(jQuery);


});
