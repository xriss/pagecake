if ngx then	return require("wetgenes.www.ngx.fetch")else	return require("wetgenes.www.gae.fetch")end