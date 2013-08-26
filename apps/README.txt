
Apps are sites which are collections of mods and possibly some extra 
special code.

Originally I was building an app per site but this has become more 
generic with a single shared between sites using vhost style setup.

The wet directory you see here contains config for all of the anlua 
sites I currently run.

The following commands bake, serv and then view the log files.

ngx/bake
ngx/serv
ngx/tail

These serv on a localhost but since they are virtual hosts you will 
have to access them via apropriately named domain to get to the 
different ones. (ie edit your /etc/hosts)
