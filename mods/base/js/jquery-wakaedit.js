
// load lots of stuffs before we can do anything
head.load(
	"/js/base/codemirror/addon/dialog/dialog.css",
	"/js/base/codemirror/addon/search/match-highlighter.css",
	"/js/base/codemirror/codemirror.css"
);
head.js(
	head.fs.jquery_js,
	head.fs.jquery_cookie_js,
	"/js/base/codemirror/codemirror.js",
	"/js/base/codemirror/addon/dialog/dialog.js",
	"/js/base/codemirror/addon/search/search.js",
	"/js/base/codemirror/addon/search/searchcursor.js",
	"/js/base/codemirror/addon/search/match-highlighter.js",
	"/js/base/codemirror/addon/edit/matchbrackets.js",
	"/js/base/codemirror/addon/edit/matchtags.js",
	"/js/base/codemirror/addon/fold/xml-fold.js",
	"/js/base/codemirror/mode/xml/xml.js",
	"/js/base/codemirror/mode/javascript/javascript.js",
	"/js/base/codemirror/mode/css/css.js",
	"/js/base/codemirror/mode/vbscript/vbscript.js",
	"/js/base/codemirror/mode/htmlmixed/htmlmixed.js",
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


// turns a text area into a pure waka editing machine using codemirror

$.fn.wakaedit=function(opts)
{
	var defs = { 
		who: "#wakaedit",
		width:  960,
		height: 480,
		show_buttons:true
	};  
	opts = $.extend(defs, opts); 
	
		var qq = {};
		$.each(document.location.search.substr(1).split('&'),function(c,q){
			var i = q.split('=');
			qq[i[0].toString()] = i[1].toString();
		});

		var page=qq.page;

		var editor;


		var edit_textarea=$(this).find("textarea");
		var edit_div=$("<div class='field cake_field'></div>");
		var edit_check=$("<input name=\"usecm\" type=\"checkbox\">");
		var edit_select=$("<select name='chunks' class='cake_wakaedit_chunks'></select>");

		var edit_result=$("<span>...</span>");
		var edit_title=$("<span>"+page+"</span>");
		var edit_button_save=$("<a class=\"cake_button\" >Save</a>");
		var edit_button_view=$("<a class=\"cake_button\" href=\""+page+"\" target=\"_blank\" >View</a>");
		
		var text=edit_textarea.val();
		
		var chunks=split_chunks(text);
		var mode=-1;
		
		var rechunks=function(){
			
			chunks=split_chunks(text);
			edit_select.empty();
			edit_select.append( $("<option value='-1'>Edit All Chunks</option>") );
			if(editor)
			{
				for( var i=0 ; i<chunks.length ; i++ )
				{
					var v=chunks[i];
					edit_select.append( $("<option value='"+i+"'>#"+v.name+" "+v.opts+"</option>") );
				}
			}
		};
		
		var done_edit=function(){
			if(mode==-1) // build all chunks
			{
				text=editor.getValue();
				rechunks();
			}
			else
			{
				chunks[mode].lines=editor.getValue().split("\n");
				text=join_chunks(chunks);
			}
			edit_textarea.val( text );
			edit_result.html("changed");
		};
		
		
		edit_check.bind("change",function() {
				if($(this).is(':checked')){
					$.cookie("editor","on");
				}
				else
				{
					$.cookie("editor","off");
				}
    		});    		

if(opts.show_buttons)
{
		edit_textarea.before(edit_select);
		edit_textarea.before(edit_check);
}
		edit_textarea.before(edit_button_save);
		edit_textarea.before(edit_result);
		edit_textarea.before(edit_button_view);
		edit_textarea.before(edit_title);
		edit_textarea.after(edit_div);

		var css={width:opts.width,height:opts.height};//,position:"relative",margin:"auto",background:"#fff"};

// hide textbox and replace with new editor
		edit_textarea.css(css);
		edit_div.css(css);
		
		if($.cookie("editor")=="off")
		{
			edit_check.attr('checked', false);
			
			edit_div.hide();
		}
		else
		{
			
 			edit_check.attr('checked', true);
 			
			edit_textarea.hide();

			edit_div.empty();
			editor = CodeMirror(function(elt) {
				edit_div.append($(elt).css(css));
			}, {
				highlightSelectionMatches: true,
				matchBrackets: true,
				matchTags: true,
				keyMap:"default",
				mode: "htmlmixed",
				lineNumbers:true,
				indentUnit:4,
				indentWithTabs:true,
				electricChars:false,
				lineWrapping:true,
				extraKeys: {
						"F11": function(cm) {
						cm.setOption("fullScreen", !cm.getOption("fullScreen"));
					},
						"Esc": function(cm) {
						if (cm.getOption("fullScreen")) cm.setOption("fullScreen", false);
					}
				},
   				value: edit_textarea[0].value
			});
			
			editor.on("change",function(){
				done_edit();
			});

			edit_select.bind("change keyup",function() {
				
				var num=Math.floor( edit_select.val()*1 );
				
				done_edit();
				mode=num;
				
				edit_select.val(mode+"");
							
				if(num>=0)
				{
					editor.setValue( chunks[num].lines.join("\n") );
				}
				else
				{
					editor.setValue(text);
				}

				editor.setCursor(0,0);

				return true;
			});

		}

		rechunks();

		
		edit_button_save.click(function() {
			var data={};
			var page="test";
			data.submit="Save";
			data.text=edit_textarea.val();
			edit_result.html("...");
			$.ajax({
				type: "POST",
				url: "",
				data: data,
				success: function(data) {
					edit_result.html("Save OK");
				},
				error: function(data) {
					edit_result.html("Save ERROR");
				}
			});
		});
		
	return this;
}

// magical auto callback
	if(window.auto_wakaedit ){
		var opts=window.auto_wakaedit;
		window.auto_wakaedit=undefined; // clear to flag as done
		$(opts.who).wakaedit(opts);
	}

})(jQuery);


});
