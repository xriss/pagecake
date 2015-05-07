
dimeload={};

dimeload.goto=function(name)
{
	if(name&&(name!=""))
	{
		dimeload.state=name;
		$(".dimeload_tabs").hide(200);
		$("#dimeload_tab_"+name).show(200);
	}	
	return false;
}


/*
 * dimeload.inject=function(div)
{
	dimeload.div=$(div);
	
	dimeload.goto("login");
};
*/

/*
 * 
dimeload.html={};

dimeload.gethtml=function(name)
{
	if( html[name] ) return html[name];
	if( dimeload.html[name] ) return dimeload.html[name];
};

dimeload.html.login='\
<div class="dl_login"><a href="/dumid/login/?continue='+location.href+'"> You must login before you can do anything. \
Click here to login</a></div>\
';

dimeload.html.welcome='\
<div class="dl_welcome">Welcome to DimeLoad you have <span class="dl_dimes">0</span> dimes.<a href="#" onclick="return dimeload.goto(\'sponsor\');">Buy dimes?</a></div>\
';

dimeload.html.back='\
<div class="dl_back"><a href="#" onclick="return dimeload.goto(\'welcome\');">Back.</a></div>\
';

dimeload.html.menu='\
<div class="dl_download"><a href="#" onclick="return dimeload.goto(\'downloads\');">Click here to view the list of downloads for this project.</a></div>\
<div class="dl_sponsor"><a href="#" onclick="return dimeload.goto(\'sponsor\');">Click here to sponsor this project and create a custom download page.</a></div>\
';

dimeload.html.sponsor='\
Sponsorship is still in development and will be available in a couple of days.\
';

//this should be calculated and filled in on the server
dimeload.html.downloads='\
No downloads available.\
';

//this should be calculated and filled in on the server
dimeload.html.alldownloads='\
No downloads available.\
';

dimeload.html.available='\
<div class="dl_available">This page has '+(dl_page?(dl_page.available):"0")+' dimes available</div>\
';





dimeload.inject=function(div)
{
	dimeload.div=$(div);
	if(error)
	{
		dimeload.goto("error");
	}
	else
	if(user)
	{
		if(dl_page)
		{
			dimeload.goto("downloads");
		}
		else
		{
			dimeload.goto("welcome");
		}
	}
	else
	{
		dimeload.goto("login");
	}
};

dimeload.goto=function(name)
{
	dimeload.state=name;
	
	switch(dimeload.state)
	{
		case "error":
			dimeload.div.html(dimeload.gethtml("back")+"<div class=\"dl_error\">"+(error)+"</div>");
		break;
		case "welcome":
			dimeload.div.html(dimeload.gethtml("welcome")+dimeload.gethtml("menu"));
		break;
		default:
			dimeload.div.html(dimeload.gethtml("back")+dimeload.gethtml(dimeload.state));	
		break;
	}
	
	dimeload.div.append( dimeload.gethtml("available") );

	if(dl_page)
	{
		dimeload.div.append( dl_page.about );
	}
	
	return false;
};
*/
