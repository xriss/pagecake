ver=`lua bump.lua`
hg ci -m "bootstrapp bumped to $ver"
hg push
ssh web "su wet -c\"cd hg/aelua;hg pull;hg up;cd apps/boot-str;make;cd ../../php;tail log.txt;exit\""
