
Function Out-Script {
    Write-Host "Finishing up."
    $endingVars = Get-Variable
    Remove-Variable $endingVars -Exclude $startingVars
    Exit
}

Function Start-MakeSortingFolders ($messyfolder) {    

    # replicate folder tree for moving files around
    $emptyFileTree = "M:\The Sims 4 (Documents)\!EmptyFileTree"
    Copy-Item "$emptyFileTree\General" $messyfolder -Filter {PSIsContainer} -Recurse -Force
    Copy-Item "$emptyFileTree\Modern" $messyfolder -Filter {PSIsContainer} -Recurse -Force
}

Function Initialize-TidyCharacters ($messyfolder) {
    $matchlist = @(<#---0---#> "[", 
    <#---1---#> "]", 
    <#---2---#> "(",  
    <#---3---#> ")", 
    <#---4---#> " ", 
    <#---5---#> "@",  
    <#---6---#> "&", 
    <#---7---#> "%", 
    <#---8---#> "$", 
    <#---9---#> "=", 
    <#---10---#> "+", 
    <#---11---#> "#", 
    <#---12---#> "'", 
    <#---13---#> "_", 
    <#---14---#> "-", 
    <#---15---#> " ", 
    <#---16---#> ",",
    <#---17---#> ".",
    <#---18---#> "'"
     ) 
    $replacelist = @(<#---0---#> "", 
    <#---1---#> "", 
    <#---2---#> "",  
    <#---3---#> "", 
    <#---4---#> "", 
    <#---5---#> "",  
    <#---6---#> "", 
    <#---7---#> "", 
    <#---8---#> "", 
    <#---9---#> "", 
    <#---10---#> "", 
    <#---11---#> "", 
    <#---12---#> "", 
    <#---13---#> "", 
    <#---14---#> "", 
    <#---15---#> "", 
    <#---16---#> "",
    <#---17---#> "",
    <#---18---#> ""
    ) 
    $foldersToIgnore = @("General", "Manual Sort", "Manual Sort - Historical", "Modern")
    for ($i=0; $matchlist.Count -gt $i; $i++) {        
        Get-ChildItem -Path $messyfolder -Depth 0 |
        Where-Object { $_.baseName.Contains($matchlist[$i]) } |
        if ($foldersToIgnore -notcontains $_.Name) {
            Rename-Item -NewName { ($_.baseName -replace [regex]::Escape($matchlist[$i]),$replacelist[$i]) + $_.Extension } -PassThru
        }
    }
}

Function Register-Package {
    param(
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'Package')][bool]$package, 
        [Parameter(Mandatory = $false, Position = 1, ParameterSetName = 'Type or Creator')][bool]$isType, 
        [Parameter(Mandatory = $true, Position = 2, ParameterSetName = 'Package Number')][int]$packageCount, 
        [Parameter(Mandatory = $false, Position = 3, ParameterSetName = 'Type')][string]$type, 
        [Parameter(Mandatory = $false, Position = 4, ParameterSetName = 'Creator')][string]$creator, 
        [Parameter(Mandatory = $false, Position = 5, ParameterSetName = 'Destination')][string]$destination, 
        [Parameter(Mandatory = $true, Position = 6, ParameterSetName = 'Log File Location')][string]$logfile,
        [Parameter(Mandatory = $true, Position = 7, ParameterSetName = 'Exist')][bool]$alreadymoved,
        [Parameter(Mandatory = $true, Position = 8, ParameterSetName = 'Packages Checked')][array]$packagesChecked,
        [Parameter(Mandatory = $false, Position = 9, ParameterSetName = 'Creator Found')][bool]$creatorfound,
        [Parameter(Mandatory = $false, Position = 10, ParameterSetName = 'Moving')][bool]$creatorNoType,
        [Parameter(Mandatory = $false, Position = 11, ParameterSetName = 'Return')][bool]$return)

        if ($alreadymoved -eq $true) {
            "#$packageCount `"$package`": This file already exists within the array. Skipping." | Out-File $logfile -Append
        } elseif ($alreadymoved -eq $false) {
            "#$packageCount `"$package`": This file has not yet been processed." | Out-File $logfile -Append
        } elseif ($creatorNoType -eq $true){
            "#$packageCount `"$package`": File matched as $creator, but we don't know the type. Moving to $destination." | Out-File $logfile -Append
            $packagesChecked += $package
            "#$packageCount : $package has been processed." | Out-File $logfile -Append
        } elseif ($isType -eq $true) {
            "#$packageCount `"$package`": File matched as $type. Continuing." | Out-File $logfile -Append
        } elseif ($isType -eq $false -AND $creatorfound -eq $true) {
            "#$packageCount `"$package`": File matched as $type by $creator. Moving to $destination." | Out-File $logfile -Append
            $packagesChecked += $package
            "#$packageCount : $package has been processed." | Out-File $logfile -Append
        } elseif ($isType -eq $false -AND $creatorfound -eq $false) {
            "#$packageCount `"$package`": File matched as $type with no matching creator. Moving to $destination." | Out-File $logfile -Append
            $packagesChecked += $package
            "#$packageCount : $package has been processed." | Out-File $logfile -Append
        } elseif ($return -eq $true) {
            "#$packageCount `"$package`": File did not match anything. Moving to $destination." | Out-File $logfile -Append
            $packagesChecked += $package
            "#$packageCount : $package has been processed." | Out-File $logfile -Append
        }
        
    Return $packageCount, $packagesChecked
}

Function Initialize-AutoSorting {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Unsorted Folder')]
        [string]
        $messyfolder,
        [Parameter(Mandatory = $true, ParameterSetName = 'List of Creators')]
        [array]
        $creatorsList,
        [Parameter(Mandatory = $true, ParameterSetName = 'List of CC Types')]
        [array]
        $typeOfCC,
        [Parameter(Mandatory = $true, ParameterSetName = 'Folders for CC')]
        [array]
        $folderForType,
        [Parameter(Mandatory = $true, ParameterSetName = 'Clean File Names')]
        [bool]
        $cleanFileNames
    )

    $messyGeneral = "$messyfolder\General\CC_Unmerged"
    $messyModern = "$messyfolder\Modern\CC_Unmerged"

    $creators = $creatorsList | Sort-Object -Uniq
    $creators = $creators | Sort-Object { $_.length } -Descending

    $folderContents = Get-ChildItem -File $messyfolder
    $packageCount = 0
    $packagesChecked = @()
    $logfile = "$messyFolder\Output.log"
    "" | Set-Content $logfile

    if ($cleanFileNames -eq $true) {
        Initialize-AutoSorting $messyfolder
    }

    foreach ($package in $folderContents) {
        if ($packagesChecked -contains $package) {
            Register-Package -package $package -packageCount $packageCount -logfile $logfile -exist $true -packagesChecked $packagesChecked
            $packageCount++
            Continue
        } else {
            Register-Package -package $package -packageCount $packageCount -logfile $logfile -exist $false -packagesChecked $packagesChecked
            $packageCount++
            $recoloristWitheringSims = "WitheringSims"
            $recoloristJewl = "JewlRefined"
            $recoloristCandy = "CandyNaturals"
            if ($package.BaseName -ilike "*$recoloristWitheringSims*"){
                Register-Package -package $package -packageCount $packageCount -logfile $logfile -exist $false -packagesChecked $packagesChecked -istype $true -type $recoloristWitheringSims
                if ($package.Basename -ilike "*roots*" -OR $package.Basename -ilike "*hairline*") {
                    $destination = "$messyGeneral\Hairlines\$recoloristWitheringSims"
                    Register-Package -package $package -packageCount $packageCount -logfile $logfile -exist $false -packagesChecked $packagesChecked -istype $false -creator $recoloristWitheringSims -type "Hairline" -destination $destination
                    New-Item -ItemType Directory -Force -Path $destination
                    Move-Item <#-Verbose-#>-#> -Path $($package.FullName) -Destination $destination
                } elseif ($package.Basename -ilike "*dyeaccessory*" -OR $package.BaseName -ilike "*headband*" -OR $package.BaseName -ilike "*hairband*" -OR $package.BaseName -ilike "*scrunchie*" -OR $package.BaseName -ilike "*clips*" -OR $package.BaseName -ilike "*ombre*" -OR $package.BaseName -ilike "*hairbow*" -OR $package.BaseName -ilike "*hairclips*") {
                    $destination = "$messyGeneral\HairAccessories\$recoloristWitheringSims"
                    Register-Package -package $package -packageCount $packageCount -logfile $logfile -exist $false -packagesChecked $packagesChecked -istype $false -creator $recoloristWitheringSims -type "Hair Accessory" -destination $destination
                    New-Item -ItemType Directory -Force -Path $destination
                    Move-Item <#-Verbose-#>-#> -Path $($package.FullName) -Destination $destination
                } elseif ($package.BaseName -ilike "*overlayacc*") { 
                    $destination = "$messyModern\Accessories\ColorOverlays\$recoloristWitheringSims"
                    Register-Package -package $package -packageCount $packageCount -logfile $logfile -exist $false -packagesChecked $packagesChecked -istype $false -creator $recoloristWitheringSims -type "Color Overlay" -destination $destination
                    New-Item -ItemType Directory -Force -Path $destination
                    Move-Item <#-Verbose-#>-#> -Path $($package.FullName) -Destination $destination
                } elseif ($package.BaseName -ilike "*top*" -OR $package.BaseName -ilike "*bottom*" -OR $package.BaseName -ilike "*bodysuit*" -OR $package.BaseName -ilike "*jeans*" -OR $package.BaseName -ilike "*outfit*" -OR $package.BaseName -ilike "*pants*" -OR $package.BaseName -ilike "*skirt*" -OR $package.BaseName -ilike "*sweater*" -OR $package.BaseName -ilike "*shirt*") {
                    $destination = "$messyModern\Clothing\$recoloristWitheringSims"
                    Register-Package -package $package -packageCount $packageCount -logfile $logfile -exist $false -packagesChecked $packagesChecked -istype $false -creator $recoloristWitheringSims -type "Clothing" -destination $destination
                    New-Item -ItemType Directory -Force -Path $destination
                    Move-Item <#-Verbose-#>-#> -Path $($package.FullName) -Destination $destination
                } elseif ($package.BaseName -ilike "*hair*" -OR $package.BaseName -ilike "*hairstyle*" -OR $package.BaseName -ilike "*twintails*" -OR $package.BaseName -ilike "*ponytail*" -OR $package.BaseName -ilike "*braid*" -OR $package.BaseName -ilike "*hairstyle*") {
                    $destination = "$messyGeneral\HairRecolors\$recoloristWitheringSims"
                    Register-Package -package $package -packageCount $packageCount -logfile $logfile -exist $false -packagesChecked $packagesChecked -istype $false -creator $recoloristWitheringSims -type "Hair" -destination $destination
                    New-Item -ItemType Directory -Force -Path $destination
                    Move-Item <#-Verbose-#>-#> -Path $($package.FullName) -Destination $destination
                } elseif ($package.BaseName -ilike "*sneakers*" -OR $package.BaseName -ilike "*shoes*") {
                    $destination = "$messyModern\Shoes\$recoloristWitheringSims"
                    Register-Package -package $package -packageCount $packageCount -logfile $logfile -exist $false -packagesChecked $packagesChecked -istype $false -creator $recoloristWitheringSims -type "Shoes" -destination $destination
                    New-Item -ItemType Directory -Force -Path $destination
                    Move-Item <#-Verbose-#>-#> -Path $($package.FullName) -Destination $destination
                }  elseif ($package.Basename -ilike "*acc*") {
                    $destination = "$messyModern\Accessories\$recoloristWitheringSims"
                    Register-Package -package $package -packageCount $packageCount -logfile $logfile -exist $false -packagesChecked $packagesChecked -istype $false -creator $recoloristWitheringSims -type "Accessories" -destination $destination
                    New-Item -ItemType Directory -Force -Path $destination
                    Move-Item <#-Verbose-#>-#> -Path $($package.FullName) -Destination $destination
                } else {
                    $destination = "$manualSort\$recoloristWitheringSims"
                    Register-Package -package $package -packageCount $packageCount -logfile $logfile -exist $false -packagesChecked $packagesChecked -istype $false -destination $destination -creatorNoType $true -creator $recoloristWitheringSims
                    New-Item -ItemType Directory -Force -Path $destination
                    Move-Item <#-Verbose-#>-#> -Path $($package.FullName) -Destination $destination
                }
            } elseif ($package.BaseName -ilike "*jewl*"){ 
                Register-Package -package $package -packageCount $packageCount -logfile $logfile -exist $false -packagesChecked $packagesChecked -istype $true -type $recoloristJewl
                if ($package.Basename -ilike "*roots*" -OR $package.Basename -ilike "*hairline*") {
                    $destination = "$messyGeneral\Hairlines\$recoloristJewl"
                    Register-Package -package $package -packageCount $packageCount -logfile $logfile -exist $false -packagesChecked $packagesChecked -istype $false -creator $recoloristJewl -type "Hairline" -destination $destination
                    New-Item -ItemType Directory -Force -Path $destination
                    Move-Item <#-Verbose-#>-#> -Path $($package.FullName) -Destination $destination
                } elseif ($package.Basename -ilike "*dyeaccessory*" -OR $package.BaseName -ilike "*headband*" -OR $package.BaseName -ilike "*hairband*" -OR $package.BaseName -ilike "*scrunchie*" -OR $package.BaseName -ilike "*clips*" -OR $package.BaseName -ilike "*ombre*" -OR $package.BaseName -ilike "*hairbow*" -OR $package.BaseName -ilike "*hairclips*") {
                    $destination = "$messyGeneral\HairAccessories\$recoloristJewl"
                    Register-Package -package $package -packageCount $packageCount -logfile $logfile -exist $false -packagesChecked $packagesChecked -istype $false -creator $recoloristJewl -type "Hair Accessory" -destination $destination
                    New-Item -ItemType Directory -Force -Path $destination
                    Move-Item <#-Verbose-#>-#> -Path $($package.FullName) -Destination $destination
                } elseif ($package.BaseName -ilike "*overlayacc*") { 
                    $destination = "$messyModern\Accessories\ColorOverlays\$recoloristJewl"
                    Register-Package -package $package -packageCount $packageCount -logfile $logfile -exist $false -packagesChecked $packagesChecked -istype $false -creator $recoloristJewl -type "Color Overlay" -destination $destination
                    New-Item -ItemType Directory -Force -Path $destination
                    Move-Item <#-Verbose-#>-#> -Path $($package.FullName) -Destination $destination
                } elseif ($package.BaseName -ilike "*top*" -OR $package.BaseName -ilike "*bottom*" -OR $package.BaseName -ilike "*bodysuit*" -OR $package.BaseName -ilike "*jeans*" -OR $package.BaseName -ilike "*outfit*" -OR $package.BaseName -ilike "*pants*" -OR $package.BaseName -ilike "*skirt*" -OR $package.BaseName -ilike "*sweater*" -OR $package.BaseName -ilike "*shirt*") {
                    $destination = "$messyModern\Clothing\$recoloristJewl"
                    Register-Package -package $package -packageCount $packageCount -logfile $logfile -exist $false -packagesChecked $packagesChecked -istype $false -creator $recoloristJewl -type "Clothing" -destination $destination
                    New-Item -ItemType Directory -Force -Path $destination
                    Move-Item <#-Verbose-#>-#> -Path $($package.FullName) -Destination $destination
                } elseif ($package.BaseName -ilike "*hair*" -OR $package.BaseName -ilike "*hairstyle*" -OR $package.BaseName -ilike "*twintails*" -OR $package.BaseName -ilike "*ponytail*" -OR $package.BaseName -ilike "*braid*" -OR $package.BaseName -ilike "*hairstyle*") {
                    $destination = "$messyGeneral\HairRecolors\$recoloristJewl"
                    Register-Package -package $package -packageCount $packageCount -logfile $logfile -exist $false -packagesChecked $packagesChecked -istype $false -creator $recoloristJewl -type "Hair" -destination $destination
                    New-Item -ItemType Directory -Force -Path $destination
                    Move-Item <#-Verbose-#>-#> -Path $($package.FullName) -Destination $destination
                } elseif ($package.BaseName -ilike "*sneakers*" -OR $package.BaseName -ilike "*shoes*") {
                    $destination = "$messyModern\Shoes\$recoloristJewl"
                    Register-Package -package $package -packageCount $packageCount -logfile $logfile -exist $false -packagesChecked $packagesChecked -istype $false -creator $recoloristJewl -type "Shoes" -destination $destination
                    New-Item -ItemType Directory -Force -Path $destination
                    Move-Item <#-Verbose-#>-#> -Path $($package.FullName) -Destination $destination
                }  elseif ($package.Basename -ilike "*acc*") {
                    $destination = "$messyModern\Accessories\$recoloristJewl"
                    Register-Package -package $package -packageCount $packageCount -logfile $logfile -exist $false -packagesChecked $packagesChecked -istype $false -creator $recoloristJewl -type "Accessories" -destination $destination
                    New-Item -ItemType Directory -Force -Path $destination
                    Move-Item <#-Verbose-#>-#> -Path $($package.FullName) -Destination $destination
                } else {
                    $destination = "$manualSort\$recoloristJewl"
                    Register-Package -package $package -packageCount $packageCount -logfile $logfile -exist $false -packagesChecked $packagesChecked -istype $false -destination $destination -creatorNoType $true -creator $recoloristJewl
                    New-Item -ItemType Directory -Force -Path $destination
                    Move-Item <#-Verbose-#>-#> -Path $($package.FullName) -Destination $destination
                }
            } elseif ($package.BaseName -ilike "*candynaturals*"){ 
                Register-Package -package $package -packageCount $packageCount -logfile $logfile -exist $false -packagesChecked $packagesChecked -istype $true -type $recoloristCandy
                if ($package.Basename -ilike "*roots*" -OR $package.Basename -ilike "*hairline*") {
                    $destination = "$messyGeneral\Hairlines\$recoloristCandy"
                    Register-Package -package $package -packageCount $packageCount -logfile $logfile -exist $false -packagesChecked $packagesChecked -istype $false -creator $recoloristCandy -type "Hairline" -destination $destination
                    New-Item -ItemType Directory -Force -Path $destination
                    Move-Item <#-Verbose-#>-#> -Path $($package.FullName) -Destination $destination
                } elseif ($package.Basename -ilike "*dyeaccessory*" -OR $package.BaseName -ilike "*headband*" -OR $package.BaseName -ilike "*hairband*" -OR $package.BaseName -ilike "*scrunchie*" -OR $package.BaseName -ilike "*clips*" -OR $package.BaseName -ilike "*ombre*" -OR $package.BaseName -ilike "*hairbow*" -OR $package.BaseName -ilike "*hairclips*") {
                    $destination = "$messyGeneral\HairAccessories\$recoloristCandy"
                    Register-Package -package $package -packageCount $packageCount -logfile $logfile -exist $false -packagesChecked $packagesChecked -istype $false -creator $recoloristCandy -type "Hair Accessory" -destination $destination
                    New-Item -ItemType Directory -Force -Path $destination
                    Move-Item <#-Verbose-#>-#> -Path $($package.FullName) -Destination $destination
                } elseif ($package.BaseName -ilike "*overlayacc*") { 
                    $destination = "$messyModern\Accessories\ColorOverlays\$recoloristCandy"
                    Register-Package -package $package -packageCount $packageCount -logfile $logfile -exist $false -packagesChecked $packagesChecked -istype $false -creator $recoloristCandy -type "Color Overlay" -destination $destination
                    New-Item -ItemType Directory -Force -Path $destination
                    Move-Item <#-Verbose-#>-#> -Path $($package.FullName) -Destination $destination
                } elseif ($package.BaseName -ilike "*top*" -OR $package.BaseName -ilike "*bottom*" -OR $package.BaseName -ilike "*bodysuit*" -OR $package.BaseName -ilike "*jeans*" -OR $package.BaseName -ilike "*outfit*" -OR $package.BaseName -ilike "*pants*" -OR $package.BaseName -ilike "*skirt*" -OR $package.BaseName -ilike "*sweater*" -OR $package.BaseName -ilike "*shirt*") {
                    $destination = "$messyModern\Clothing\$recoloristCandy"
                    Register-Package -package $package -packageCount $packageCount -logfile $logfile -exist $false -packagesChecked $packagesChecked -istype $false -creator $recoloristCandy -type "Clothing" -destination $destination
                    New-Item -ItemType Directory -Force -Path $destination
                    Move-Item <#-Verbose-#>-#> -Path $($package.FullName) -Destination $destination
                } elseif ($package.BaseName -ilike "*hair*" -OR $package.BaseName -ilike "*hairstyle*" -OR $package.BaseName -ilike "*twintails*" -OR $package.BaseName -ilike "*ponytail*" -OR $package.BaseName -ilike "*braid*" -OR $package.BaseName -ilike "*hairstyle*") {
                    $destination = "$messyGeneral\HairRecolors\$recoloristCandy"
                    Register-Package -package $package -packageCount $packageCount -logfile $logfile -exist $false -packagesChecked $packagesChecked -istype $false -creator $recoloristCandy -type "Hair" -destination $destination
                    New-Item -ItemType Directory -Force -Path $destination
                    Move-Item <#-Verbose-#>-#> -Path $($package.FullName) -Destination $destination
                } elseif ($package.BaseName -ilike "*sneakers*" -OR $package.BaseName -ilike "*shoes*") {
                    $destination = "$messyModern\Shoes\$recoloristCandy"
                    Register-Package -package $package -packageCount $packageCount -logfile $logfile -exist $false -packagesChecked $packagesChecked -istype $false -creator $recoloristCandy -type "Shoes" -destination $destination
                    New-Item -ItemType Directory -Force -Path $destination
                    Move-Item <#-Verbose-#>-#> -Path $($package.FullName) -Destination $destination
                }  elseif ($package.Basename -ilike "*acc*") {
                    $destination = "$messyModern\Accessories\$recoloristCandy"
                    Register-Package -package $package -packageCount $packageCount -logfile $logfile -exist $false -packagesChecked $packagesChecked -istype $false -creator $recoloristCandy -type "Accessories" -destination $destination
                    New-Item -ItemType Directory -Force -Path $destination
                    Move-Item <#-Verbose-#>-#> -Path $($package.FullName) -Destination $destination
                } else {
                    $destination = "$manualSort\$recoloristCandy"
                    Register-Package -package $package -packageCount $packageCount -logfile $logfile -exist $false -packagesChecked $packagesChecked -istype $false -destination $destination -creatorNoType $true -creator $recoloristCandy
                    New-Item -ItemType Directory -Force -Path $destination
                    Move-Item <#-Verbose-#>-#> -Path $($package.FullName) -Destination $destination
                }
            } elseif ($package.BaseName -ilike "*lorysims*") {
                $destination = "$messyModern\Cars\LorySims"
                Register-Package -package $package -packageCount $packageCount -logfile $logfile -exist $false -packagesChecked $packagesChecked -istype $false -destination $destination -creatorNoType $true -creator "LorySims"
                New-Item -ItemType Directory -Force -Path $destination
                Move-Item <#-Verbose-#>-#> -Path $($package.FullName) -Destination $destination
            } else {
                for ($typeCount=0; $typeOfCC.Count -gt $typeCount; $typeCount++) {
                    $typeCheck = $typeOfCC[$typeCount]
                    $typeLength = $typeOfCC.Length
                    if ($packagesChecked -contains $package) {
                        Register-Package -package $package -packageCount $packageCount -logfile $logfile -alreadymoved $true -packagesChecked $packagesChecked
                        Continue
                    } else {
                        if ($package.BaseName -ilike "*$typeCheck*") { #discover the type
                            $mainFolder = $folderForType[$typeCount]
                            for ($creatorsCount=0; $creators.Count -gt $creatorsCount; $creatorsCount++) {
                                $creatorCheck = $creators[$creatorsCount]
                                $creatorsLength = $creators.Length
                                if ($package.BaseName -ilike "*$creatorCheck*") { #match to a creator
                                    $destination = "$mainFolder\$creatorCheck"
                                    Register-Package -package $package -packageCount $packageCount -logfile $logfile -packagesChecked $packagesChecked -return $true -destination $destination -type $typeCheck -isType $false -creator $creatorCheck
                                    New-Item -ItemType Directory -Force -Path $destination
                                    Move-Item <#-Verbose-#> -Path $($package.FullName) -Destination "$destination\$($package.Name)"

                                } elseif ($creatorsLength -le $creatorsCount) {
                                    $destination = $mainFolder
                                    Register-Package -package $package -packageCount $packageCount -logfile $logfile -packagesChecked $packagesChecked -return $true -destination $destination -type $typeCheck -isType $false -creatorfound $false
                                    New-Item -ItemType Directory -Force -Path $destination
                                    Move-Item <#-Verbose-#> -Path $($package.FullName) -Destination "$destination\$($package.Name)"
                                }
                            }
                        } elseif ($typeLength -le $typeCount) {
                            Register-Package -package $package -packageCount $packageCount -logfile $logfile -packagesChecked $packagesChecked -return $true -destination $manualSort
                            New-Item -ItemType Directory -Force -Path $manualSort
                            Move-Item <#-Verbose-#> -Path $($package.FullName) -Destination "$manualSort\$($package.Name)"
                        }
                    }
                }
            }
        }

    }
}



################################

$startingVars = Get-Variable

###########VARS###############

$creatorsList = @("001studiok", "26ink", "4w25", "Aa", "Ada", "Adiec", "Afs", "Ah00b", "Ah00bxbop", "Akuiyumi", "Aladdin", "Alessandrae", "Alexaarr", "Alfsi", "Algue", "Aliens", "Alin22", "Alsoidyia", "Aluckyday", "Amelylina", "Ametrinesims", "Ancasims", "Angissi", "Animalcostumes", "Anto", "Arenetta", "Arethabee", "Artup", "Atashi77", "Awesomeajuga", "Axa", "Axa2019hairs", "Axa2020hairs", "Axaparishairs", "Axaspringcollectionhairs", "Azleia","Baddiesims", "Badkarma", "BatsFromWesteros", "Beardsps", "Beardsseleng", "Beccab323", "BedTS4", "Berrybloom", "Beo", "Bexosims", "Bimbosim", "Birksche", "Blahberrypancake", "Blewis", "Bluemoonsims", "Bluesparkling", "Blvckls", "Bm", "Bobur", "Bobur", "Boobish", "Boobishenrique", "Boobishsimmandy", "Bps", "Breathinsims", "Brianitesims", "Busenur41", "Busratr", "Bustedpixels", "Butterscotchsims", "Buzzard", "Bybukovka", "Cabsims", "Caearsims", "Caesarsims", "Candysims4", "Capitalco", "Caribbeanpatch", "Carol", "Caroll91", "Casteru", "Catpintwoh", "Catplnt", "Catus", "Chippedsim", "Christopher067", "Citrontart", "Clumsyalien", "Cmt", "Cosimetic", "Cottoncandy", "Cowconuts", "Crayolablaze", "Crazycupcake", "Crownsondisplay", "Crypticsim", "Csxdsxoxtoakiyo", "Cubersimsxoakiyo", "Cupidjuice", "Curbs", "Cyberaddix", "Daylifesims", "Db", "Desysimmer", "Devilicious", "Dfjkellyhb5", "Disanity", "Divadoom", "Divinecap", "Dntsr", "Dogsill", "Domi", "Dreamtart", "Druidsim", "Ebonix","Eirflower", "Ellesmea", "Emythegamer", "Enrique", "Enriquexsentate", "Ersch", "Evoxy", "Fadedsprings", "Faez", "Feline", "Feralpoodles", "Fifthscreations", "Fivesims", "Fivesimsxwildpixel", "Florauh", "Frostsims", "G1g2", "Georgiaglm", "Gildedghosts", "Glaza", "Glitterberrysims", "Gpme", "Grafity", "Gramsims", "Greenllamas", "Grimcookies", "Habsims", "Hallowsims", "Hgcc", "Historicalsimslife", "Hoa", "Holosprite", "Horns", "Ht0", "Ikarisims", "Imadako", "Imvikai", "Infinityonsims", "Infusedpeach", "Insects", "Isjao", "Isjaoleeleesims1", "Ivosims", "Ixs", "Jhcosmetics", "Joliebean", "Joliebean", "Joliebeanxhfoxsentate", "Kamiiri", "Katverse", "Kiara24", "Kiarazurk", "Kiko", "Kismetsims", "Kiwisims4", "Kotcat", "Kotcatxisjao", "Kotcatxisjao", "Kumikya", "Kxi", "Kyuusims", "Leeleesims1", "Lexits4", "Lightdeficient", "Lilasims", "Linkysims", "Linzlu", "Lollaleeloo", "Lunacress", "Lune", "Luumia", "Magicbot", "Mannequin", "Marigold", "Marsosims", "Mathcope", "Maxiematch", "Mb", "Meghewlett", "Melissasims", "Mellouwsim", "Meltingedge", "Melunn", "Mer", "Miiko", "Milkyki", "Mk9", "Mlys", "Modmax", "Mohkii", "Moonchildlovesthenight", "Moonpres", "Moriel", "Moxxxes", "Msmarysims", "Msqsims", "Mssims", "Musae", "Musicalsimmer", "Myobi", "Naevyssims", "Natalieauditore", "Nell", "Nesurii", "Nickname", "Noiranddarksims", "Nolansims", "Nolansimsxteanmoon", "Nooboos", "Noodles", "Noodlesremixsaurus", "Nords", "Normalsiim", "Notdaniella", "Notegain", "Novvvas", "Nsxnd", "Numberswoman", "Oakiyo", "Obscurus", "Okruee", "Oksanaoliver", "Onyxsims4", "Opiumhoney", "Oranos", "Overkillsimmer", "Paranormaladdonhairs", "Parise", "Pbox", "Peachibloom", "Peebs", "Pfoten", "Pinealexple", "Pinkpatchy", "Plumbobteasociety", "Pnf", "Pooklet", "Pridesim", "Ps", "Pupcake", "Pupusims", "Pxelboy", "Pyxis", "Qicc", "Qrsims", "Qwerty", "Qwertysims", "Raiichuu", "Raspberrysims", "Remussirion", "Renorasims", "Retropixels", "Ridgecookies", "Ridgeport", "Rigelsims", "Ropey", "Rubybird", "Rustyxsentate", "Rusty", "S4simomo", "Saartje77", "Salttry", "Satterlly", "Saurus", "Saurusxbop", "Savagesim", "Savvysweet", "Savvyxgrim", "Sayasims", "Sclub", "Seleng", "Semplicesims", "Serenity", "Servotea", "Severinka", "Sfs", "Sg5150", "Sheabuttyr", "Shespeakssimlish", "Shuiisims", "Shysimblr", "Sideburns", "Simancholy", "Simandy", "Simarillion", "Simbiance", "Simbience", "Simcelebrity00", "Simduction", "Simgguk", "Simiracle", "Simlotus", "Simmandy", "Simmerstesia", "Simplesimmer", "Simplicitay", "Simplifiedsimi", "Sims3melancholic", "Sims41ife", "Sims4pack", "Simserenity", "Simshini", "Simstefani", "Simstrouble", "Simsza", "Simtric", "Simtric", "Sina", "Singingpickles", "Skellysim", "Sll", "Sls", "Slythersim", "Softerhaze", "Soli", "Soloriya", "Sondescent", "Sonyasims", "Sparrows", "Spinningplumbobs", "Spookyspookysim", "Ssb", "Sspx", "Stephaniesims", "Stephanine", "Stretchskeleton", "Subtlestubble", "Sugarowl", "Suiminntyuusims", "Sulsul", "Suzue", "Suzue", "Sweettacoplumbob", "Sxb", "Sxltss", "Syaovu", "Sylviemy", "Teanmoon", "Tekrisims", "Thecrimsonsimmer", "Thekalino", "Thessia", "Tiefling", "Tong", "Toskami", "Toskasims", "Trillyke", "Tssskellysim", "Tts", "Twinksimstress", "Twistedcat", "Vain", "Valhallan", "Veve", "Viiavi", "Vikai", "Vikaixgreenllamas", "Vikaixrenorasims", "Vitiligo", "Vittleruniverse", "Vittleruniverses4", "Voidsimtric", "Vro", "Vxgglitter", "Waekey", "Watersim44","Weepingsimmer", "Wh", "Wiccandove", "Wildpixel", "Wildpixelxah00b", "Wildspit", "Wistfulcastle", "Wms", "Wondercarlotta", "Wyattsims", "Xghostx", "Xld", "Zaneidacu", "Zebrazest", "Zenx", "Zeussim", "Anlamveg", "Anonimux", "Hanraja", "AphroditeSims", "Nords", "Sifix", "AdrienPastel", "Cozyyeons", "CrypticSim", "Birkshe", "CUUPIDCORP", "Dreamgirl", "TUDS", "Daylifesims", "Darlyssims", "ddaengsims", "deetronx", "deelitefulsimmer", "demondare", "dew", "disorganaized", "divinecap", "dyoreos", "eipi", "Georgiaglm", "gfv74", "gildedghosts", "gingerllama", "gloomfish", "graphix", "GS", "harluxe", "HFO", "HFOxSentate", "honeyssims4", "hos", "shy", "hydra", "icecreamforbreakfast", "icfb", "igor", "imf", "imsamuelcc", "ingeliwfs", "wasabisims", "isjao", "ixs", "ivosims", "iyasts4", "javasims", "jellymoo", "jhcosmetics", "johnnysims", "jius", "joliebean", "kamidus", "kamiiri", "kitty25939", "kiwisim4", "kksims", "kliekie", "km", "kotake", "kotcat", "kumikya", "kylie", "softsimmer", "landgraabbed", "leafmotif", "leeleesims", "azertysims", "liliili", "littledica", "lls", "llumisims", "ln", "lonelyboyts4", "lorysims", "lotusplum", "lotuswhim", "ls", "lutessa", "luumia", "luutzi", "lvndre", "maddy", "magichand", "mari", "marigolde", "marsosims", "marvell", "maytaiii", "mc", "mcltn", "mechtasims", "meghewlett", "melonsloth", "miiko", "miraim", "mmsims", "mooncakesims", "beeniebaby", "msmarysims", "mycupofcc", "mvg", "myshunosun", "nekochan", "nickname", "nolansims", "normalsiim", "nucrests", "oakiyo", "okruee", "oni", "onyxsims4", "parissimmer", "peachyfaerie", "severinka", "pixelette", "plummetya", "pnf", "powluna", "praleska", "pralinesims", "pvrplehaze", "pxelboy", "qicc", "qrsims", "quidx", "qvoix", "qwerty", "raspbxxry", "ratboy", "ravensim", "rb", "renorasims", "rheallsim", "rigelsims", "azertysims", "s4tink", "sammixox", "salttry", "scarlett", "scb", "sclub", "sehablasimlish", "seleng","semplicesims", "shespeakssimlish", "shibuisims", "shs", "simancholy", "simandy", "simiracle", "simkoos", "simmerianne93", "simplesimmer", "simmireenxherecirmxsimmerianne93", "sims3melancholic", "sims41ife", "simsberrry", "simstomaggie", "simstrouble", "simthingclever", "simtographies", "simtric", "sixamcc", "sleepingsims", "smxir", "softsimmer", "soguewimvikai", "solistair", "sp", "spinningplumbobs", "srslysims", "starkknaked", "starry", "stephanine", "storylsims", "sukyoolent", "sunivaa", "surelysims", "suzue", "sw", "tawney", "thisisthema", "tillie", "tiosims", "tpn", "trillyke", "ts4041", "turksimmer", "twistedcat", "uglysim", "ubp", "valleytulya", "valuka", "veigasims", "veve", "victorrmiguell", "vikaixgreenllamas", "vikaixrenorasims", "vxgglitter", "weepingsimmer", "wildpixel", "wistfulcastle", "xld", "yooniesim", "zenx", "zeussim", "zxtats4", "alladin", "amoebae". "bellassims", "bluecraving", "boonstow")

$typeOfCC = @(<#--- -1 ---#> "brooch",
    <#--- 0 ---#> "valhallan",
    <#--- 1 ---#> "1900",
    <#--- 2 ---#> "1901",
    <#--- 3 ---#> "1902",
    <#--- 4 ---#> "1903",
    <#--- 5 ---#> "1904",
    <#--- 6 ---#> "1905",
    <#--- 7 ---#> "1906",
    <#--- 8 ---#> "1907",
    <#--- 9 ---#> "1908",
    <#--- 10 ---#> "1909",
    <#--- 11 ---#> "1910",
    <#--- 12 ---#> "1911",
    <#--- 13 ---#> "1912",
    <#--- 14 ---#> "1913",
    <#--- 15 ---#> "1914",
    <#--- 16 ---#> "1915",
    <#--- 17 ---#> "1916",
    <#--- 18 ---#> "1917",
    <#--- 19 ---#> "1918",
    <#--- 20 ---#> "1919",
    <#--- 21 ---#> "1920",
    <#--- 22 ---#> "1921",
    <#--- 23 ---#> "1922",
    <#--- 24 ---#> "1923",
    <#--- 25 ---#> "1924",
    <#--- 26 ---#> "1925",
    <#--- 27 ---#> "1926",
    <#--- 28 ---#> "1927",
    <#--- 29 ---#> "1928",
    <#--- 30 ---#> "1929",
    <#--- 31 ---#> "1930",
    <#--- 32 ---#> "1931",
    <#--- 33 ---#> "1932",
    <#--- 34 ---#> "1933",
    <#--- 35 ---#> "1934",
    <#--- 36 ---#> "1935",
    <#--- 37 ---#> "1936",
    <#--- 38 ---#> "1937",
    <#--- 39 ---#> "1938",
    <#--- 40 ---#> "1939",
    <#--- 41 ---#> "1940",
    <#--- 42 ---#> "1941",
    <#--- 43 ---#> "1942",
    <#--- 44 ---#> "1943",
    <#--- 45 ---#> "1944",
    <#--- 46 ---#> "1945",
    <#--- 47 ---#> "1946",
    <#--- 48 ---#> "1947",
    <#--- 49 ---#> "1948",
    <#--- 50 ---#> "1949",
    <#--- 51 ---#> "1950",
    <#--- 52 ---#> "1951",
    <#--- 53 ---#> "1952",
    <#--- 54 ---#> "1953",
    <#--- 55 ---#> "1954",
    <#--- 56 ---#> "1955",
    <#--- 57 ---#> "1956",
    <#--- 58 ---#> "1957",
    <#--- 59 ---#> "1958",
    <#--- 60 ---#> "1959",
    <#--- 61 ---#> "1960",
    <#--- 62 ---#> "1961",
    <#--- 63 ---#> "1962",
    <#--- 64 ---#> "1963",
    <#--- 65 ---#> "1964",
    <#--- 66 ---#> "1965",
    <#--- 67 ---#> "1966",
    <#--- 68 ---#> "1967",
    <#--- 69 ---#> "1968",
    <#--- 70 ---#> "1969",
    <#--- 71 ---#> "1970",
    <#--- 72 ---#> "1971",
    <#--- 73 ---#> "1972",
    <#--- 74 ---#> "1973",
    <#--- 75 ---#> "1974",
    <#--- 76 ---#> "1975",
    <#--- 77 ---#> "1976",
    <#--- 78 ---#> "1977",
    <#--- 79 ---#> "1978",
    <#--- 80 ---#> "1979",
    <#--- 81 ---#> "1980",
    <#--- 82 ---#> "1981",
    <#--- 83 ---#> "1982",
    <#--- 84 ---#> "1983",
    <#--- 85 ---#> "1984",
    <#--- 86 ---#> "1985",
    <#--- 87 ---#> "1986",
    <#--- 88 ---#> "1987",
    <#--- 89 ---#> "1988",
    <#--- 90 ---#> "1989",
    <#--- 91 ---#> "1990",
    <#--- 92 ---#> "1991",
    <#--- 93 ---#> "1992",
    <#--- 94 ---#> "1993",
    <#--- 95 ---#> "1994",
    <#--- 96 ---#> "1995",
    <#--- 97 ---#> "1996",
    <#--- 98 ---#> "1997",
    <#--- 99 ---#> "1998",
    <#--- 100 ---#> "1999",
    <#--- 101 ---#> "rococo",
    <#--- 102 ---#> "victorian",
    <#--- 103 ---#> "renaissance",
    <#--- 104 ---#> "apocalyp",
    <#--- 105 ---#> "medieval",
    <#--- 106 ---#> "TSM",
    <#--- 107 ---#> "cyberpunk",
    <#--- 108 ---#> "steampunk",
    <#--- 109 ---#> "colonial",
    <#--- 110 ---#> "baroque",
    <#--- 111 ---#> "tudor",
    <#--- 112 ---#> "11th",
    <#--- 113 ---#> "12th",
    <#--- 114 ---#> "13th",
    <#--- 115 ---#> "14th",
    <#--- 116 ---#> "15th",
    <#--- 117 ---#> "16th",
    <#--- 118 ---#> "17th",
    <#--- 119 ---#> "18th",
    <#--- 120 ---#> "19th",
    <#--- 121 ---#> "rustic",
    <#--- 122 ---#> "candle",
    <#--- 123 ---#> "animation",
    <#--- 124 ---#> "nosemask",
    <#--- 125 ---#> "wallcolor",
    <#--- 126 ---#> "wallcolour",
    <#--- 127 ---#> "vitiligo",
    <#--- 128 ---#> "simtasia",
    <#--- 129 ---#> "simtric",
    <#--- 130 ---#> "puppycrow*hair",
    <#--- 131 ---#> "hair*puppycrow",
    <#--- 132 ---#> "sorbets*hair",
    <#--- 133 ---#> "hair*sorbets",
    <#--- 134 ---#> "sorbetsremix",
    <#--- 135 ---#> "sorbets",
    <#--- 136 ---#> "roselipa",
    <#--- 137 ---#> "S4Anachrosims",
    <#--- 139 ---#> "satterlly",
    <#--- 140 ---#> "simart",
    <#--- 141 ---#> "occult",
    <#--- 142 ---#> "bodysuit*acc",
    <#--- 143 ---#> "acc*bodysuit",
    <#--- 144 ---#> "bra*acc",
    <#--- 145 ---#> "acc*bra",
    <#--- 146 ---#> "corset*acc",
    <#--- 147 ---#> "acc*corset",
    <#--- 148 ---#> "fairy",
    <#--- 149 ---#> "supergirl",
    <#--- 150 ---#> "superboy",
    <#--- 151 ---#> "ghost",
    <#--- 152 ---#> "skeleton",
    <#--- 153 ---#> "piercing",
    <#--- 154 ---#> "necrodog",
    <#--- 155 ---#> "uniform",
    <#--- 156 ---#> "preset",
    <#--- 157 ---#> "slider",
    <#--- 158 ---#> "necklace",
    <#--- 159 ---#> "glasses",
    <#--- 160 ---#> "socks",
    <#--- 161 ---#> "tights",
    <#--- 162 ---#> "stockings",
    <#--- 163 ---#> "veil",
    <#--- 164 ---#> "scarftop",
    <#--- 165 ---#> "scarf",
    <#--- 166 ---#> "bonnet",
    <#--- 167 ---#> "bandana",
    <#--- 168 ---#> "bandanna",
    <#--- 169 ---#> "beret",
    <#--- 170 ---#> "bandeau",
    <#--- 171 ---#> "earrings",
    <#--- 172 ---#> "earings",
    <#--- 173 ---#> "overlay",
    <#--- 174 ---#> "eyelashes",
    <#--- 175 ---#> "lashes",
    <#--- 176 ---#> "braids",
    <#--- 177 ---#> "armlet",
    <#--- 178 ---#> "bodysuit",
    <#--- 179 ---#> "lipstick",
    <#--- 180 ---#> "eyeshadow",
    <#--- 181 ---#> "eyeliner",
    <#--- 182 ---#> "eyebrow",
    <#--- 183 ---#> "beard",
    <#--- 184 ---#> "mustache",
    <#--- 185 ---#> "sideburn",
    <#--- 186 ---#> "hairpin",
    <#--- 187 ---#> "afbottom",
    <#--- 188 ---#> "ambottom",
    <#--- 189 ---#> "aftop",
    <#--- 190 ---#> "amtop",
    <#--- 191 ---#> "afoutfit",
    <#--- 192 ---#> "amoutfit",
    <#--- 193 ---#> "afhair",
    <#--- 194 ---#> "tshirt",
    <#--- 195 ---#> "jeans",
    <#--- 196 ---#> "trousers",
    <#--- 197 ---#> "shorts",
    <#--- 198 ---#> "pullover",
    <#--- 199 ---#> "hijab",
    <#--- 200 ---#> "ombreacc",
    <#--- 201 ---#> "skindetail",
    <#--- 202 ---#> "skinblend",
    <#--- 203 ---#> "freckles",
    <#--- 204 ---#> "nails",
    <#--- 205 ---#> "headband",
    <#--- 206 ---#> "hairband",
    <#--- 207 ---#> "hairclips",
    <#--- 208 ---#> "clips",
    <#--- 209 ---#> "kerchief",
    <#--- 210 ---#> "dresser",
    <#--- 211 ---#> "coffeetable",
    <#--- 212 ---#> "loveseat",
    <#--- 213 ---#> "accenttable",
    <#--- 214 ---#> "chezlounge",
    <#--- 215 ---#> "dyeaccessory",
    <#--- 216 ---#> "scrunchie",
    <#--- 217 ---#> "armchair",
    <#--- 218 ---#> "object",
    <#--- 219 ---#> "sweateracc",
    <#--- 220 ---#> "hanraja",
    <#--- 221 ---#> "mask",
    <#--- 222 ---#> "corsetacc",
    <#--- 223 ---#> "corset",
    <#--- 224 ---#> "curtain",
    <#--- 225 ---#> "blanket",
    <#--- 226 ---#> "bed",
    <#--- 227 ---#> "light",
    <#--- 228 ---#> "choker",
    <#--- 229 ---#> "plushie",
    <#--- 230 ---#> "blush",
    <#--- 231 ---#> "tattoo",
    <#--- 232 ---#> "piercing",
    <#--- 233 ---#> "plugs",
    <#--- 234 ---#> "DIYtree",
    <#--- 235 ---#> "tiara",
    <#--- 236 ---#> "crown",
    <#--- 237 ---#> "choker",
    <#--- 238 ---#> "reindeer",
    <#--- 239 ---#> "christmas",
    <#--- 240 ---#> "santa",
    <#--- 241 ---#> "decal",
    <#--- 242 ---#> "onesie",
    <#--- 243 ---#> "mirror",
    <#--- 244 ---#> "macrame",
    <#--- 245 ---#> "snowglobe",
    <#--- 246 ---#> "bookshelf",
    <#--- 247 ---#> "bookcase",
    <#--- 248 ---#> "chandelier",
    <#--- 249 ---#> "mattress",
    <#--- 250 ---#> "wallpaper",
    <#--- 251 ---#> "piercings",
    <#--- 252 ---#> "plant",
    <#--- 253 ---#> "colormix",
    <#--- 254 ---#> "acchat",
    <#--- 255 ---#> "sleeveless",
    <#--- 256 ---#> "panels",
    <#--- 257 ---#> "wallpanel",
    <#--- 258 ---#> "painting",
    <#--- 259 ---#> "mural",
    <#--- 260 ---#> "ceiling",
    <#--- 261 ---#> "portrait",
    <#--- 262 ---#> "tapestry",
    <#--- 263 ---#> "bench",
    <#--- 264 ---#> "overalls",
    <#--- 265 ---#> "tanktop",
    <#--- 266 ---#> "handjewelry",
    <#--- 267 ---#> "handjewelery",
    <#--- 268 ---#> "squishmallow",
    <#--- 269 ---#> "bouquet",
    <#--- 270 ---#> "romper",
    <#--- 271 ---#> "blouse",
    <#--- 272 ---#> "nosechain",
    <#--- 273 ---#> "accessoryjacket",
    <#--- 274 ---#> "acc*jacket",
    <#--- 275 ---#> "jacket*acc",
    <#--- 276 ---#> "garter",
    <#--- 277 ---#> "backpack",
    <#--- 278 ---#> "stilettos",
    <#--- 279 ---#> "undershirt",
    <#--- 280 ---#> "vest",
    <#--- 281 ---#> "tutu",
    <#--- 282 ---#> "pompom",
    <#--- 283 ---#> "croppedtop",
    <#--- 284 ---#> "leggings",
    <#--- 285 ---#> "decals",
    <#--- 286 ---#> "streetsign",
    <#--- 287 ---#> "wallflag",
    <#--- 288 ---#> "billboard",
    <#--- 289 ---#> "chalkboard",
    <#--- 290 ---#> "poster",
    <#--- 291 ---#> "slippers",
    <#--- 292 ---#> "keychain",
    <#--- 293 ---#> "hoodie",
    <#--- 294 ---#> "acccardigan",
    <#--- 295 ---#> "accessorycardigan",
    <#--- 296 ---#> "cardigan",
    <#--- 297 ---#> "accblazer",
    <#--- 298 ---#> "accessoryblazer",
    <#--- 299 ---#> "blazer",
    <#--- 300 ---#> "hairstyle",
    <#--- 301 ---#> "hairelastic",
    <#--- 302 ---#> "hairwreath",
    <#--- 303 ---#> "braid",
    <#--- 304 ---#> "override",
    <#--- 305 ---#> "fireplace",
    <#--- 306 ---#> "shrub",
    <#--- 307 ---#> "planter",
    <#--- 308 ---#> "plant",
    <#--- 309 ---#> "windowbox",
    <#--- 310 ---#> "chair",
    <#--- 311 ---#> "spandrel",
    <#--- 312 ---#> "jacket",
    <#--- 313 ---#> "dreads",
    <#--- 314 ---#> "yfhair",
    <#--- 315 ---#> "ymhair",
    <#--- 316 ---#> "braacc",
    <#--- 317 ---#> "pantiesacc",
    <#--- 318 ---#> "bikinibottomacc",
    <#--- 319 ---#> "bikinitopacc",
    <#--- 320 ---#> "bikini",
    <#--- 321 ---#> "pantsacc",
    <#--- 322 ---#> "jumpsuit",
    <#--- 323 ---#> "longsleeve",
    <#--- 324 ---#> "buttonup",
    <#--- 325 ---#> "watch",
    <#--- 326 ---#> "sweatpants",
    <#--- 327 ---#> "tightacc",
    <#--- 328 ---#> "tight",
    <#--- 329 ---#> "wrist",
    <#--- 330 ---#> "tiedshirt",
    <#--- 331 ---#> "pmbody",
    <#--- 332 ---#> "pmbottom",
    <#--- 333 ---#> "pmbody",
    <#--- 334 ---#> "pfhat",
    <#--- 335 ---#> "pfbody",
    <#--- 336 ---#> "pftop",
    <#--- 337 ---#> "pfbottom",
    <#--- 338 ---#> "putop",
    <#--- 339 ---#> "pubottom",
    <#--- 340 ---#> "pubody",
    <#--- 341 ---#> "babyhair",
    <#--- 342 ---#> "afro",
    <#--- 343 ---#> "braid",
    <#--- 344 ---#> "hairline",
    <#--- 345 ---#> "puffs",
    <#--- 346 ---#> "pigtail",
    <#--- 347 ---#> "flowerscu",
    <#--- 348 ---#> "flowerspu",
    <#--- 349 ---#> "yfbot",
    <#--- 350 ---#> "ymbot",
    <#--- 351 ---#> "yftop",
    <#--- 352 ---#> "ymtop",
    <#--- 353 ---#> "yfbody",
    <#--- 354 ---#> "ymbody",
    <#--- 355 ---#> "window",
    <#--- 356 ---#> "mohawk",
    <#--- 357 ---#> "console",
    <#--- 358 ---#> "pagdi",
    <#--- 359 ---#> "safa",
    <#--- 360 ---#> "swimsuit",
    <#--- 361 ---#> "marble",
    <#--- 362 ---#> "bottle",
    <#--- 363 ---#> "winerack",
    <#--- 364 ---#> "shelves",
    <#--- 365 ---#> "shelf",
    <#--- 366 ---#> "stool",
    <#--- 367 ---#> "desk",
    <#--- 368 ---#> "lamp",
    <#--- 369 ---#> "backyard",
    <#--- 370 ---#> "tray",
    <#--- 371 ---#> "lantern",
    <#--- 372 ---#> "skintone",
    <#--- 373 ---#> "divider",
    <#--- 374 ---#> "ponytail",
    <#--- 375 ---#> "lingerie",
    <#--- 376 ---#> "dresser",
    <#--- 377 ---#> "streakacc",
    <#--- 378 ---#> "streaksacc",
    <#--- 379 ---#> "roots",
    <#--- 380 ---#> "facepaint",
    <#--- 381 ---#> "selfie",
    <#--- 382 ---#> "kiosk",
    <#--- 383 ---#> "gasstation",
    <#--- 384 ---#> "sign",
    <#--- 385 ---#> "menu",
    <#--- 386 ---#> "facialhair",
    <#--- 387 ---#> "liner",
    <#--- 388 ---#> "stubble",
    <#--- 389 ---#> "goatee",
    <#--- 390 ---#> "clutter",
    <#--- 391 ---#> "headboard",
    <#--- 392 ---#> "loveseat",
    <#--- 393 ---#> "nectar",
    <#--- 394 ---#> "divider",
    <#--- 395 ---#> "vanity",
    <#--- 396 ---#> "motorbike",
    <#--- 397 ---#> "bike",
    <#--- 398 ---#> "dryer",
    <#--- 399 ---#> "washingmachine",
    <#--- 400 ---#> "dishwasher",
    <#--- 401 ---#> "duvet",
    <#--- 402 ---#> "cart",
    <#--- 403 ---#> "hamper",
    <#--- 404 ---#> "easel",
    <#--- 405 ---#> "muttonchops",
    <#--- 406 ---#> "shield",
    <#--- 407 ---#> "sword",
    <#--- 408 ---#> "arrow",
    <#--- 409 ---#> "hairbow",
    <#--- 410 ---#> "bow",
    <#--- 411 ---#> "moriel",
    <#--- 412 ---#> "office",
    <#--- 413 ---#> "storage",
    <#--- 414 ---#> "airpod",
    <#--- 415 ---#> "cabinet",
    <#--- 416 ---#> "microwave",
    <#--- 417 ---#> "fridge",
    <#--- 418 ---#> "refrigerator",
    <#--- 419 ---#> "refridgerator",
    <#--- 420 ---#> "stove",
    <#--- 421 ---#> "fountain",
    <#--- 422 ---#> "aircon",
    <#--- 423 ---#> "toothbrush",
    <#--- 424 ---#> "building",
    <#--- 425 ---#> "fireescape",
    <#--- 426 ---#> "street",
    <#--- 427 ---#> "nofoot",
    <#--- 428 ---#> "recipe",
    <#--- 429 ---#> "seveneleven",
    <#--- 430 ---#> "book",
    <#--- 431 ---#> "partition",
    <#--- 432 ---#> "pcts4",
    <#--- 433 ---#> "contour",
    <#--- 434 ---#> "pores",
    <#--- 435 ---#> "stretchmarks",
    <#--- 436 ---#> "faceshine",
    <#--- 437 ---#> "moles",
    <#--- 438 ---#> "mouthcorners",
    <#--- 439 ---#> "cleavage",
    <#--- 440 ---#> "pantry",
    <#--- 441 ---#> "eyebag",
    <#--- 442 ---#> "eyelid",
    <#--- 443 ---#> "amphora",
    <#--- 444 ---#> "lantern",
    <#--- 445 ---#> "boat",
    <#--- 446 ---#> "radio",
    <#--- 447 ---#> "concealer",
    <#--- 448 ---#> "palette",
    <#--- 449 ---#> "record",
    <#--- 450 ---#> "jumpsuit",
    <#--- 451 ---#> "coat",
    <#--- 452 ---#> "bodyhair",
    <#--- 453 ---#> "birthmark",
    <#--- 454 ---#> "locket",
    <#--- 455 ---#> "thong",
    <#--- 456 ---#> "sandals",
    <#--- 457 ---#> "bandaid",
    <#--- 458 ---#> "hoodie",
    <#--- 459 ---#> "earbud",
    <#--- 460 ---#> "fannypack",
    <#--- 461 ---#> "dimple",
    <#--- 462 ---#> "belly",
    <#--- 463 ---#> "pregnant",
    <#--- 464 ---#> "stretchmark",
    <#--- 465 ---#> "contact",
    <#--- 466 ---#> "bodyhighlight",
    <#--- 467 ---#> "bodyshine",
    <#--- 468 ---#> "vacuum",
    <#--- 469 ---#> "helmet",
    <#--- 470 ---#> "wheelchair",
    <#--- 471 ---#> "corkboard",
    <#--- 472 ---#> "bedside",
    <#--- 473 ---#> "laptop",
    <#--- 474 ---#> "bench",
    <#--- 475 ---#> "backligh",
    <#--- 476 ---#> "booth",
    <#--- 477 ---#> "stationchef",
    <#--- 478 ---#> "stationhost",
    <#--- 479 ---#> "stationwaiter",
    <#--- 480 ---#> "sectional",
    <#--- 481 ---#> "chaise",
    <#--- 482 ---#> "hairstrand",
    <#--- 483 ---#> "cdplayer",
    ####catchalls####
    <#--- 484 ---#> "ties",
    <#--- 485 ---#> "nude",
    <#--- 486 ---#> "skin",
    <#--- 487 ---#> "sweater",
    <#--- 488 ---#> "belt",
    <#--- 489 ---#> "brow",
    <#--- 490 ---#> "accessories",
    <#--- 491 ---#> "accessory",
    <#--- 492 ---#> "acc",
    <#--- 493 ---#> "top",
    <#--- 494 ---#> "tshirt",
    <#--- 495 ---#> "bottom",
    <#--- 496 ---#> "pants",
    <#--- 497 ---#> "shorts",
    <#--- 498 ---#> "short",
    <#--- 499 ---#> "overalls",
    <#--- 500 ---#> "fullbody",
    <#--- 501 ---#> "suit",
    <#--- 502 ---#> "outfit",
    <#--- 503 ---#> "dress",
    <#--- 504 ---#> "gown",
    <#--- 505 ---#> "shoes",
    <#--- 506 ---#> "boots",
    <#--- 507 ---#> "heels",
    <#--- 508 ---#> "hat",
    <#--- 509 ---#> "lamp",
    <#--- 510 ---#> "rug",
    <#--- 511 ---#> "wall",
    <#--- 512 ---#> "paper",
    <#--- 513 ---#> "paint",
    <#--- 514 ---#> "wings",
    <#--- 515 ---#> "hoops",
    <#--- 516 ---#> "tee",
    <#--- 517 ---#> "decor",
    <#--- 518 ---#> "glove",
    <#--- 519 ---#> "chair",
    <#--- 520 ---#> "table",
    <#--- 521 ---#> "speaker",
    <#--- 522 ---#> "stereo",
    <#--- 523 ---#> "fence",
    <#--- 524 ---#> "panties",
    <#--- 525 ---#> "twist",
    <#--- 526 ---#> "dread",
    <#--- 527 ---#> "counter",
    <#--- 528 ---#> "island",
    <#--- 529 ---#> "poses",
    <#--- 530 ---#> "pose",
    <#--- 531 ---#> "bathwater",
    <#--- 532 ---#> "bathroom",
    <#--- 533 ---#> "bath",
    <#--- 534 ---#> "bathbomb",
    <#--- 535 ---#> "towel",
    <#--- 536 ---#> "shower",
    <#--- 537 ---#> "sink",
    <#--- 538 ---#> "soap",
    <#--- 539 ---#> "toilet",
    <#--- 540 ---#> "toothpaste",
    <#--- 541 ---#> "cactus",
    <#--- 542 ---#> "wallart",
    <#--- 543 ---#> "vase",
    <#--- 544 ---#> "dining",
    <#--- 545 ---#> "sculpture",
    <#--- 546 ---#> "fruitbowl",
    <#--- 547 ---#> "floor",
    <#--- 548 ---#> "wall",
    <#--- 549 ---#> "standing",
    <#--- 550 ---#> "lamp",
    <#--- 551 ---#> "sofa",
    <#--- 552 ---#> "stool",
    <#--- 553 ---#> "pillow",
    <#--- 554 ---#> "arch",
    <#--- 555 ---#> "sconce",
    <#--- 556 ---#> "lounger",
    <#--- 557 ---#> "crate",
    <#--- 558 ---#> "picture",
    <#--- 559 ---#> "wardrobe",
    <#--- 560 ---#> "ashtray",
    <#--- 561 ---#> "book",
    <#--- 562 ---#> "clock",
    <#--- 563 ---#> "room",
    <#--- 564 ---#> "kitchen",
    <#--- 565 ---#> "wave",
    <#--- 566 ---#> "ring",
    <#--- 567 ---#> "bouquet",
    <#--- 568 ---#> "door",
    <#--- 569 ---#> "light",
    <#--- 570 ---#> "minibar",
    <#--- 571 ---#> "crib",
    <#--- 572 ---#> "pouf",
    <#--- 573 ---#> "blanket",
    <#--- 574 ---#> "cane",
    <#--- 575 ---#> "polo",
    <#--- 576 ---#> "robe",
    <#--- 577 ---#> "spots",
    <#--- 578 ---#> "desk",
    <#--- 579 ---#> "croc",
    <#--- 580 ---#> "deco",
    <#--- 581 ---#> "rug",
    <#--- 582 ---#> "bra",
    <#--- 583 ---#> "locs",
    <#--- 584 ---#> "fro",
    <#--- 585 ---#> "pony",
    <#--- 586 ---#> "bar",
    <#--- 587 ---#> "bag",
    <#--- 588 ---#> "bed",
    <#--- 589 ---#> "toy",
    <#--- 590 ---#> "eye",
    <#--- 591 ---#> "bun",
    <#--- 592 ---#> "lip",
    <#--- 593 ---#> "cap",
    <#--- 594 ---#> "zits",
    <#--- 595 ---#> "tent",
    <#--- 596 ---#> "rug",
    <#--- 597 ---#> "art",
    <#--- 598 ---#> "neon",
    <#--- 599 ---#> "TV",
    <#--- 600 ---#> "hair",
    <#--- 601 ---#> "default",
    <#--- 602 ---#> "fishtank",
    <#--- 603 ---#> "tank",
    <#--- 604 ---#> "septum",
    <#--- 605 ---#> "pig",
    <#--- 606 ---#> "curl",
    <#--- 607 ---#> "cami",
    <#--- 608 ---#> "bodywear",
    <#--- 609 ---#> "vintage")

$folderfortype = @(<#--- -1 ---#> "$messyGeneral\Accessories\Brooches",
    <#--- 0 ---#> "$periodManualSort",
    <#--- 1 ---#> "$period10s",
    <#--- 2 ---#> "$period10s",
    <#--- 3 ---#> "$period10s",
    <#--- 4 ---#> "$period10s",
    <#--- 5 ---#> "$period10s",
    <#--- 6 ---#> "$period10s",
    <#--- 7 ---#> "$period10s",
    <#--- 8 ---#> "$period10s",
    <#--- 9 ---#> "$period10s",
    <#--- 10 ---#> "$period10s",
    <#--- 11 ---#> "$period10s",
    <#--- 12 ---#> "$period10s",
    <#--- 13 ---#> "$period10s",
    <#--- 14 ---#> "$period10s",
    <#--- 15 ---#> "$period10s",
    <#--- 16 ---#> "$period10s",
    <#--- 17 ---#> "$period10s",
    <#--- 18 ---#> "$period10s",
    <#--- 19 ---#> "$period10s",
    <#--- 20 ---#> "$period10s",
    <#--- 21 ---#> "$period20s",
    <#--- 22 ---#> "$period20s",
    <#--- 23 ---#> "$period20s",
    <#--- 24 ---#> "$period20s",
    <#--- 25 ---#> "$period20s",
    <#--- 26 ---#> "$period20s",
    <#--- 27 ---#> "$period20s",
    <#--- 28 ---#> "$period20s",
    <#--- 29 ---#> "$period20s",
    <#--- 30 ---#> "$period20s",
    <#--- 31 ---#> "$period30s",
    <#--- 32 ---#> "$period30s",
    <#--- 33 ---#> "$period30s",
    <#--- 34 ---#> "$period30s",
    <#--- 35 ---#> "$period30s",
    <#--- 36 ---#> "$period30s",
    <#--- 37 ---#> "$period30s",
    <#--- 38 ---#> "$period30s",
    <#--- 39 ---#> "$period30s",
    <#--- 40 ---#> "$period30s",
    <#--- 41 ---#> "$period40s",
    <#--- 42 ---#> "$period40s",
    <#--- 43 ---#> "$period40s",
    <#--- 44 ---#> "$period40s",
    <#--- 45 ---#> "$period40s",
    <#--- 46 ---#> "$period40s",
    <#--- 47 ---#> "$period40s",
    <#--- 48 ---#> "$period40s",
    <#--- 49 ---#> "$period40s",
    <#--- 50 ---#> "$period40s",
    <#--- 51 ---#> "$period50s",
    <#--- 52 ---#> "$period50s",
    <#--- 53 ---#> "$period50s",
    <#--- 54 ---#> "$period50s",
    <#--- 55 ---#> "$period50s",
    <#--- 56 ---#> "$period50s",
    <#--- 57 ---#> "$period50s",
    <#--- 58 ---#> "$period50s",
    <#--- 59 ---#> "$period50s",
    <#--- 60 ---#> "$period50s",
    <#--- 61 ---#> "$period50s",
    <#--- 62 ---#> "$period60s",
    <#--- 63 ---#> "$period60s",
    <#--- 64 ---#> "$period60s",
    <#--- 65 ---#> "$period60s",
    <#--- 66 ---#> "$period60s",
    <#--- 67 ---#> "$period60s",
    <#--- 68 ---#> "$period60s",
    <#--- 69 ---#> "$period60s",
    <#--- 70 ---#> "$period60s",
    <#--- 71 ---#> "$period70s",
    <#--- 72 ---#> "$period70s",
    <#--- 73 ---#> "$period70s",
    <#--- 74 ---#> "$period70s",
    <#--- 75 ---#> "$period70s",
    <#--- 76 ---#> "$period70s",
    <#--- 77 ---#> "$period70s",
    <#--- 78 ---#> "$period70s",
    <#--- 79 ---#> "$period70s",
    <#--- 80 ---#> "$period70s",
    <#--- 81 ---#> "$period80s",
    <#--- 82 ---#> "$period80s",
    <#--- 83 ---#> "$period80s",
    <#--- 84 ---#> "$period80s",
    <#--- 85 ---#> "$period80s",
    <#--- 86 ---#> "$period80s",
    <#--- 87 ---#> "$period80s",
    <#--- 88 ---#> "$period80s",
    <#--- 89 ---#> "$period80s",
    <#--- 90 ---#> "$period80s",
    <#--- 91 ---#> "$period90s",
    <#--- 92 ---#> "$period90s",
    <#--- 93 ---#> "$period90s",
    <#--- 94 ---#> "$period90s",
    <#--- 95 ---#> "$period90s",
    <#--- 96 ---#> "$period90s",
    <#--- 97 ---#> "$period90s",
    <#--- 98 ---#> "$period90s",
    <#--- 99 ---#> "$period90s",
    <#--- 100 ---#> "$period90s",
    <#--- 101 ---#> "$periodRococo",
    <#--- 102 ---#> "$periodVictorian",
    <#--- 103 ---#> "$periodRenaissance",
    <#--- 104 ---#> "$perioddystopia",
    <#--- 105 ---#> "$periodMedieval",
    <#--- 106 ---#> "$periodMedieval",
    <#--- 107 ---#> "$periodcyberpunk",
    <#--- 108 ---#> "$periodSteam",
    <#--- 109 ---#> "$periodColonial",
    <#--- 110 ---#> "$periodBaroque",
    <#--- 111 ---#> "$periodTudors",
    <#--- 112 ---#> "$periodManualSort",
    <#--- 113 ---#> "$periodManualSort",
    <#--- 114 ---#> "$periodManualSort",
    <#--- 115 ---#> "$periodManualSort",
    <#--- 116 ---#> "$periodManualSort",
    <#--- 117 ---#> "$periodManualSort",
    <#--- 118 ---#> "$periodManualSort",
    <#--- 119 ---#> "$periodManualSort",
    <#--- 120 ---#> "$periodManualSort",
    <#--- 121 ---#> "$periodManualSort",
    <#--- 122 ---#> "$messyGeneral\Buy\Off The Grid",
    <#--- 123 ---#> "$messyGeneral\Poses",
    <#--- 124 ---#> "$messyGeneral\SkinDetails\NoseMasks",
    <#--- 125 ---#> "$messyModern\Build",
    <#--- 126 ---#> "$messyModern\Build",
    <#--- 127 ---#> "$messyGeneral\SkinDetails\Vitiligo",
    <#--- 128 ---#> "$manualSort",
    <#--- 129 ---#> "$manualSort",
    <#--- 130 ---#> "$messyGeneral\HairRecolors\_Puppycrow",
    <#--- 131 ---#> "$messyGeneral\HairRecolors\_Puppycrow",
    <#--- 132 ---#> "$messyGeneral\HairRecolors\_Sorbets",
    <#--- 133 ---#> "$messyGeneral\HairRecolors\_Sorbets",
    <#--- 134 ---#> "$messyGeneral\HairRecolors\_Sorbets",
    <#--- 135 ---#> "$messyGeneral\HairRecolors\_Sorbets",
    <#--- 136 ---#> "$manualSort",
    <#--- 137 ---#> "$periodManualSort", 
    <#--- 139 ---#> "$periodManualSort",
    <#--- 140 ---#> "$messyModern\Buy",
    <#--- 141 ---#> "$messyGeneral\Occult",
    <#--- 142 ---#> "$messyModern\Accessories\Underwear",
    <#--- 143 ---#> "$messyModern\Accessories\Underwear",
    <#--- 144 ---#> "$messyModern\Accessories\Underwear",
    <#--- 145 ---#> "$messyModern\Accessories\Underwear",
    <#--- 146 ---#> "$messyModern\Accessories\Underwear",
    <#--- 147 ---#> "$messyModern\Accessories\Underwear",
    <#--- 148 ---#> "$manualSort",
    <#--- 149 ---#> "$manualSort",
    <#--- 150 ---#> "$manualSort",
    <#--- 151 ---#> "$manualSort",
    <#--- 152 ---#> "$manualSort",
    <#--- 153 ---#> "$messyModern\Accessories\JewelryMisc",
    <#--- 154 ---#> "$messyGeneral\Necrodog",
    <#--- 155 ---#> "$messyModern\Uniform",
    <#--- 156 ---#> "$manualSort\Presets",
    <#--- 157 ---#> "$manualSort\Sliders",
    <#--- 158 ---#> "$messyModern\Accessories\Necklace",
    <#--- 159 ---#> "$messyModern\Accessories\Glasses",
    <#--- 160 ---#> "$messyModern\Accessories\Socks",
    <#--- 161 ---#> "$messyModern\Accessories\Socks",
    <#--- 162 ---#> "$messyModern\Accessories\Socks",
    <#--- 163 ---#> "$messyModern\Accessories\Veils",
    <#--- 164 ---#> "$messyModern\Clothing",
    <#--- 165 ---#> "$messyModern\Accessories\Scarves",
    <#--- 166 ---#> "$messyModern\Accessories\Hats",
    <#--- 167 ---#> "$messyModern\Accessories\Hats",
    <#--- 168 ---#> "$messyModern\Accessories\Hats",
    <#--- 169 ---#> "$messyModern\Accessories\Hats",
    <#--- 170 ---#> "$messyModern\Accessories\Hats",
    <#--- 171 ---#> "$messyModern\Accessories\Earrings",
    <#--- 172 ---#> "$messyModern\Accessories\Earrings",
    <#--- 173 ---#> "$messyGeneral\Accessories\ColorOverlays",
    <#--- 174 ---#> "$messyGeneral\Accessories\Eyelashes",
    <#--- 175 ---#> "$messyGeneral\Accessories\Eyelashes",
    <#--- 176 ---#> "$messyGeneral\Hair",
    <#--- 177 ---#> "$messyModern\Accessories\JewelryMisc",
    <#--- 178 ---#> "$messyModern\Clothing",
    <#--- 179 ---#> "$messyGeneral\Makeup",
    <#--- 180 ---#> "$messyGeneral\Makeup",
    <#--- 181 ---#> "$messyGeneral\Makeup",
    <#--- 182 ---#> "$messyGeneral\FacialHair\Beards",
    <#--- 183 ---#> "$messyGeneral\FacialHair\Beards",
    <#--- 184 ---#> "$messyGeneral\FacialHair\Mustaches",
    <#--- 185 ---#> "$messyGeneral\FacialHair\Sideburns",
    <#--- 186 ---#> "$messyGeneral\Accessories\HairAccessories",
    <#--- 187 ---#> "$messyModern\Clothing",
    <#--- 188 ---#> "$messyModern\Clothing",
    <#--- 189 ---#> "$messyModern\Clothing",
    <#--- 190 ---#> "$messyModern\Clothing",
    <#--- 191 ---#> "$messyModern\Clothing",
    <#--- 192 ---#> "$messyModern\Clothing",
    <#--- 193 ---#> "$messyGeneral\Hair",
    <#--- 194 ---#> "$messyModern\Clothing",
    <#--- 195 ---#> "$messyModern\Clothing",
    <#--- 196 ---#> "$messyModern\Clothing",
    <#--- 197 ---#> "$messyModern\Clothing",
    <#--- 198 ---#> "$messyModern\Clothing",
    <#--- 199 ---#> "$messyModern\Accessories\Hijabs",
    <#--- 200 ---#> "$messyGeneral\Accessories\ColorOverlays",
    <#--- 201 ---#> "$messyGeneral\SkinDetails",
    <#--- 202 ---#> "$messyGeneral\SkinBlends",
    <#--- 203 ---#> "$messyGeneral\SkinDetails",
    <#--- 204 ---#> "$messyModern\Accessories\Nails",
    <#--- 205 ---#> "$messyGeneral\Accessories\HairAccessories",
    <#--- 206 ---#> "$messyGeneral\Accessories\HairAccessories",
    <#--- 207 ---#> "$messyGeneral\Accessories\HairAccessories",
    <#--- 208 ---#> "$messyGeneral\Accessories\HairAccessories",
    <#--- 209 ---#> "$messyModern\Accessories\Misc",
    <#--- 210 ---#> "$messyModern\Buy",
    <#--- 211 ---#> "$messyModern\Buy",
    <#--- 212 ---#> "$messyModern\Buy",
    <#--- 213 ---#> "$messyModern\Buy",
    <#--- 214 ---#> "$messyModern\Buy",
    <#--- 215 ---#> "$messyGeneral\Accessories\ColorOverlays",
    <#--- 216 ---#> "$messyGeneral\Accessories\HairAccessories",
    <#--- 217 ---#> "$messyModern\Buy",
    <#--- 218 ---#> "$messyModern\Buy",
    <#--- 219 ---#> "$messyModern\Accessories\Jackets",
    <#--- 220 ---#> "$messyModern\Buy",
    <#--- 221 ---#> "$messyGeneral\Accessories\Masks",
    <#--- 222 ---#> "$messyModern\Accessories\Underwear",
    <#--- 223 ---#> "$messyModern\Clothing",
    <#--- 224 ---#> "$messyModern\Buy",
    <#--- 225 ---#> "$messyModern\Buy",
    <#--- 226 ---#> "$messyModern\Buy",
    <#--- 227 ---#> "$messyModern\Buy",
    <#--- 228 ---#> "$messyModern\Accessories\Necklaces",
    <#--- 229 ---#> "$messyModern\Buy",
    <#--- 230 ---#> "$messyGeneral\Makeup",
    <#--- 231 ---#> "$messyGeneral\Tattoos",
    <#--- 232 ---#> "$messyModern\Accessories\JewelryMisc",
    <#--- 233 ---#> "$messyModern\Accessories\JewelryMisc",
    <#--- 234 ---#> "$messyModern\Holidays\Christmas",
    <#--- 235 ---#> "$messyGeneral\Accessories\Crowns",
    <#--- 236 ---#> "$messyGeneral\Accessories\Crowns",
    <#--- 237 ---#> "$messyModern\Accessories\Necklaces",
    <#--- 238 ---#> "$messyModern\Holidays\Christmas",
    <#--- 239 ---#> "$messyModern\Holidays\Christmas",
    <#--- 240 ---#> "$messyModern\Holidays\Christmas",
    <#--- 241 ---#> "$messyModern\Buy",
    <#--- 242 ---#> "$messyModern\Buy",
    <#--- 243 ---#> "$messyModern\Buy",
    <#--- 244 ---#> "$messyModern\Buy",
    <#--- 245 ---#> "$messyModern\Buy",
    <#--- 246 ---#> "$messyModern\Buy",
    <#--- 247 ---#> "$messyModern\Buy",
    <#--- 248 ---#> "$messyModern\Buy",
    <#--- 249 ---#> "$messyModern\Buy",
    <#--- 250 ---#> "$messyModern\Build",
    <#--- 251 ---#> "$messyModern\Accessories\JewelryMisc",
    <#--- 252 ---#> "$messyModern\Buy",
    <#--- 253 ---#> "$messyGeneral\Accessories\ColorOverlays",
    <#--- 254 ---#> "$messyModern\Accessories\Hats",
    <#--- 255 ---#> "$messyModern\Clothing",
    <#--- 256 ---#> "$messyModern\Build",
    <#--- 257 ---#> "$messyModern\Build",
    <#--- 258 ---#> "$messyModern\Buy",
    <#--- 259 ---#> "$messyModern\Buy",
    <#--- 260 ---#> "$messyModern\Build",
    <#--- 261 ---#> "$messyModern\Buy",
    <#--- 262 ---#> "$messyModern\Buy",
    <#--- 263 ---#> "$messyModern\Buy",
    <#--- 264 ---#> "$messyModern\Clothing",
    <#--- 265 ---#> "$messyModern\Clothing",
    <#--- 266 ---#> "$messyModern\Accessories\Rings",
    <#--- 267 ---#> "$messyModern\Accessories\Rings",
    <#--- 268 ---#> "$messyModern\Buy",
    <#--- 269 ---#> "$manualSort",
    <#--- 270 ---#> "$messyModern\Clothing",
    <#--- 271 ---#> "$messyModern\Clothing",
    <#--- 272 ---#> "$messyModern\Accessories\JewelryMisc",
    <#--- 273 ---#> "$messyModern\Accessories\Jackets",
    <#--- 274 ---#> "$messyModern\Accessories\Jackets",
    <#--- 275 ---#> "$messyModern\Accessories\Jackets",
    <#--- 276 ---#> "$messyModern\Accessories\Underwear",
    <#--- 277 ---#> "$manualSort",
    <#--- 278 ---#> "$messyModern\Shoes",
    <#--- 279 ---#> "$messyModern\Clothing",
    <#--- 280 ---#> "$messyModern\Clothing",
    <#--- 281 ---#> "$messyModern\Clothing",
    <#--- 282 ---#> "$messyModern\Accessories\Misc",
    <#--- 283 ---#> "$messyModern\Clothing",
    <#--- 284 ---#> "$manualSort",
    <#--- 285 ---#> "$messyModern\Buy",
    <#--- 286 ---#> "$messyModern\Buy",
    <#--- 287 ---#> "$messyModern\Buy",
    <#--- 288 ---#> "$messyModern\Buy",
    <#--- 289 ---#> "$messyModern\Buy",
    <#--- 290 ---#> "$messyModern\Buy",
    <#--- 291 ---#> "$messyModern\Shoes",
    <#--- 292 ---#> "$messyModern\Accessories\Misc",
    <#--- 293 ---#> "$messyModern\Clothing",
    <#--- 294 ---#> "$messyModern\Accessories\Jackets",
    <#--- 295 ---#> "$messyModern\Accessories\Jackets",
    <#--- 296 ---#> "$messyModern\Clothing",
    <#--- 297 ---#> "$messyModern\Accessories\Jackets",
    <#--- 298 ---#> "$messyModern\Accessories\Jackets",
    <#--- 299 ---#> "$messyModern\Clothing",
    <#--- 300 ---#> "$messyGeneral\Hair",
    <#--- 301 ---#> "$messyGeneral\Accessories\HairAccessories",
    <#--- 302 ---#> "$messyGeneral\Accessories\HairAccessories",
    <#--- 303 ---#> "$messyGeneral\Hair",
    <#--- 304 ---#> "$manualSort\Overrides",
    <#--- 305 ---#> "$messyModern\Build",
    <#--- 306 ---#> "$messyModern\Buy",
    <#--- 307 ---#> "$messyModern\Buy",
    <#--- 308 ---#> "$messyModern\Buy",
    <#--- 309 ---#> "$messyModern\Buy",
    <#--- 310 ---#> "$messyModern\Buy",
    <#--- 311 ---#> "$messyModern\Build",
    <#--- 312 ---#> "$messyModern\Clothing",
    <#--- 313 ---#> "$messyGeneral\Hair",
    <#--- 314 ---#> "$messyGeneral\Hair",
    <#--- 315 ---#> "$messyGeneral\Hair",
    <#--- 316 ---#> "$messyModern\Accessories\Underwear",
    <#--- 317 ---#> "$messyModern\Accessories\Underwear",
    <#--- 318 ---#> "$messyModern\Accessories\Underwear",
    <#--- 319 ---#> "$messyModern\Accessories\Underwear",
    <#--- 320 ---#> "$messyModern\Clothing",
    <#--- 321 ---#> "$messyModern\Accessories\Misc",
    <#--- 322 ---#> "$messyModern\Clothing",
    <#--- 323 ---#> "$messyModern\Clothing",
    <#--- 324 ---#> "$messyModern\Clothing",
    <#--- 325 ---#> "$messyModern\Accessories\Wrist",
    <#--- 326 ---#> "$messyModern\Clothing",
    <#--- 327 ---#> "$messyModern\Accessories\Socks",
    <#--- 328 ---#> "$messyModern\Clothing",
    <#--- 329 ---#> "$messyModern\Accessories\Wrist",
    <#--- 330 ---#> "$messyModern\Clothing",
    <#--- 331 ---#> "$messyModern\Clothing",
    <#--- 332 ---#> "$messyModern\Clothing",
    <#--- 333 ---#> "$messyModern\Clothing",
    <#--- 334 ---#> "$messyModern\Accessories\Hats",
    <#--- 335 ---#> "$messyModern\Clothing",
    <#--- 336 ---#> "$messyModern\Clothing",
    <#--- 337 ---#> "$messyModern\Clothing",
    <#--- 338 ---#> "$messyModern\Clothing",
    <#--- 339 ---#> "$messyModern\Clothing",
    <#--- 340 ---#> "$messyModern\Clothing",
    <#--- 341 ---#> "$messyGeneral\Hair",
    <#--- 342 ---#> "$messyGeneral\Hair",
    <#--- 343 ---#> "$messyGeneral\Hair",
    <#--- 344 ---#> "$messyModern\Accessories\Hairlines",
    <#--- 345 ---#> "$messyGeneral\Hair",
    <#--- 346 ---#> "$messyGeneral\Hair",
    <#--- 347 ---#> "$manualSort",
    <#--- 348 ---#> "$manualSort",
    <#--- 349 ---#> "$messyModern\Clothing",
    <#--- 350 ---#> "$messyModern\Clothing",
    <#--- 351 ---#> "$messyModern\Clothing",
    <#--- 352 ---#> "$messyModern\Clothing",
    <#--- 353 ---#> "$messyModern\Clothing",
    <#--- 354 ---#> "$messyModern\Clothing",
    <#--- 355 ---#> "$messyModern\Build",
    <#--- 356 ---#> "$messyGeneral\Hair",
    <#--- 357 ---#> "$messyModern\Buy",
    <#--- 358 ---#> "$manualSort",
    <#--- 359 ---#> "$manualSort",
    <#--- 360 ---#> "$messyModern\Clothing",
    <#--- 361 ---#> "$messyModern\Buy",
    <#--- 362 ---#> "$messyModern\Buy",
    <#--- 363 ---#> "$messyModern\Buy",
    <#--- 364 ---#> "$messyModern\Buy",
    <#--- 365 ---#> "$messyModern\Buy",
    <#--- 366 ---#> "$messyModern\Buy",
    <#--- 367 ---#> "$messyModern\Buy",
    <#--- 368 ---#> "$messyModern\Buy",
    <#--- 369 ---#> "$messyModern\Buy",
    <#--- 370 ---#> "$messyModern\Buy",
    <#--- 371 ---#> "$manualSort",
    <#--- 372 ---#> "$messyGeneral\Skins",
    <#--- 373 ---#> "$messyModern\Buy",
    <#--- 374 ---#> "$messyGeneral\Hair",
    <#--- 375 ---#> "$messyModern\Clothing",
    <#--- 376 ---#> "$messyModern\Buy",
    <#--- 377 ---#> "$messyGeneral\Accessories\ColorOverlays",
    <#--- 378 ---#> "$messyGeneral\Accessories\ColorOverlays",
    <#--- 379 ---#> "$messyGeneral\Accessories\Hairlines",
    <#--- 380 ---#> "$messyGeneral\Facepaint",
    <#--- 381 ---#> "$manualSort\Overrides",
    <#--- 382 ---#> "$messyModern\Buy",
    <#--- 383 ---#> "$messyModern\Buy",
    <#--- 384 ---#> "$messyModern\Buy",
    <#--- 385 ---#> "$messyModern\Buy",
    <#--- 386 ---#> "$messyGeneral\FacialHair",
    <#--- 387 ---#> "$messyGeneral\Makeup\Eyeliner",
    <#--- 388 ---#> "$messyGeneral\FacialHair\Beards",
    <#--- 389 ---#> "$messyGeneral\FacialHair\Beards",
    <#--- 390 ---#> "$messyModern\Buy",
    <#--- 391 ---#> "$messyModern\Buy",
    <#--- 392 ---#> "$messyModern\Buy",
    <#--- 393 ---#> "$messyModern\Buy",
    <#--- 394 ---#> "$messyModern\Buy",
    <#--- 395 ---#> "$messyModern\Buy",
    <#--- 396 ---#> "$messyModern\Vehicles",
    <#--- 397 ---#> "$messyModern\Vehicles",
    <#--- 398 ---#> "$messyModern\Buy",
    <#--- 399 ---#> "$messyModern\Buy",
    <#--- 400 ---#> "$messyModern\Buy",
    <#--- 401 ---#> "$messyModern\Buy",
    <#--- 402 ---#> "$messyModern\Buy",
    <#--- 403 ---#> "$messyModern\Buy",
    <#--- 404 ---#> "$messyModern\Buy",
    <#--- 405 ---#> "$messyGeneral\FacialHair\Beards",
    <#--- 406 ---#> "$periodManualSort",
    <#--- 407 ---#> "$periodManualSort",
    <#--- 408 ---#> "$periodManualSort",
    <#--- 409 ---#> "$messyGeneral\Accessories\HairAccessories",
    <#--- 410 ---#> "$messyGeneral\Accessories\HairAccessories",
    <#--- 411 ---#> "$periodManualSort",
    <#--- 412 ---#> "$messyModern\Buy",
    <#--- 413 ---#> "$messyModern\Buy",
    <#--- 414 ---#> "$messyModern\Accessories\Misc",
    <#--- 415 ---#> "$messyModern\Buy",
    <#--- 416 ---#> "$messyModern\Buy",
    <#--- 417 ---#> "$messyModern\Buy",
    <#--- 418 ---#> "$messyModern\Buy",
    <#--- 419 ---#> "$messyModern\Buy",
    <#--- 420 ---#> "$messyModern\Buy",
    <#--- 421 ---#> "$messyModern\Buy",
    <#--- 422 ---#> "$messyModern\Buy",
    <#--- 423 ---#> "$messyModern\Buy",
    <#--- 424 ---#> "$messyModern\Buy\Buildings",
    <#--- 425 ---#> "$messyModern\Buy",
    <#--- 426 ---#> "$messyModern\Buy",
    <#--- 427 ---#> "$messyGeneral\Misc",
    <#--- 428 ---#> "$manualSort",
    <#--- 429 ---#> "$messyModern\Buy",
    <#--- 430 ---#> "$messyModern\Buy",
    <#--- 431 ---#> "$messyModern\Buy",
    <#--- 432 ---#> "$manualSort\Peacemaker",
    <#--- 433 ---#> "$messyGeneral\Makeup",
    <#--- 434 ---#> "$messyGeneral\SkinDetails",
    <#--- 435 ---#> "$messyGeneral\SkinDetails",
    <#--- 436 ---#> "$messyGeneral\SkinDetails",
    <#--- 437 ---#> "$messyGeneral\SkinDetails",
    <#--- 438 ---#> "$messyGeneral\SkinDetails",
    <#--- 439 ---#> "$messyGeneral\SkinDetails",
    <#--- 440 ---#> "$messyModern\Buy",
    <#--- 441 ---#> "$messyGeneral\SkinDetails",
    <#--- 442 ---#> "$messyGeneral\SkinDetails",
    <#--- 443 ---#> "$messyModern\Buy",
    <#--- 444 ---#> "$manualSort",
    <#--- 445 ---#> "$manualSort",
    <#--- 446 ---#> "$messyModern\Buy",
    <#--- 447 ---#> "$messyGeneral\Makeup",
    <#--- 448 ---#> "$messyGeneral\Makeup",
    <#--- 449 ---#> "$messyModern\Buy",
    <#--- 450 ---#> "$messyModern\Clothing",
    <#--- 451 ---#> "$messyModern\Clothing",
    <#--- 452 ---#> "$messyGeneral\BodyHair",
    <#--- 453 ---#> "$messyGeneral\SkinDetails",
    <#--- 454 ---#> "$messyModern\Accessories\Necklaces",
    <#--- 455 ---#> "$messyModern\Accessories\Underwear",
    <#--- 456 ---#> "$messyModern\Shoes",
    <#--- 457 ---#> "$messyModern\Accessories\Misc",
    <#--- 458 ---#> "$messyModern\Clothing",
    <#--- 459 ---#> "$messyModern\Accessories\Misc",
    <#--- 460 ---#> "$messyModern\Accessories\Bags",
    <#--- 461 ---#> "$messyGeneral\SkinDetails",
    <#--- 462 ---#> "$messyGeneral\SkinDetails",
    <#--- 463 ---#> "$messyGeneral\SkinDetails",
    <#--- 464 ---#> "$messyGeneral\SkinDetails",
    <#--- 465 ---#> "$messyGeneral\Accessories\ContactLenses",
    <#--- 466 ---#> "$messyGeneral\SkinDetails",
    <#--- 467 ---#> "$messyGeneral\SkinDetails",
    <#--- 468 ---#> "$messyModern\Buy",
    <#--- 469 ---#> "$messyModern\Accessories\Hats",
    <#--- 470 ---#> "$messyModern\Disabilities",
    <#--- 471 ---#> "$messyModern\Buy",
    <#--- 472 ---#> "$messyModern\Buy",
    <#--- 473 ---#> "$messyModern\Buy",
    <#--- 474 ---#> "$messyModern\Buy",
    <#--- 475 ---#> "$messyModern\Buy",
    <#--- 476 ---#> "$messyModern\Buy",
    <#--- 477 ---#> "$messyModern\Buy",
    <#--- 478 ---#> "$messyModern\Buy",
    <#--- 479 ---#> "$messyModern\Buy",
    <#--- 480 ---#> "$messyModern\Buy",
    <#--- 481 ---#> "$messyModern\Buy",
    <#--- 482 ---#> "$messyGeneral\Accessories\ColorOverlays",
    <#--- 483 ---#> "$messyModern\Buy",
    ####catchalls####
    <#--- 484 ---#> "$messyModern\Accessories\HairAccessories",
    <#--- 485 ---#> "$manualSort\Adult",
    <#--- 486 ---#> "$messyGeneral\Skins",
    <#--- 487 ---#> "$messyModern\Clothing",
    <#--- 488 ---#> "$messyModern\Accessories\Belts",
    <#--- 489 ---#> "$messyGeneral\FacialHair\Eyebrows",
    <#--- 490 ---#> "$messyModern\Accessories",
    <#--- 491 ---#> "$messyModern\Accessories",
    <#--- 492 ---#> "$messyModern\Accessories",
    <#--- 493 ---#> "$messyModern\Clothing",
    <#--- 494 ---#> "$messyModern\Clothing",
    <#--- 495 ---#> "$messyModern\Clothing",
    <#--- 496 ---#> "$messyModern\Clothing",
    <#--- 497 ---#> "$messyModern\Clothing",
    <#--- 498 ---#> "$messyModern\Clothing",
    <#--- 499 ---#> "$messyModern\Clothing",
    <#--- 500 ---#> "$messyModern\Clothing",
    <#--- 501 ---#> "$messyModern\Clothing",
    <#--- 502 ---#> "$messyModern\Clothing",
    <#--- 503 ---#> "$messyModern\Clothing",
    <#--- 504 ---#> "$messyModern\Clothing",
    <#--- 505 ---#> "$messyModern\Shoes",
    <#--- 506 ---#> "$messyModern\Shoes",
    <#--- 507 ---#> "$messyModern\Shoes",
    <#--- 508 ---#> "$messyModern\Accessories\Hats",
    <#--- 509 ---#> "$messyModern\Buy",
    <#--- 510 ---#> "$messyModern\Buy",
    <#--- 511 ---#> "$messyModern\Build",
    <#--- 512 ---#> "$messyModern\Build",
    <#--- 513 ---#> "$messyModern\Build",
    <#--- 514 ---#> "$manualSort",
    <#--- 515 ---#> "$messyModern\Accessories\Earrings",
    <#--- 516 ---#> "$messyModern\Clothing",
    <#--- 517 ---#> "$messyModern\Buy",
    <#--- 518 ---#> "$messyModern\Accessories\Gloves",
    <#--- 519 ---#> "$messyModern\Buy",
    <#--- 520 ---#> "$messyModern\Buy",
    <#--- 521 ---#> "$messyModern\Buy",
    <#--- 522 ---#> "$messyModern\Buy",
    <#--- 523 ---#> "$messyModern\Build",
    <#--- 524 ---#> "$messyModern\Clothing",
    <#--- 525 ---#> "$messyGeneral\Hair",
    <#--- 526 ---#> "$messyGeneral\Hair",
    <#--- 527 ---#> "$messyModern\Buy",
    <#--- 528 ---#> "$messyModern\Buy",
    <#--- 529 ---#> "$messyGeneral\Poses",
    <#--- 530 ---#> "$messyGeneral\Poses",
    <#--- 531 ---#> "$messyGeneral\SpecialEffects",
    <#--- 532 ---#> "$messyModern\Buy",
    <#--- 533 ---#> "$messyModern\Buy",
    <#--- 534 ---#> "$messyModern\Buy",
    <#--- 535 ---#> "$messyModern\Buy",
    <#--- 536 ---#> "$messyModern\Buy",
    <#--- 537 ---#> "$messyModern\Buy",
    <#--- 538 ---#> "$messyModern\Buy",
    <#--- 539 ---#> "$messyModern\Buy",
    <#--- 540 ---#> "$messyModern\Buy",
    <#--- 541 ---#> "$messyModern\Buy",
    <#--- 542 ---#> "$messyModern\Buy",
    <#--- 543 ---#> "$messyModern\Buy",
    <#--- 544 ---#> "$messyModern\Buy",
    <#--- 545 ---#> "$messyModern\Buy",
    <#--- 546 ---#> "$messyModern\Buy",
    <#--- 547 ---#> "$messyModern\Build",
    <#--- 548 ---#> "$messyModern\Build",
    <#--- 549 ---#> "$messyModern\Buy",
    <#--- 550 ---#> "$messyModern\Buy",
    <#--- 551 ---#> "$messyModern\Buy",
    <#--- 552 ---#> "$messyModern\Buy",
    <#--- 553 ---#> "$messyModern\Buy",
    <#--- 554 ---#> "$messyModern\Build",
    <#--- 555 ---#> "$messyModern\Buy",
    <#--- 556 ---#> "$messyModern\Buy",
    <#--- 557 ---#> "$messyModern\Buy",
    <#--- 558 ---#> "$messyModern\Buy",
    <#--- 559 ---#> "$messyModern\Buy",
    <#--- 560 ---#> "$messyModern\Buy",
    <#--- 561 ---#> "$messyModern\Buy",
    <#--- 562 ---#> "$messyModern\Buy",
    <#--- 563 ---#> "$messyModern\Buy",
    <#--- 564 ---#> "$messyModern\Buy",
    <#--- 565 ---#> "$messyGeneral\Hair",
    <#--- 566 ---#> "$messyModern\Accessories\Rings",
    <#--- 567 ---#> "$manualSort",
    <#--- 568 ---#> "$messyModern\Build",
    <#--- 569 ---#> "$messyModern\Buy",
    <#--- 570 ---#> "$messyModern\Buy",
    <#--- 571 ---#> "$messyModern\Buy",
    <#--- 572 ---#> "$messyModern\Buy",
    <#--- 573 ---#> "$messyModern\Buy",
    <#--- 574 ---#> "$messyGeneral\Disabilities",
    <#--- 575 ---#> "$messyModern\Clothing",
    <#--- 576 ---#> "$messyModern\Clothing",
    <#--- 577 ---#> "$manualSort",
    <#--- 578 ---#> "$messyModern\Buy",
    <#--- 579 ---#> "$messyModern\Shoes",
    <#--- 580 ---#> "$messyModern\Buy",
    <#--- 581 ---#> "$messyModern\Buy",
    <#--- 582 ---#> "$messyModern\Clothing",
    <#--- 583 ---#> "$messyGeneral\Hair",
    <#--- 584 ---#> "$messyGeneral\Hair",
    <#--- 585 ---#> "$messyGeneral\Hair",
    <#--- 586 ---#> "$messyModern\Buy",
    <#--- 587 ---#> "$manualSort",
    <#--- 588 ---#> "$messyModern\Buy",
    <#--- 589 ---#> "$messyModern\Buy",
    <#--- 590 ---#> "$messyGeneral\Eyes",
    <#--- 591 ---#> "$messyGeneral\Hair",
    <#--- 592 ---#> "$messyGeneral\Makeup",
    <#--- 593 ---#> "$messyModern\Accessories\Hats",
    <#--- 594 ---#> "$messyGeneral\SkinDetails",
    <#--- 595 ---#> "$messyModern\Buy",
    <#--- 596 ---#> "$messyModern\Buy",
    <#--- 597 ---#> "$messyModern\Buy",
    <#--- 598 ---#> "$messyModern\Buy",
    <#--- 599 ---#> "$messyModern\Buy",
    <#--- 600 ---#> "$messyGeneral\Hair"
    <#--- 601 ---#> "$manualSort\Overrides"
    <#--- 602 ---#> "$messyModern\Buy",
    <#--- 603 ---#> "$messyModern\Clothing",
    <#--- 604 ---#> "$messyModern\Accessories\JewelryMisc",
    <#--- 605 ---#> "$messyGeneral\Hair",
    <#--- 606 ---#> "$messyGeneral\Hair",
    <#--- 607 ---#> "$messyModern\Clothing",
    <#--- 607 ---#> "$messyModern\Clothing",
    <#--- 607 ---#> "$periodManualSort")

$periodAll = "$messyfolder\Manual Sort - Historical\00_All"
$periodAncient = "$messyfolder\Manual Sort - Historical\01_Ancient"
$periodEarlyCiv = "$messyfolder\Manual Sort - Historical\02_EarlyCiv"
$periodMedieval = "$messyfolder\Manual Sort - Historical\03_Medieval (476CE)"
$periodRenaissance = "$messyfolder\Manual Sort - Historical\04_Renaissance (1300)"
$periodTudors = "$messyfolder\Manual Sort - Historical\05_Tudors (1485)"
$periodColonial = "$messyfolder\Manual Sort - Historical\06_Colonial (1620)"
$periodBaroque = "$messyfolder\Manual Sort - Historical\07_Baroque (1700)"
$periodIndustrial = "$messyfolder\Manual Sort - Historical\08_IndustrialAge (1760)"
$periodRococo = "$messyfolder\Manual Sort - Historical\09_Rococo (1730)"
$periodOldWest = "$messyfolder\Manual Sort - Historical\10_OldWest (1865)"
$periodVictorian = "$messyfolder\Manual Sort - Historical\11a_Victorian (1890)"
$periodSteam = "$messyfolder\Manual Sort - Historical\11b_Steampunk"
$period10s = "$messyfolder\Manual Sort - Historical\12_1910s"
$period20s = "$messyfolder\Manual Sort - Historical\13_1920s"
$period30s = "$messyfolder\Manual Sort - Historical\14_1930s"
$period40s = "$messyfolder\Manual Sort - Historical\15_1940s"
$period50s = "$messyfolder\Manual Sort - Historical\16_1950s"
$period60s = "$messyfolder\Manual Sort - Historical\17_1960s"
$period70s = "$messyfolder\Manual Sort - Historical\18_1970s"
$period80s = "$messyfolder\Manual Sort - Historical\19_1980s"
$period90s = "$messyfolder\Manual Sort - Historical\20_1990s"
$period2000s = "$messyfolder\Manual Sort - Historical\21_2000s"
$period2010s = "$messyfolder\Manual Sort - Historical\22_2010s"
$periodfantasy = "$messyfolder\Manual Sort - Historical\00a_Fantasy"
$periodscifi = "$messyfolder\Manual Sort - Historical\00b_SciFi"
$periodfuturistic = "$messyfolder\Manual Sort - Historical\00c_Futuristic"
$periodgrunge = "$messyfolder\Manual Sort - Historical\00d_Grunge"
$perioddystopia = "$messyfolder\Manual Sort - Historical\00f_DystopianApocalypse"
$periodcyberpunk = "$messyfolder\Manual Sort - Historical\00g_Cyberpunk"
$periodManualSort = "$messyfolder\Manual Sort - Historical"
$manualSort = "$messyfolder\Manual Sort"

$messyfolder = "M:\The Sims 4 (Documents)\!UnmergedCC\NEWCC2022"

######VARS############

#$creatorsList = @("Apple", "Orange") <- this works, for some ungodly reason. the main one doesn't. help. 

Initialize-AutoSorting -messyfolder $messyfolder -creatorsList $creatorsList -typeOfCC $typesList -folderForType $folderForType -cleanFileNames $false 

Out-Script
