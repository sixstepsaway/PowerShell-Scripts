
Function Out-Script {
    Write-Host "Finishing up."
    $endingVars = Get-Variable
    Remove-Variable $endingVars -Exclude $startingVars
    Exit
}

Function Initialize-TidyCharacters ($folderToSort) {
    $matchlist = @(" "
    "["
    "]"
    "(" 
    ")"
    "{"
    "}" 
    "@" 
    "&"
    "%"
    "$"
    "="
    "+"
    "#"
    "'"
    "_"
    "-"
    " "
    ","
    "."
    "'"
    "❤"
    "`“") 
    $replacelist = @(<#---0---#> "") 
    
    <#for ($i=0; $matchlist.Count -gt $i; $i++) {
        $filestoClean = Get-ChildItem -File "$folderToSort\*.package" -Depth 0
        $numberOfFiles = $filestoClean.Length
        $Completed = ($i/$NumberOfFiles) * 100
        Write-Progress -Id 0 -Activity "Cleaning file names" -Status "Progress: " -PercentComplete $Completed        
        Get-ChildItem -File "$folderToSort\*.package" -Depth 0 |
        Where-Object { $_.baseName.Contains($matchlist[$i]) } |
        Rename-Item -NewName { ($_.baseName -replace [regex]::Escape($matchlist[$i]),$replacelist[$i]) + $_.Extension } -PassThru | Out-Null
    }#>
    $filestoClean = Get-ChildItem -File "$folderToSort\*.package" -Depth 0
    $numberOfFiles = $filestoClean.Count
    for ($i=0; $matchlist.Count -gt $i; $i++) {        
        $Completed = ($i/$NumberOfFiles) * 100
        Write-Progress -Id 0 -Activity "Cleaning file names" -Status "Progress: " -PercentComplete $Completed
        $filestoClean = Get-ChildItem -File "$folderToSort\*.package" -Depth 0        
        for ($num=0; $filestoClean.Count -gt $num; $num++) {
            $currentFile = $filestoClean[$num]
            if ($currentFile.Basename -imatch [regex]::Escape($matchlist[$i])) {
                $newname = $currentFile.BaseName -replace [regex]::Escape($matchlist[$i]),$replacelist[0]
                $fileExists = Test-Path -LiteralPath "$folderToSort\$newname.package"
                if ($fileExists -eq $false) {
                    Rename-Item $currentFile -NewName "$newname.package" | Out-Null
                    "Package $($package.BaseName) renamed to $newname.package." | Out-File $logfile -Append
                } elseif ($fileExists -eq $true) {
                    New-Item -ItemType Directory "$folderToSort\_Duplicates" -Force | Out-Null
                    Move-Item -LiteralPath $($currentFile.FullName) -Destination "$folderToSort\_Duplicates\$($currentFile.Name)" | Out-Null
                    "Package $($package.BaseName) is a duplicate. Moved to duplicates folder." | Out-File $logfile -Append
                }
            }
        }
    }
}


Function Register-Package {
    param(
        [string]$logfile, #place to log output
        [object]$package, #which package is being processed
        [switch]$inArray, #is this package already in the array?
        [switch]$type, #if this is a type match
        [switch]$creator, #if this is a creator match
        [switch]$recolorist, #if this is a recolorist match
        [string]$typeMatch, #which type the package matched to
        [string]$creatorMatch, #which creator the package matched to 
        [string]$recoloristMatch, #which recolorist the package matched to 
        [string]$destination, #where the package is going 
        [switch]$noCreatorMatch, #this did not match a creator
        [switch]$noTypeMatch, #this did not match a type
        [switch]$duplicate, #file is a dupe
        [switch]$outlier, #file is an outlier
        [switch]$historical, #file is for historical sorting
        [switch]$void #no match, manual sort only
        )
        if ($inArray) { #file already processed 
            "Package $script:packageCount/$script:packagesTotal, $($package.BaseName) has already been processed. Skipping." | Out-File $logfile -Append
        }
        if ($type) { #got a type match, proceed to creators
            "Package $script:packageCount/$script:packagesTotal, $($package.BaseName) matched to type: $typeMatch." | Out-File $logfile -Append
        }
        if ($creator) { #got a creator match! moving into a folder
            New-Item -ItemType Directory -Force -Path $destination | Out-Null
            Move-Item <#-Verbose-#> -Path $($package.FullName) -Destination "$destination\$($package.Name)" | Out-Null
            "Package $script:packageCount/$script:packagesTotal, $($package.BaseName) matched to creator: $creatorMatch. Moving to $destination." | Out-File $logfile -Append
            $script:packagesMoved += $package
            "Package $script:packageCount/$script:packagesTotal, $($package.BaseName) has been processed." | Out-File $logfile -Append
        }
        if ($recolorist) { #got a recolorist match! moving into a folder
            New-Item -ItemType Directory -Force -Path $destination | Out-Null
            Move-Item <#-Verbose-#> -Path $($package.FullName) -Destination "$destination\$($package.Name)" | Out-Null
            "Package $script:packageCount/$script:packagesTotal, $($package.BaseName) matched to recolorist: $recoloristMatch. Moving to $destination." | Out-File $logfile -Append
            $script:packagesMoved += $package
            "Package $script:packageCount/$script:packagesTotal, $($package.BaseName) has been processed." | Out-File $logfile -Append
        }
        if ($noCreatorMatch) { #no creator could be found, moving into a folder withouta creator tag
            New-Item -ItemType Directory -Force -Path $destination | Out-Null
            Move-Item <#-Verbose-#> -Path $($package.FullName) -Destination "$destination\$($package.Name)" | Out-Null
            "Package $script:packageCount/$script:packagesTotal, $($package.BaseName) could not find a matching creator. Moving to $destination." | Out-File $logfile -Append
            $script:packagesMoved += $package
            "Package $script:packageCount/$script:packagesTotal, $($package.BaseName) has been processed." | Out-File $logfile -Append
        }
        if ($noTypeMatch) { #found a creator but no type? moving to a sorting folder with a creator tag
            New-Item -ItemType Directory -Force -Path $destination | Out-Null
            Move-Item <#-Verbose-#> -Path $($package.FullName) -Destination "$destination\$($package.Name)" | Out-Null
            "Package $script:packageCount/$script:packagesTotal, $($package.BaseName) could not find a matching type. Moving to $destination." | Out-File $logfile -Append
            $script:packagesMoved += $package
            "Package $script:packageCount/$script:packagesTotal, $($package.BaseName) has been processed." | Out-File $logfile -Append
        }
        if ($void) { #no clue. moving to sort later.
            New-Item -ItemType Directory -Force -Path $destination | Out-Null
            Move-Item <#-Verbose-#> -Path $($package.FullName) -Destination "$destination\$($package.Name)" | Out-Null
            "Package $script:packageCount/$script:packagesTotal, $($package.BaseName) matched nothing. Moving to $destination." | Out-File $logfile -Append
            $script:packagesMoved += $package
            "Package $script:packageCount/$script:packagesTotal, $($package.BaseName) has been processed." | Out-File $logfile -Append
        }
        if ($duplicate) { #duplicate file.
            New-Item -ItemType Directory -Force -Path $destination | Out-Null
            Move-Item <#-Verbose-#> -Path $($package.FullName) -Destination "$destination\$($package.Name)" | Out-Null
            "Package $script:packageCount/$script:packagesTotal, $($package.BaseName) seems to be a duplicate. Moving to $destination." | Out-File $logfile -Append
            $script:packagesMoved += $package
            "Package $script:packageCount/$script:packagesTotal, $($package.BaseName) has been processed." | Out-File $logfile -Append
        }
        if ($outlier) { #one of the outliers
            New-Item -ItemType Directory -Force -Path $destination | Out-Null
            Move-Item <#-Verbose-#> -Path $($package.FullName) -Destination "$destination\$($package.Name)" | Out-Null
            "Package $script:packageCount/$script:packagesTotal, $($package.BaseName) is flagged as an outlier. Moving to $destination." | Out-File $logfile -Append
            $script:packagesMoved += $package
            "Package $script:packageCount/$script:packagesTotal, $($package.BaseName) has been processed." | Out-File $logfile -Append
        }
        if ($historical) { #historical for sorting
            New-Item -ItemType Directory -Force -Path $destination | Out-Null
            Move-Item <#-Verbose-#> -Path $($package.FullName) -Destination "$destination\$($package.Name)" | Out-Null
            "Package $script:packageCount/$script:packagesTotal, $($package.BaseName) is flagged as potentially historical. Moving to $destination." | Out-File $logfile -Append
            $script:packagesMoved += $package
            "Package $script:packageCount/$script:packagesTotal, $($package.BaseName) has been processed." | Out-File $logfile -Append
        }
}

Function Initialize-Autosorting {
    param (
        [string]$folderWithPackages, #what folder are we parsing through
        [array]$types, #our list of CC types
        [array]$typesFolder, #folders associated with those types
        [array]$creators, #our list of creators
        [array]$recolorist, #a list of recolorists
        [array]$historicals, #a list of historical terms that should put files to sort elsewhere
        [array]$historicalFolders, #folders associated with those historical terms
        [array]$outliers, #outliers, things that should be moved no matter what
        [array]$outlierFolders, #matching folders
        [switch]$cleanFileNames #do we clean up the file names?
    )   

    $logfile = "$folderWithPackages\Output.log"
    $logbakExists = Test-Path "$folderWithPackages\Output.log.bak"
    $logexists = Test-Path "$folderWithPackages\Output.log"
    if ($logbakExists -eq $true) {
        Remove-Item "$folderWithPackages\Output.log.bak" -Force | Out-Null
    }
    if ($logexists -eq $true) {
        Rename-Item $logfile "Output.log.bak" -Force -PassThru | Out-Null
    }    
    New-Item $logfile -ItemType file | Out-Null

    if ($cleanFileNames) {
        Initialize-TidyCharacters $folderWithPackages
    }

    $folderFullOfPackages = Get-ChildItem -File "$folderWithPackages\*.package"
    $script:packagesTotal = $folderFullOfPackages.Count

    $creators = $creators | Sort-Object -Uniq
    $creators = $creators | Sort-Object { $_.length } -Descending

    $script:packageCount = 0
    $script:packagesMoved = @()

    foreach ($package in $folderFullOfPackages) { #check every package folder
        $script:packageCount++ #increment count by one each time we check a package
        $Completedmove = ($script:packageCount/$script:packagesTotal) * 100
        Write-Progress -Id 2 -Activity "Searching through packages: $script:packageCount /$script:packagesTotal" -PercentComplete $Completedmove        
        if ($script:packagesMoved -contains $package) { #if the package has already been moved
            Register-Package -logfile $logfile -package $package $inArray #make a note
            Continue #and go to the next one
        }
        if ($package.BaseName -ilike "*(1)*" -OR $package.BaseName -ilike "*(2)*" -OR $package.BaseName -ilike "*(3)*" -OR $package.BaseName -ilike "*(4)*" -OR $package.BaseName -ilike "*(5)*" -OR $package.BaseName -ilike "*(6)*" -OR $package.BaseName -ilike "*(7)*" -OR $package.BaseName -ilike "*(8)*" -OR $package.BaseName -ilike "*(9)*" -OR $package.BaseName -ilike "*(10)*" -OR $package.BaseName -ilike "*(11)*" -OR $package.BaseName -ilike "*(12)*" -OR $package.BaseName -ilike "*(13)*" -OR $package.BaseName -ilike "*(14)*" -OR $package.BaseName -ilike "*(15)*") { #check for stupid duplicates :)
            $destination = "$folderToSort\_Duplicates"
            Register-Package -logfile $logfile -package $package -destination $destination -duplicate
            Continue #and go to the next one
        }
        for ($outlierCounter=0; $outliers.Count -gt $outlierCounter; $outlierCounter++){
            $thisOutlier = $outliers[$outlierCounter] #associate a variable with that type
            if ($script:packagesMoved -contains $package) { #if the package has already been moved
                Register-Package -logfile $logfile -package $package $inArray #make a note
                Continue #and go to the next one
            }
            if ($package.BaseName -ilike "*$thisOutlier*") { #see if it matches that variable
                $destination = $outlierFolders[$outlierCounter] #decied where it belongs
                Register-Package -logfile $logfile -package $package -destination $destination -outlier #kick it to its type folder
                Continue #and go to the next one
            }
        }
        for ($historicalCounter=0; $historicals.Count -gt $historicalCounter; $historicalCounter++){
            $thishistorical = $historicals[$historicalCounter] #associate a variable with that type
            if ($script:packagesMoved -contains $package) { #if the package has already been moved
                Register-Package -logfile $logfile -package $package $inArray #make a note
                Continue #and go to the next one
            }
            if ($package.BaseName -ilike "*$thishistorical*") { #see if it matches that variable
                $destination = $historicalFolders[$historicalCounter] #decied where it belongs
                Register-Package -logfile $logfile -package $package -destination $destination -historical #kick it to its type folder
                Continue #and go to the next one
            }
        }
        for ($typeCounter=0; $types.Count -gt $typeCounter; $typeCounter++) { #now check and see if the package matches a type in the array
            $thisType = $types[$typeCounter] #associate a variable with that type
            if ($script:packagesMoved -contains $package) { #if the package has already been moved
                Register-Package -logfile $logfile -package $package $inArray #make a note
                Continue #and go to the next one
            }
            if ($package.BaseName -ilike "*$thisType*") { #see if it matches that variable
                $typeMoveFolder = $typesFolder[$typeCounter] #decide where the type would move to
                Register-Package -logfile $logfile -package $package -typeMatch $thisType -type #register it as matched
                for ($creatorCounter=0; $creators.Count -gt $creatorCounter; $creatorCounter++) {
                    $thisCreator = $creators[$creatorCounter] #create a var of which type we're checking
                    if ($script:packagesMoved -contains $package) { #if the package has already been moved
                        Register-Package -logfile $logfile -package $package $inArray #make a note
                        Continue #and go to the next one
                    }
                    if ($package.BaseName -ilike "*$thisCreator*"){
                        $creatorMoveFolder = "$typeMoveFolder\$thisCreator"
                        for ($recoloristCounter=0; $recolorist.Count -gt $recoloristCounter; $recoloristCounter++) { #check against list of recolorists
                            $thisRecolorist = $recolorist[$recoloristCounter]
                            if ($script:packagesMoved -contains $package) { #if the package has already been moved
                                Register-Package -logfile $logfile -package $package $inArray #make a note
                                Continue #and go to the next one
                            }
                            if ($package.BaseName -ilike "*$thisRecolorist*"){ #if the file matches a recolorist
                                $destination = "$creatorMoveFolder\_$thisRecolorist"
                                Register-Package -logfile $logfile -package $package -recoloristMatch $thisRecolorist -destination $destination -recolorist 
                                Continue
                            } else { #if it doesnt match a recolorist, just pop it where it belongs
                                $destination = "$creatorMoveFolder"    
                                Register-Package -logfile $logfile -package $package -creatorMatch $thisCreator -destination $destination -creator 
                                Continue
                            }
                        }
                    }
                }
                if ($script:packagesMoved -contains $package) { #if the package has already been moved
                    Register-Package -logfile $logfile -package $package $inArray #make a note
                    Continue #and go to the next one
                }
                if ($script:packagesMoved -notcontains $package) { #if the package has gone through the above but NOT been moved
                    $destination = $typeMoveFolder
                    Register-Package -logfile $logfile -package $package -destination $destination -noCreatorMatch #kick it to its type folder
                    Continue #and go to the next one
                }
            }
        }
        for ($creatorCounter=0; $creators.Count -gt $creatorCounter; $creatorCounter++) {
            $thisCreator = $creators[$creatorCounter]
            if ($script:packagesMoved -contains $package) { #if the package has already been moved
                Register-Package -logfile $logfile -package $package $inArray #make a note
                Continue #and go to the next one
            }
            if ($package.BaseName -ilike "*$thisCreator*"){
                $creatorMoveFolder = "$folderWithPackages\Manual Sort\$thisCreator"
                for ($recoloristCounter=0; $recolorist.Count -gt $recoloristCounter; $recoloristCounter++) { #check against list of recolorists
                    $thisRecolorist = $recolorist[$recoloristCounter]
                    if ($script:packagesMoved -contains $package) { #if the package has already been moved
                        Register-Package -logfile $logfile -package $package $inArray #make a note
                        Continue #and go to the next one
                    }
                    if ($package.BaseName -ilike "*$thisRecolorist*"){ #if the file matches a recolorist
                        $destination = "$creatorMoveFolder\_$thisRecolorist"
                        Register-Package -logfile $logfile -package $package -recoloristMatch $thisRecolorist -destination $destination -recolorist 
                        Continue
                    } else { #if it doesnt match a recolorist, just pop it where it belongs
                        $destination = "$creatorMoveFolder"    
                        Register-Package -logfile $logfile -package $package -creatorMatch $thisCreator -destination $destination -noTypeMatch 
                        Continue
                    }
                }
            }
        }
        if ($script:packagesMoved -contains $package) { #if the package has already been moved
            Register-Package -logfile $logfile -package $package $inArray #make a note
            Continue #and go to the next one
        }
        if ($script:packagesMoved -notcontains $package) { #if the package has gone through the above but NOT been moved
            $destination = "$folderWithPackages\Manual Sort"
            Register-Package -logfile $logfile -package $package -destination $destination -void #kick it to manual sort
            Continue #and go to the next one
        }
    }
}

################################

$startingVars = Get-Variable

###########VARS###############
$PSStyle.Progress.View = 'Minimal'

$yesNoQuestion = "&Yes", "&No"
$cleanUpFileNames = $Host.UI.PromptForChoice("File Names", "Clean file names up?", $yesNoQuestion, 1)
$folderToSort = <#"M:\The Sims 4 (Documents)\!UnmergedCC\testingfolder"#> Read-Host -prompt "Location of Unsorted Folder"
$generalCC = "$folderToSort\General\Unmerged_CC"
$modernCC = "$folderToSort\General\Unmerged_CC"

$typesList = @()
$typesFolderList = @()
$creatorsList = @()
$recoloristList = @()
$recoloristFolders = @()
$outliers = @()
$outlierFolders = @()
$historicals = @()
$historicalFolders = @()

$CSV = Import-CSV ".\Sims4SortCC.csv"
for ($lineCounter=0; $CSV.Types.Count -gt $lineCounter; $lineCounter++){
    if ($CSV.Types[$lineCounter] -notlike ''){
        $toAdd = Invoke-Expression """$($CSV.Types[$lineCounter])"""
        $typesList += $toAdd
    }
}
for ($lineCounter=0; $CSV.FoldersForType.Count -gt $lineCounter; $lineCounter++){    
    if ($CSV.FoldersForType[$lineCounter] -notlike ''){
        $toAdd = Invoke-Expression """$($CSV.FoldersForType[$lineCounter])"""
        $typesFolderList += $toAdd
    }
}
for ($lineCounter=0; $CSV.Creators.Count -gt $lineCounter; $lineCounter++){  
    if ($CSV.Creators[$lineCounter] -notlike ''){
        $toAdd1 = Invoke-Expression """$($CSV.Creators[$lineCounter])"""
        $toAdd = $toAdd1.ToUpper()
        $creatorsList += $toAdd
    }
}
for ($lineCounter=0; $CSV.Recolorists.Count -gt $lineCounter; $lineCounter++){
    if ($CSV.Recolorists[$lineCounter] -notlike ''){
        $toAdd = Invoke-Expression """$($CSV.Recolorists[$lineCounter])"""
        $recoloristList += $toAdd
    }
}
for ($lineCounter=0; $CSV.FoldersForRecolorists.Count -gt $lineCounter; $lineCounter++){
    if ($CSV.FoldersForRecolorists[$lineCounter] -notlike ''){
        $toAdd = Invoke-Expression """$($CSV.FoldersForRecolorists[$lineCounter])"""
        $recoloristFolders += $toAdd
    }
}
for ($lineCounter=0; $CSV.Historicals.Count -gt $lineCounter; $lineCounter++){
    if ($CSV.Historicals[$lineCounter] -notlike ''){
        $toAdd = Invoke-Expression """$($CSV.Historicals[$lineCounter])"""
        $historicals += $toAdd
    }
}
for ($lineCounter=0; $CSV.HistoricalFolders.Count -gt $lineCounter; $lineCounter++){
    if ($CSV.HistoricalFolders[$lineCounter] -notlike ''){
        $toAdd = Invoke-Expression """$($CSV.HistoricalFolders[$lineCounter])"""
        $historicalFolders += $toAdd
    }
}
for ($lineCounter=0; $CSV.Outliers.Count -gt $lineCounter; $lineCounter++){
    if ($CSV.Outliers[$lineCounter] -notlike ''){
        $toAdd = Invoke-Expression """$($CSV.Outliers[$lineCounter])"""
        $outliers += $toAdd
    }
}
for ($lineCounter=0; $CSV.OutlierFolders.Count -gt $lineCounter; $lineCounter++){
    if ($CSV.OutlierFolders[$lineCounter] -notlike ''){
        $toAdd = Invoke-Expression """$($CSV.OutlierFolders[$lineCounter])"""
        $outlierFolders += $toAdd
    }
}

if ($cleanUpFileNames -eq 0) {
    Initialize-AutoSorting -folderWithPackages $folderToSort -types $typesList -typesFolder $typesFolderList -creators $creatorsList -recolorist $recoloristList -historicals $historicals -historicalFolders $historicalFolders -outliers $outliers -outlierFolders $outlierFolders -cleanFileNames
} else {
    Initialize-AutoSorting -folderWithPackages $folderToSort -types $typesList -typesFolder $typesFolderList -creators $creatorsList -recolorist $recoloristList -historicals $historicals -historicalFolders $historicalFolders -outliers $outliers -outlierFolders $outlierFolders
}

Out-Script
