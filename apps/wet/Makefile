
all: bake

bake:
	ant
	
clean:
	ant clean
	
serv: bake
	../../../sdks/appengine-java-sdk/bin/dev_appserver.sh .war

upload: bake
	../../../sdks/appengine-java-sdk/bin/appcfg.sh update .war

rollback: bake
	../../../sdks/appengine-java-sdk/bin/appcfg.sh rollback .war

