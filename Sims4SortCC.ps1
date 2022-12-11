

Function Initialize-AutoSorting ($messyfolder) {

    $creators = @("001StudioK", "26Ink", "4w25", "AA", "Accessories", "ADA", "ADIEC", "AFS", "AH00B", "AH00BXBOP", "Akuiyumi", "Aladdin", "alessandrae", "alexaarr", "Alfsi", "ALGUE", "Aliens", "Alin22", "alsoidyia", "aluckyday", "amelylina", "AmetrineSims", "ancasims", "ANGISSI", "AnimalCostumes", "Animals", "Antlers", "Anto", "Arenetta", "arethabee", "artup", "Atashi77", "awesomeajuga", "AxA", "AxA2019Hairs", "AxA2020Hairs", "AxAParisHairs", "AxASpringCollectionHairs", "azleia", "BabyHairs", "BADDIESIMS", "BADKARMA", "BatsFromWesteros", "Beards", "BeardsMER", "BeardsPS", "BeardsSeleng", "BeccaB323", "BEDTS4", "berrybloom", "BEO", "BexoSims", "bimbosim", "Binkies", "Birksche", "BlahberryPancake", "BLewis", "Bluemoonsims", "bluesparkling", "BLVCKLS", "BM", "bobur", "Bobur", "Bodies", "BodyHair", "BodyHairMagicBot", "BooBish", "BooBishEnrique", "BoobishSimmandy", "BooboshSimmandy", "BPS", "Breathinsims", "brianitesims", "Build", "busenur41", "busratr", "BustedPixels", "ButterscotchSims", "Buy", "Buzzard", "bybukovka", "cabsims", "caearsims", "caesarsims", "candysims4", "CandySims4", "capitalco", "CaribbeanPatch", "Carol", "Caroll91", "CAS", "casteru", "casterua", "catpIntwoh", "catplnt", "Catus", "ChippedSim", "Christmas", "Christopher067", "citrontart", "ClumsyAlien", "clumsyalien", "cmt", "cosimetic", "CottonCandy", "Cowconuts", "Crayola", "CrayolaBlaze", "crazycupcake", "Crowns", "CrownsOnDisplay", "crypticsim", "CSxDSxOxToakiyo", "CubersimsxOakiyo", "cupidjuice", "Curbs", "CyberAddix", "Cyborg", "daylifesims", "DB", "Deafness", "Demons", "DesySimmer", "Devilicious", "dfjkellyhb5", "Dirt", "Disabilities", "Disanity", "DivaDoom", "DivineCap", "DNTSR", "dogsill", "Dogsill", "dogsill", "Domi", "DreamTart", "DruidSim", "Ears", "Ebonix", "EcoLifestyleAddOnHairs", "eirflower", "Ellesmea", "EmyTheGamer", "Enrique", "enrique", "Enrique", "EnriquexSentate", "ERSCH", "EVOXY", "Eyebrows", "Eyelashes", "Eyes", "fadedsprings", "FAEZ", "Fairy", "Feet", "feline", "feralpoodles", "FeralPoodles", "FifthsCreations", "FiveSims", "FiveSimsxWildPixel", "florauh", "FrostSims", "FunctionalItems", "g1g2", "Georgiaglm", "GildedGhosts", "glaza", "GlitterberrySims", "GPME", "grafity", "gramsims", "greenllamas", "grimcookies", "habsims", "Hairlines", "HallowSims", "Hats", "Head", "Headdress", "HGCC", "HistoricalSimsLife", "HOA", "Holidays", "holosprite", "Horns", "ht0", "ikarisims", "imadako", "imvikai", "infinityonsims", "infusedpeach", "Insects", "isjao", "IsJao", "isjaoLeeleesims1", "ivosims", "ixs", "JHCOSMETICS", "Joliebean", "joliebean", "JoliebeanxHFOxSentate", "kamiiri", "Kamiiri", "Katverse", "Kiara24", "KiaraZurk", "Kiko", "KISMETSIMS", "Kiwisims4", "KOTCAT", "Kotcat", "KOTCATxIsJao", "KOTCATxIsjao", "kumikya", "KXI", "kyuusims", "Leeleesims1", "LexiTS4", "LightDeficient", "lilasims", "linkysims", "LinzLu", "lollaleeloo", "lunacress", "Lune", "LUUMIA", "MagicBot", "Mannequin", "Marigold", "marsosims", "Mathcope", "maxiematch", "MB", "meghewlett", "melissasims", "MellouwSim", "MeltingEdge", "melunn", "MER", "Mermaids", "miiko", "milkyki", "MK9", "MLys", "ModMax", "mohkii", "MoonChildLovesTheNight", "MOONPRES", "moriel", "MoxXxes", "MSMarySims", "MSQSIMS", "MSSIMS", "MUSAE", "MusicalSimmer", "Mustaches", "MYOBI", "naevyssims", "NatalieAuditore", "NELL", "Neon", "nesurii", "NICKNAME", "NoirAndDarkSims", "NolanSims", "Nolansims", "NolanSims", "NolanSimsxTeanmoon", "Nooboos", "Noodles", "NoodlesRemixSaurus", "Nords", "NormalSiim", "NotDaniella", "NotEgain", "Novvvas", "NSxND", "NudeMagicBot", "NumbersWoman", "oakiyo", "Objects", "obscurus", "Obscurus", "Occult", "okruee", "oksanaoliver", "OnyxSims4", "opiumhoney", "oranos", "Other", "Overkillsimmer", "ParanormalAddOnHairs", "Parise", "pbox", "peachibloom", "Peebs", "pfoten", "pinealexple", "PinkPatchy", "PlumbobTeaSociety", "PnF", "Pooklet", "PookletBlaze", "PookletButterscotchSims", "PookletCabsim", "PookletGeorgialm", "PookletIvoSims", "PookletKarzalee", "PookletKiaraZurk", "PookletSaartje", "PookletSimpleSimmer", "Poses", "PosesAnimal", "PosesGallery", "PrideSim", "Props", "Prosthetics", "PS", "pupcake", "puppycrow", "PuppyCrowSimLotus", "PuppyCrowSimMandy", "pupusims", "pxelboy", "PYXIS", "QICC", "QRsims", "Qwerty", "Qwertysims", "raiichuu", "RaspberrySims", "Realism", "RemusSirion", "RenoraSims", "RetroPixels", "Ridgecookies", "ridgeport", "Ridgeport", "ridgeport", "RigelSims", "Ropey", "RubyBird", "rustyxsentate", "rusty", "RUSTY", "s4simomo", "Saartje77", "SALTTRY", "Sandwich", "Sandwichnaevyssims", "satterlly", "Saurus", "SaurusxBoP", "SavageSim", "savvysweet", "SavvySweet", "SavvyxGrim", "SayaSims", "Scales", "Scars", "Sclub", "sclub", "Sclub", "Seleng", "semplicesims", "serenity", "Serenity", "serenity", "servotea", "Servotea", "Sets", "Severinka", "SFS", "sg5150", "sheabuttyr", "SheSpeaksSimlish", "ShuiiSims", "ShySimblr", "Sideburns", "Signs", "Simancholy", "simandy", "Simandy", "simarillion", "Simbiance", "Simbience", "Simblreen2019Hairs", "SimCelebrity00", "Simduction", "simduction", "simgguk", "Simiracle", "SimLotus", "SimMandy", "simmerstesia", "SimpleSimmer", "Simplicitay", "simplifiedsimi", "sims3melancholic", "Sims41ife", "Sims4Pack", "SimSerenity", "Simshini", "SIMSTEFANI", "Simstrouble", "Simsza", "simtric", "Simtric", "SINA", "SingingPickles", "skellysim", "SkinDetails", "SLL", "SlotsAndShifts", "SLS", "Slythersim", "SnowyEscapeAddOnHairs", "SofterHaze", "soli", "Soloriya", "sondescent", "SonyaSims", "Sorbets", "Sorbetscandysims4", "Sparrows", "SpecialEffects", "SpinningPlumbobs", "SpookySpookySim", "Spring", "SSB", "SSPx", "StephanieSims", "stephanine", "stretchskeleton", "SubtleStubble", "SugarOwl", "suiminntyuusims", "sulsul", "suzue", "Suzue", "SweetTacoPlumbob", "SxB", "SxLTSS", "SyaoVu", "Sylviemy", "Tattoos", "teanmoon", "Teanmoon", "teanmoon", "Teeth", "Tekrisims", "tekrisims", "Tekrisims", "tekrisims", "Templates", "thecrimsonsimmer", "TheKalino", "thessia", "Tiefling", "tong", "toskami", "Toskasims", "Trillyke", "tssskellysim", "TTS", "twinksimstress", "TwistedCat", "VAIN", "valhallan", "Valhallan", "valhallan", "Vampires", "veve", "VIIAVI", "vikai", "vikaixgreenllamas", "vikaixRenoraSims", "Vitiligo", "VittlerUniverse", "VittlerUniverseS4", "VoidSimtric", "vro", "VXGGLITTER", "WAEKEY", "Watersim44", "weepingsimmer", "WeepingSimmer", "WH", "WiccanDove", "wildpixel", "wildpixelxAH00B", "Wildspit", "Wings", "WistfulCastle", "WitchingHour", "WitchingHourAH00B", "WitchingHourAladdin", "WMS", "Wondercarlotta", "WyattSims", "XGHOSTX", "Xld", "zaneidacu", "zebrazest", "Zenx", "ZeusSim")
    
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
