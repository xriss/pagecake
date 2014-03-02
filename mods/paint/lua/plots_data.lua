-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require


local whtml=require("wetgenes.html")
local wjson=require("wetgenes.json")
local wstr=require("wetgenes.string")


local M={ modname=(...) } ; package.loaded[M.modname]=M


local deepcopy

deepcopy=function(frm,too)
	too=too or {}

	for n,v in pairs(frm) do
		if type(v)=="table" then 	too[n]=deepcopy(v,too[n])
		else						too[n]=v
		end
	end

	return too
end

local random_count=function(tab)
	local count=0
	for i,v in pairs(tab) do
		count=count+1
	end
	return count
end

local random_pair=function(tab,idx)
	if not idx then
		idx=math.random( random_count(tab) )
	end
	local count=0
	for i,v in pairs(tab) do
		count=count+1
		if idx<=count then return i,v end
	end
end
local random_value=function(tab,idx)
	local i,v=random_pair(tab,idx)
	return v
end

-- get a random full data,
-- in the future we could use a fixed seed so we get the same "random"
M.get=function()
	local ret=deepcopy(M.default)

	local pix={random_pair( M.pixs )}
	local pal={random_pair( M.pals )}
	local fat={random_pair( M.fats )}
	local plate={random_pair( M.plates )}

	local words={}
	for n,v in pairs(M.words) do
		words[n]=random_value(v)
	end

	local title=wstr.replace(plate[2],words)

	ret.title=title
	ret.plot=pix[1].."/"..pal[1].."/"..fat[1].."/"..plate[1]

	deepcopy(pix[2],ret.pix)
	deepcopy(pal[2],ret.pal)
	deepcopy(fat[2],ret.fat)

	return ret
end


M.pixs={
	pix64x64={
		width=64,
		height=64,
		depth=1,
	},
	pix32x32={
		width=32,
		height=32,
		depth=1,
	},
	pix16x16={
		width=16,
		height=16,
		depth=1,
	},
	pix8x8={
		width=8,
		height=8,
		depth=1,
	},
}

M.pals={
	C64={
		0xFF000000,0xFFFFFFFF,0xFF663322,0xFF77AABB,
		0xFF663388,0xFF558844,0xFF332277,0xFFbbcc77,
		0xFF664422,0xFF443300,0xFF996655,0xFF444444,
		0xFF666666,0xFF99DD88,0xFF6655BB,0xFF999999,
	},
	EGA={
		0xff000000,0xff0000aa,0xff00aa00,0xff00aaaa,
		0xffaa0000,0xffaa00aa,0xffaa5500,0xffaaaaaa,
		0xff555555,0xff5555ff,0xff55ff55,0xff55ffff,
		0xffff5555,0xffff55ff,0xffffff55,0xffffffff,
	},
	Spectrum={
		0xff000000,0xff0000ff,0xffff0000,0xffff00ff,
		0xff00ff00,0xff00ffff,0xffffff00,0xffffffff,
		0xff000000,0xff0000bb,0xffbb0000,0xffbb00bb,
		0xff00bb00,0xff00bbbb,0xffbbbb00,0xffbbbbbb,
	},
	MSX={
		0x00000000,0xff000000,0xff33bb44,0xff77dd77,
		0xff5555ee,0xff8877ff,0xffbb5555,0xff66ddee,
		0xffdd6655,0xffff8877,0xffcccc55,0xffdddd88,
		0xff33aa44,0xffbb66bb,0xffcccccc,0xffffffff,
	},
	AppleII={
		0xff000000,0xff662244,0xff443377,0xffdd33ee,
		0xff115544,0xff888888,0xff2299ee,0xffbbbbff,
		0xff444400,0xffdd6600,0xff888888,0xffeeaabb,
		0xff22cc11,0xffbbcc88,0xff99ddbb,0xffffffff,
	},
}

M.fats={
	bloom3x3={
		width=3,
		height=3,
		bloom=1.5,
	},
}

M.plates={
	"{adjective} {noun}",
--	"I dont know what {adjective} is.",
--	"Sometime {noun} come back.",
}

M.words={
	adjective={
	"ravishing","mimic","famous","cheerful","livid","obstinate","exhausted","graceful","outrageous","radical","childish","snobbish","miserly","amiable","disgusting","awful","humorous","fanciful","pathetic","windy","dusty","bashful","freaky","chilly","stormy","humid","bountiful","jubilant","irritated","patient","dizzy","skeptical","puzzled","perplexed","jovial","hyper","squirrely","jittery","elegant","gleeful","dreary","impish","sneaky","horrid","monsterous","able","abnormal","absent","absolute","accurate","acidic","acoustic","active","adequate","airborne","airy","all","alone","american","amphibious","angry","annual","another","any","apparent","artificial","atomic","audible","automatic","auxiliary","available","bad","ballistic","bare","basic","beautiful","beneficial","best","better","big","biggest","binary","bipolar","bitter","black","blind","blue","both","brief","bright","broad","brown","busy","capable","careful","careless","carnal","cautious","celestial","celsius","central","ceramic","certain","cheap","cheaper","civil","clean","clear","closer","coarse","cold","common","compact","complete","complex","compound","compulsory","concrete","conscious","constant","continuous","convenient","cool","correct","corrosive","critical","cruel","cubic","culpable","current","daily","dangerous","dark","darker","darkest","dead","deaf","dear","dearer","dearest","decimal","deep","deeper","deepest","defective","definite","delicate","dental","dependent","destructive","diagonal","different","difficult","digital","dim","diseased","distinct","ditty","dormant","double","drafty","drier","driest","drowsy","dry","dual","due","dull","dumb","dynamic","each","easy","eighth","either","elastic","electric","eligible","else","empty","enough","entire","equal","erect","erratic","essential","eventual","every","everyday","evident","exact","excellent","excessive","exclusive","explosive","extensive","external","extra","extreme","extrinsic","faint","fair","false","familiar","fast","fat","fatal","fattest","faulty","feasible","federal","feeble","fertile","few","fifth","final","fine","firm","first","fiscal","fit","flammable","flat","flexible","foggy","foolish","foreign","formal","former","fourth","free","frequent","fresh","full","gamma","general","gentle","good","gradual","grand","graphic","grave","gray","great","green","grievous","grocery","happy","hard","harmful","hazardous","healthy","heavy","helpful","high","hilly","hind","hollow","hot","huge","icy","identical","idle","ill","imminent","important","improper","inboard","inner","instant","intense","internal","intrinsic","iterative","jet","julian","junior","keen","kelvin","kind","knobbed","large","last","late","lawful","lazy","leaky","lean","least","legal","less","lethal","level","likely","linear","liquid","literal","little","lively","local","lone","long","loose","loud","low","magnetic","main","many","maple","marine","martial","mean","medical","mental","mere","metallic","middle","minor","minus","misty","mnemonic","mobile","modern","modular","molten","moral","more","most","movable","muddy","multiple","mutual","naked","narcotic","narrow","national","natural","nautical","naval","neat","necessary","negative","nervous","neutral","new","next","nice","noisy","nominal","normal","nuclear","numeric","numerical","numerous","obsolete","obvious","odd","offline","okay","old","online","open","optimum","optional","oral","ordinary","original","other","outboard","outer","outside","outward","overhead","oversize","own","pale","paler","palest","parallel","partial","passive","past","peculiar","periodic","permanent","personal","petty","phonetic","physical","plain","planar","plenty","poisonous","polite","political","poor","portable","positive","possible","potential","powerful","practical","precise","pretty","previous","primary","prior","private","probable","prompt","proper","protective","proximate","punitive","pure","purple","quick","quiet","random","rapid","raw","ready","real","red","regional","regular","relative","reliable","remote","removable","responsible","retail","reusable","rich","richer","richest","right","rigid","ripe","rough","sad","sadder","saddest","safe","safer","safest","same","secondary","secure","senior","sensitive","separate","serious","seventh","several","severe","shady","shallow","sharp","shy","shiny","short","sick","silent","similar","simple","single","sixth","slack","slight","slippery","slower","slowest","small","smart","smooth","snug","social","soft","solar","solid","some","sour","special","specific","stable","static","steady","steep","sterile","sticky","stiff","still","straight","strange","strict","strong","such","sudden","suitable","sunny","superior","sure","sweet","swift","swollen","symbolic","synthetic","tactical","tall","taut","technical","temporary","tentative","terminal","thermal","thick","thin","third","thirsty","tight","tiny","toxic","tropical","true","turbulent","typical","unique","upper","urgent","useable","useful","usual","valid","valuable","various","vertical","viable","violent","virtual","visible","visual","vital","void","volatile","wanton","warm","weak","weary","wet","white","whole","wide","wise","wooden","woolen","worse","worst","wrong","yellow","young","harmless","inactive","incorrect","indirect","invalid","unable","unknown","unmated","unsafe","unsigned","unused","unusual","unwanted","useless","aged","etched","finished","given","left","lost","mistaken","proven",
	},
	noun={
	"abrasive","abuser","accident","acid","acre","acronym","act","address","admiral","adverb","adviser","affair","agent","aid","aim","air","airplane","airport","airship","alarm","alcoholic","algebra","alias","alibi","alley","alloy","analog","analyst","anchor","angle","animal","anthem","apple","april","apron","arc","arch","area","arm","army","array","arrest","arrow","atom","attack","ax","axis","baby","back","bag","ball","balloon","band","bang","bar","barge","barrel","base","basin","basket","bat","batch","bath","bather","battery","bay","beach","beacon","bead","beam","bean","bear","beat","bed","being","bend","berry","bigamy","blade","blank","blanket","blast","blasts","block","blood","blot","blow","blower","boat","body","boil","bolt","bone","book","boot","bore","bottle","bottom","box","boy","brain","bread","breast","brick","broom","bubble","bucket","builder","bullet","bump","bus","bush","butt","butter","button","byte","cab","cake","camp","cannon","cap","captain","carpet","cause","cave","cell","cellar","chair","chalk","cheat","cheek","cheese","chief","child","chimney","church","circle","citizen","civilian","clamp","claw","clerk","clock","cloud","club","clump","coal","coat","coder","colon","comb","comma","computer","cone","console","control","copy","cord","core","cork","corner","cough","count","crack","cradle","craft","cramp","crash","crawl","crust","cube","cup","cure","curl","dam","data","date","dealer","death","debris","debt","decay","december","deck","decoder","default","defect","delight","dent","desert","desire","desk","device","diode","dirt","disease","disgust","dish","disk","ditch","ditches","diver","divider","dolly","dope","dose","drag","dress","drug","dump","ear","edge","egg","elbow","electron","eleven","end","enemy","error","exit","expert","face","factory","fake","fall","family","fan","farm","father","fear","feather","feeder","feet","field","fighter","file","filter","finger","fish","fist","flake","flap","flash","flood","floor","flush","foam","fog","fold","food","foot","force","forest","fork","form","fort","friction","friday","friend","front","frost","fruit","fur","game","gang","gap","garage","garden","gas","gate","gear","gene","giant","girl","gland","glass","glaze","gleam","glide","glove","glow","glue","goal","grade","graph","grass","grease","grid","grip","groan","gross","growth","guard","guest","guide","gum","gun","guy","habit","hail","hair","half","hall","hammer","hand","handle","hangar","harbor","hardware","harm","harpoon","haste","hat","hatch","hate","hazard","head","heap","heart","heat","heater","heel","heels","height","hello","helm","helmet","help","hem","here","hertz","hill","hint","hip","hiss","hold","hole","home","honk","hood","hoof","hook","hoop","horn","hose","hotel","hour","house","howl","hub","hug","hull","hum","human","humor","hump","hundred","hunk","hunt","hush","hut","ice","icing","idea","ideal","image","impact","impulse","inch","injury","ink","inlet","inlets","input","inquiry","insanity","insignia","intake","intakes","integer","integrity","intent","intents","intercom","interest","interface","interior","interval","interview","invention","invoice","iron","island","issue","item","ivory","jack","jail","jam","jar","jaw","jelly","jewel","jig","job","joint","judge","jug","july","jump","june","junk","jury","justice","keel","kettle","key","keyboard","keyword","kick","kill","kiss","kit","kite","knee","knife","knob","knock","knot","label","labor","lace","lack","ladder","lake","lamp","land","lane","lantern","lap","lapse","lard","laser","lash","latch","laugh","launch","laundry","law","layer","lead","leader","leaf","leak","leakage","leap","leaper","leather","leave","leg","legend","length","lesson","letter","liberty","library","lick","lid","life","lift","light","limb","lime","limit","limp","line","linen","link","lint","lip","liquor","list","liter","litre","liver","load","loaf","loan","lock","locker","log","logic","look","loop","loss","lot","love","lumber","lump","lung","machine","magnet","mail","major","make","male","man","map","marble","march","margin","mark","market","mask","mass","mast","master","mat","match","mate","material","math","meal","meat","medal","medium","meet","member","memory","men","mention","mentions","menu","menus","mess","metal","meter","method","mile","milk","mill","mind","mine","mint","mirror","misfit","miss","mission","mist","mitt","mitten","mix","mode","model","modem","module","moment","monday","money","monitor","moon","moonlight","mop","moss","motel","mother","motion","motor","mount","mouth","move","mover","much","mud","mug","mule","muscle","music","mustard","nail","name","nation","nature","nausea","navy","neck","need","needle","neglect","nerve","nest","net","neutron","nickel","night","nod","noise","noon","north","nose","notation","note","notice","noun","nozzle","null","number","numeral","nurse","nut","nylon","oak","oar","object","ocean","odor","odors","offer","officer","ohm","oil","operand","opinion","option","orange","order","ore","organ","orifice","origin","ornament","ounce","ounces","outfit","outing","outlet","outline","output","oven","owner","oxide","oxygen","pace","pack","pad","page","pail","pain","paint","pair","pan","pane","panel","paper","parcel","parity","park","part","partner","party","pascal","pass","passage","paste","pat","patch","path","patient","patrol","paw","paws","pay","pea","peace","peak","pear","peck","pedal","peg","pen","pencil","people","percent","perfect","period","permit","person","phase","photo","pick","picture","piece","pier","pile","pilot","pin","pink","pipe","pistol","piston","pit","place","plan","plane","plant","plastic","plate","play","plead","pleasure","plot","plow","plug","pocket","point","poison","poke","pole","police","polish","poll","pond","pool","pop","port","portion","post","pot","potato","pound","powder","power","prefix","presence","present","president","press","price","prime","print","prism","prison","probe","problem","produce","product","profile","profit","program","progress","project","pronoun","proof","prop","protest","public","puddle","puff","pull","pulse","pump","punch","pupil","purchase","purge","purpose","push","pyramid","quart","quarter","question","quiet","quota","race","rack","radar","radian","radio","rag","rail","rain","rainbow","raincoat","raise","rake","ram","ramp","range","rank","rap","rate","ratio","ratios","rattle","ray","reach","reader","ream","rear","reason","rebound","receipt","recess","record","recovery","recruit","reel","refund","refuse","region","regret","relay","release","relief","remedy","removal","repair","report","request","rescue","reserve","resident","residue","resource","respect","rest","result","return","reverse","review","reward","rheostat","rhythm","rib","ribbon","rice","riddle","ride","rifle","rig","rim","rinse","river","road","roar","rock","rocket","rod","roll","roof","room","root","rope","rose","round","route","rower","rubber","rudder","rug","rule","rumble","run","runner","rush","rust","sack","saddle","safety","sail","sailor","sale","salt","salute","sample","sand","sap","sash","scab","scale","scene","school","science","scope","score","scrap","scratch","scream","screen","screw","sea","seal","seam","search","season","seat","second","secret","sector","seed","self","sense","sentry","serial","series","servant","session","setup","sewage","sewer","sex","shade","shadow","shaft","shame","shape","share","shave","sheet","shelf","shell","shelter","shield","shift","ship","shirt","shock","shoe","shop","shore","shoulder","shout","shovel","show","shower","side","sight","sign","silence","silk","sill","silver","sink","sip","sir","siren","sister","site","size","skew","skill","skin","skip","skirt","sky","slap","slash","slate","slave","sled","sleep","sleeve","slice","slide","slope","slot","smash","smell","smile","smoke","snap","sneeze","snow","soap","society","sock","socket","sod","software","soil","soldier","sole","son","sonar","song","sort","sound","soup","source","south","space","spacer","spade","span","spar","spare","spark","speaker","spear","speech","speed","speeder","spike","spill","spiral","splash","splice","splint","spoke","sponge","sponsor","sponsors","spool","spoon","sport","spot","spray","spring","square","squeak","stack","staff","stage","stair","stake","stall","stamp","stand","staple","star","stare","start","state","status","steam","steamer","steel","stem","step","stern","stick","sting","stitch","stock","stomach","stone","stool","stop","store","storm","story","stove","strain","strand","strap","straw","streak","stream","street","stress","strike","string","strip","stripe","strobe","stroke","strut","stub","student","study","stuff","stump","submarine","success","sugar","suit","sum","sun","sunday","sunlight","sunrise","sunset","sunshine","surface","surge","surprise","swab","swallow","swamp","swap","sweep","swell","swim","swimmer","swing","switch","swivel","sword","symbol","system","tab","table","tablet","tack","tactic","tag","tail","tailor","talk","tan","tank","tap","tape","tar","target","task","taste","tax","taxi","team","tear","teeth","teller","temper","tender","tens","tension","tent","tenth","term","terrain","test","tests","text","theory","thin","thing","thirty","thread","threat","throat","thumb","thunder","tick","tide","tie","till","time","timer","timers","times","tin","tip","tips","tire","tissue","title","today","toe","ton","tongue","tool","tools","tooth","top","topic","toss","total","touch","tour","towel","tower","town","trace","track","tracker","tractor","trade","traffic","trail","trailer","train","transfer","transit","trap","trash","tray","tree","trial","trick","trigger","trim","trip","troop","trouble","truck","trunk","truth","try","tub","tug","tune","tunnel","turn","twig","twin","twine","twirl","twist","type","typist","umbrella","uniform","unit","update","upside","usage","use","user","vacuum","value","valve","vapor","vector","vehicle","vendor","vent","verb","version","vessel","veteran","vice","victim","video","view","village","vine","violet","visit","voice","volt","vomit","wafer","wage","wagon","waist","wait","wake","walk","wall","want","war","wash","waste","watch","water","watt","wave","wax","way","web","weed","week","weight","weld","west","wheel","whip","whirl","width","wiggle","win","winch","wind","wine","wing","winter","wire","wish","woman","wonder","wood","wool","word","work","world","worm","worry","worth","wrap","wreck","wrench","wrist","writer","yard","yarn","year","yell","yield","yolk","zero","zip","zone","can","may","coupling","damping","ending","rigging","ring","sizing","sling","nothing","cast","cost","cut","drunk","felt","ground","hit","lent","offset","set","shed","shot","slit","thought","wound",
	},
}

-- default settings, add
M.default={
	plot="default",
	title="anything goes",
	pix={
		width=64,
		height=64,
		depth=1,
	},
	pal={
		0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
		0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
		0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
		0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,

		0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
		0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
		0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
		0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,

		0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
		0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
		0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
		0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,

		0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
		0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
		0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
		0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
	},
	fat={
		width=3,
		height=3,
		bloom=1.5,
		escher=0,
		bits=32,
	},
}

