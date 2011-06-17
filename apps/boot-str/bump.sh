lua bump.lua
hg ci
hg push
ssh web "su wet;cd hg/aelua;hg up;cd apps/boot-str;make;cd ..;tail log.txt;exit"
