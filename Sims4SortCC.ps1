

Function Initialize-AutoSorting ($messyfolder) {

    $creators = @("001studiok", "26ink", "4w25", "aa", "accessories", "ada", "adiec", "afs", "ah00b", "ah00bxbop", "akuiyumi", "aladdin", "alessandrae", "alexaarr", "alfsi", "algue", "aliens", "alin22", "alsoidyia", "aluckyday", "amelylina", "ametrinesims", "ancasims", "angissi", "animalcostumes", "animals", "antlers", "anto", "arenetta", "arethabee", "artup", "atashi77", "awesomeajuga", "axa", "axa2019hairs", "axa2020hairs", "axaparishairs", "axaspringcollectionhairs", "azleia", "babyhairs", "baddiesims", "badkarma", "batsfromwesteros", "beards", "beardsmer", "beardsps", "beardsseleng", "beccab323", "bedts4", "berrybloom", "beo", "bexosims", "bimbosim", "binkies", "birksche", "blahberrypancake", "blewis", "bluemoonsims", "bluesparkling", "blvckls", "bm", "bobur", "bobur", "bodies", "bodyhair", "bodyhairmagicbot", "boobish", "boobishenrique", "boobishsimmandy", "booboshsimmandy", "bps", "breathinsims", "brianitesims", "build", "busenur41", "busratr", "bustedpixels", "butterscotchsims", "buy", "buzzard", "bybukovka", "cabsims", "caearsims", "caesarsims", "candysims4", "candysims4", "capitalco", "caribbeanpatch", "carol", "caroll91", "cas", "casteru", "casterua", "catpintwoh", "catplnt", "catus", "chippedsim", "christmas", "christopher067", "citrontart", "clumsyalien", "clumsyalien", "cmt", "cosimetic", "cottoncandy", "cowconuts", "crayola", "crayolablaze", "crazycupcake", "crowns", "crownsondisplay", "crypticsim", "csxdsxoxtoakiyo", "cubersimsxoakiyo", "cupidjuice", "curbs", "cyberaddix", "cyborg", "daylifesims", "db", "deafness", "demons", "desysimmer", "devilicious", "dfjkellyhb5", "dirt", "disabilities", "disanity", "divadoom", "divinecap", "dntsr", "dogsill", "dogsill", "dogsill", "domi", "dreamtart", "druidsim", "ears", "ebonix", "ecolifestyleaddonhairs", "eirflower", "ellesmea", "emythegamer", "enrique", "enrique", "enrique", "enriquexsentate", "ersch", "evoxy", "eyebrows", "eyelashes", "eyes", "fadedsprings", "faez", "fairy", "feet", "feline", "feralpoodles", "feralpoodles", "fifthscreations", "fivesims", "fivesimsxwildpixel", "florauh", "frostsims", "functionalitems", "g1g2", "georgiaglm", "gildedghosts", "glaza", "glitterberrysims", "gpme", "grafity", "gramsims", "greenllamas", "grimcookies", "habsims", "hairlines", "hallowsims", "hats", "head", "headdress", "hgcc", "historicalsimslife", "hoa", "holidays", "holosprite", "horns", "ht0", "ikarisims", "imadako", "imvikai", "infinityonsims", "infusedpeach", "insects", "isjao", "isjao", "isjaoleeleesims1", "ivosims", "ixs", "jhcosmetics", "joliebean", "joliebean", "joliebeanxhfoxsentate", "kamiiri", "kamiiri", "katverse", "kiara24", "kiarazurk", "kiko", "kismetsims", "kiwisims4", "kotcat", "kotcat", "kotcatxisjao", "kotcatxisjao", "kumikya", "kxi", "kyuusims", "leeleesims1", "lexits4", "lightdeficient", "lilasims", "linkysims", "linzlu", "lollaleeloo", "lunacress", "lune", "luumia", "magicbot", "mannequin", "marigold", "marsosims", "mathcope", "maxiematch", "mb", "meghewlett", "melissasims", "mellouwsim", "meltingedge", "melunn", "mer", "mermaids", "miiko", "milkyki", "mk9", "mlys", "modmax", "mohkii", "moonchildlovesthenight", "moonpres", "moriel", "moxxxes", "msmarysims", "msqsims", "mssims", "musae", "musicalsimmer", "mustaches", "myobi", "naevyssims", "natalieauditore", "nell", "neon", "nesurii", "nickname", "noiranddarksims", "nolansims", "nolansims", "nolansims", "nolansimsxteanmoon", "nooboos", "noodles", "noodlesremixsaurus", "nords", "normalsiim", "notdaniella", "notegain", "novvvas", "nsxnd", "nudemagicbot", "numberswoman", "oakiyo", "objects", "obscurus", "obscurus", "occult", "okruee", "oksanaoliver", "onyxsims4", "opiumhoney", "oranos", "other", "overkillsimmer", "paranormaladdonhairs", "parise", "pbox", "peachibloom", "peebs", "pfoten", "pinealexple", "pinkpatchy", "plumbobteasociety", "pnf", "pooklet", "pookletblaze", "pookletbutterscotchsims", "pookletcabsim", "pookletgeorgialm", "pookletivosims", "pookletkarzalee", "pookletkiarazurk", "pookletsaartje", "pookletsimplesimmer", "poses", "posesanimal", "posesgallery", "pridesim", "props", "prosthetics", "ps", "pupcake", "puppycrow", "puppycrowsimlotus", "puppycrowsimmandy", "pupusims", "pxelboy", "pyxis", "qicc", "qrsims", "qwerty", "qwertysims", "raiichuu", "raspberrysims", "realism", "remussirion", "renorasims", "retropixels", "ridgecookies", "ridgeport", "ridgeport", "ridgeport", "rigelsims", "ropey", "rubybird", "rustyxsentate", "rusty", "rusty", "s4simomo", "saartje77", "salttry", "sandwich", "sandwichnaevyssims", "satterlly", "saurus", "saurusxbop", "savagesim", "savvysweet", "savvysweet", "savvyxgrim", "sayasims", "scales", "scars", "sclub", "sclub", "sclub", "seleng", "semplicesims", "serenity", "serenity", "serenity", "servotea", "servotea", "sets", "severinka", "sfs", "sg5150", "sheabuttyr", "shespeakssimlish", "shuiisims", "shysimblr", "sideburns", "signs", "simancholy", "simandy", "simandy", "simarillion", "simbiance", "simbience", "simblreen2019hairs", "simcelebrity00", "simduction", "simduction", "simgguk", "simiracle", "simlotus", "simmandy", "simmerstesia", "simplesimmer", "simplicitay", "simplifiedsimi", "sims3melancholic", "sims41ife", "sims4pack", "simserenity", "simshini", "simstefani", "simstrouble", "simsza", "simtric", "simtric", "sina", "singingpickles", "skellysim", "skindetails", "sll", "slotsandshifts", "sls", "slythersim", "snowyescapeaddonhairs", "softerhaze", "soli", "soloriya", "sondescent", "sonyasims", "sorbets", "sorbetscandysims4", "sparrows", "specialeffects", "spinningplumbobs", "spookyspookysim", "spring", "ssb", "sspx", "stephaniesims", "stephanine", "stretchskeleton", "subtlestubble", "sugarowl", "suiminntyuusims", "sulsul", "suzue", "suzue", "sweettacoplumbob", "sxb", "sxltss", "syaovu", "sylviemy", "tattoos", "teanmoon", "teanmoon", "teanmoon", "teeth", "tekrisims", "tekrisims", "tekrisims", "tekrisims", "templates", "thecrimsonsimmer", "thekalino", "thessia", "tiefling", "tong", "toskami", "toskasims", "trillyke", "tssskellysim", "tts", "twinksimstress", "twistedcat", "vain", "valhallan", "valhallan", "valhallan", "vampires", "veve", "viiavi", "vikai", "vikaixgreenllamas", "vikaixrenorasims", "vitiligo", "vittleruniverse", "vittleruniverses4", "voidsimtric", "vro", "vxgglitter", "waekey", "watersim44", "weepingsimmer", "weepingsimmer", "wh", "wiccandove", "wildpixel", "wildpixelxah00b", "wildspit", "wings", "wistfulcastle", "witchinghour", "witchinghourah00b", "witchinghouraladdin", "wms", "wondercarlotta", "wyattsims", "xghostx", "xld", "zaneidacu", "zebrazest", "zenx", "zeussim")
    
    $typeOfCC = @("necklace", #0
    "glasses", #1
    "socks", #2
    "tights", #3
    "stockings", #4
    "veil", #5
    "bonnet", #6
    "beret", #7
    "bandeau" #8
    )
        
    $folderfortype = @("$messyfolder\Modern\CC_Unmerged\Accessories\Necklaces", #0
    "$messyfolder\Modern\CC_Unmerged\Accessories\Glasses", #1
    "$messyfolder\Modern\CC_Unmerged\Accessories\Socks", #2
    "$messyfolder\Modern\CC_Unmerged\Accessories\Tights", #3
    "$messyfolder\Modern\CC_Unmerged\Accessories\Stockings", #4
    "$messyfolder\Modern\CC_Unmerged\Accessories\Veils", #5
    "$messyfolder\Modern\CC_Unmerged\Accessories\Hats", #6
    "$messyfolder\Modern\CC_Unmerged\Accessories\Hats", #7
    "$messyfolder\Modern\CC_Unmerged\Accessories\Misc" #8
    )


    $folderContents = Get-ChildItem -File $messyfolder
    foreach ($package in $folderContents) {
        for ($typenum=0; $typeOfCC.Count -gt $typenum; $typenum++) {
            $check = $typeOfCC[$typenum]
            if ($package.BaseName -ilike "*$check*") { #check if it's a necklace etc
                $toMoveTo = $folderfortype[$typenum]
                New-Item -ItemType Directory -Force -Path $tomoveto
                for ($creatorNum=0; $creators.Count -gt $creatorNum; $creatorNum++) {
                    $search = $creators[$creatorNum]
                    if ($package.BaseName -ilike "*$search*") { #check for creator name
                        New-Item -ItemType Directory -Force -Path "$tomoveto\$search"
                        Move-Item -Verbose -Path $($package.FullName) -Destination "$tomoveto\$search\$($package.Name)"
                    } else {
                        Move-Item -Verbose -Path $($package.FullName) -Destination "$tomoveto\$($package.Name)"
                    }
                }
            } else {
                Write-Host "File $($package.Name) did not match any known types."
                #do nothing rn, but later enable the below
                <#New-Item -ItemType Directory -Force -Path "$messyfolder\Must Sort Manually"
                Move-Item -Verbose -Path $($package.FullName) -Destination "$messyfolder\Must Sort Manually\$($package.Name)"#>
            }
        }
    }
}

$messyfolder = "M:\The Sims 4 (Documents)\testingfolder"

Initialize-Autosorting $messyfolder
