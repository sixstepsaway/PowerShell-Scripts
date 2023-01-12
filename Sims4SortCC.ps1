
Function Out-Script {
    Write-Host "Finishing up."
    $endingVars = Get-Variable
    Remove-Variable $endingVars -Exclude $startingVars
    Exit
}

Function Initialize-MatchTwoArrays {
    Param(
        [array]$arrayToSort,
        [array]$arrayToMatch
    )
    Remove-Variable arraySorted
    Remove-Variable sortedArray
    Remove-Variable numItems
    Remove-Variable itemsCount

    $numItems = $arrayToSort.Count
    $numItems++
    $script:sortedArray = @()
    for ($itemsCount=0; $numItems -gt $itemsCount; $itemsCount++) {
        $script:sortedArray += "$itemsCount"
    }

    $script:arraySorted = $arrayToSort | Sort-Object {$_.Length} -Descending
    $sortednum=-1


    foreach ($sortedOrderItem in $script:arraySorted) {
        $sortednum++
        $unsortednum=-1
        #Write-Verbose "Checking $sortedOrderItem from sorted list."
        foreach ($originalOrderItem in $typesList) {
            $unsortednum++
            #Write-Verbose "Checking $originalOrderItem from unsorted list."
            if ($sortedOrderItem -contains $originalOrderItem) {
                $script:sortedArray[$sortednum] = "$($arrayToMatch[$unsortedNum])"
                Write-Verbose "$sortedOrderItem ($sortedNum) matched against $originalOrderItem ($unsortednum) which should corrolate to $($arrayToMatch[$unsortednum])."
                Continue
        }
        }
    }
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
        [string]$destination, #where the package is going 
        [switch]$duplicate, #file is a dupe
        [switch]$outlier, #file is an outlier
        [switch]$historical, #file is for historical sorting
        [switch]$void #no match, manual sort only
        )
        if ($inArray) { #file already processed 
            $output = "Package $script:packageCount/$script:packagesTotal, $($package.BaseName) has already been processed. Skipping."
            Write-Verbose $output
            $output | Out-File $logfile -Append
        }
        if ($void) { #no clue. moving to sort later.
            New-Item -ItemType Directory -Force -Path $destination | Out-Null
            #Move-Item <#-Verbose-#> -Path $($package.FullName) -Destination "$destination\$($package.Name)" | Out-Null
            $output = "Package $script:packageCount/$script:packagesTotal, $($package.BaseName) matched nothing. Moving to $destination."
            Write-Verbose $output
            $output | Out-File $logfile -Append
            $script:packagesMoved += $package
            $output = "Package $script:packageCount/$script:packagesTotal, $($package.BaseName) has been processed." |
            Write-Verbose $output
            $output | Out-File $logfile -Append
        }
        if ($duplicate) { #duplicate file.
            New-Item -ItemType Directory -Force -Path $destination | Out-Null
            #Move-Item <#-Verbose-#> -Path $($package.FullName) -Destination "$destination\$($package.Name)" | Out-Null
            $output = "Package $script:packageCount/$script:packagesTotal, $($package.BaseName) seems to be a duplicate. Moving to $destination."
            Write-Verbose $output
            $output | Out-File $logfile -Append
            $script:packagesMoved += $package
            $output = "Package $script:packageCount/$script:packagesTotal, $($package.BaseName) has been processed."
            Write-Verbose $output
            $output | Out-File $logfile -Append
        }
        if ($outlier) { #one of the outliers
            New-Item -ItemType Directory -Force -Path $destination | Out-Null
            #Move-Item <#-Verbose-#> -Path $($package.FullName) -Destination "$destination\$($package.Name)" | Out-Null
            $output = "Package $script:packageCount/$script:packagesTotal, $($package.BaseName) is flagged as an outlier. Moving to $destination."
            Write-Verbose $output
            $output | Out-File $logfile -Append
            $script:packagesMoved += $package
            $output = "Package $script:packageCount/$script:packagesTotal, $($package.BaseName) has been processed." |
            Write-Verbose $output
            $output | Out-File $logfile -Append
        }
        if ($historical) { #historical for sorting
            New-Item -ItemType Directory -Force -Path $destination | Out-Null
            #Move-Item <#-Verbose-#> -Path $($package.FullName) -Destination "$destination\$($package.Name)" | Out-Null
            $output = "Package $script:packageCount/$script:packagesTotal, $($package.BaseName) is flagged as potentially historical. Moving to $destination."
            Write-Verbose $output
            $output | Out-File $logfile -Append
            $script:packagesMoved += $package
            $output = "Package $script:packageCount/$script:packagesTotal, $($package.BaseName) has been processed."
            Write-Verbose $output
            $output | Out-File $logfile -Append
        }
}

Function Initialize-Autosorting {
    param (
        [switch]$cleanFileNames #do we clean up the file names?
    )

    $packagesToSort = Get-ChildItem $folderToSort
    $script:packagesTotal = $packagesToSort.Count
    $script:packagesMoved = @()
    Write-Verbose "Getting packages"
    Write-Verbose "Example packages: $($packagesToSort[4]), $($packagesToSort[44]), $($packagesToSort[444]), $($packagesToSort[4444]), $($packagesToSort[44444]), $($packagesToSort[1324]), $($packagesToSort[4664]), $($packagesToSort[21]), $($packagesToSort[789]), $($packagesToSort[654]), $($packagesToSort[648]), $($packagesToSort[687]), $($packagesToSort[684])."

    if ($cleanFileNames) {
        Write-Verbose "Cleaning the file names now"
        Initialize-TidyCharacters        
    } else {
        Write-Verbose "Leaving the file names alone"
    }
    
    foreach ($package in $packagesToSort) {
        #Write-Verbose "Checking $package."
        Write-Verbose $outliers
        if ($script:packagesMoved -contains $package) {
            Register-Package -logfile $logfile -package $package -inArray
            Continue
        } elseif ($package.BaseName -ilike "*(1)*" -OR $package.BaseName -ilike "*(2)*" -OR $package.BaseName -ilike "*(3)*" -OR $package.BaseName -ilike "*(4)*" -OR $package.BaseName -ilike "*(5)*" -OR $package.BaseName -ilike "*(6)*" -OR $package.BaseName -ilike "*(7)*" -OR $package.BaseName -ilike "*(8)*" -OR $package.BaseName -ilike "*(9)*" -OR $package.BaseName -ilike "*(10)*" -OR $package.BaseName -ilike "*(11)*" -OR $package.BaseName -ilike "*(12)*" -OR $package.BaseName -ilike "*(13)*" -OR $package.BaseName -ilike "*(14)*" -OR $package.BaseName -ilike "*(15)*") { #check for stupid duplicates :)
            $destination = "$folderToSort\_Duplicates"
            Register-Package -logfile $logfile -package $package -destination $destination -duplicate
            Continue
        } else {
            # check for type matches, including outliers
            for ($parseProgress=0; $outliers.Count -gt $parseProgress; $parseProgress++) {
                $thisSearch = $outliers[$parseProgress]
                Write-Verbose "Checking outliers, outlier number $parseProgress, $thisSearch"
                if ($script:packagesMoved -contains $package) {
                    Register-Package -logfile $logfile -package $package -inArray
                    Continue
                } elseif ($package.BaseName -ilike "*$thisSearch*") {
                    Write-Verbose "Matched file number $parseProgress, $package to $thisSearch."
                        $destination = $outlierFolders[$parseProgress]
                        Register-Package -logfile $logfile -package $package -destination $destination -outlier
                        Continue
                }
            }
            for ($parseProgress=0; $historicals.Count -gt $parseProgress; $parseProgress++) {
                $thisSearch = $historicals[$parseProgress]
                Write-Verbose "Checking historicals, historical number $parseProgress, $thisSearch"
                if ($script:packagesMoved -contains $package) {
                    Register-Package -logfile $logfile -package $package -inArray
                    Continue
                } elseif ($package.BaseName -ilike "*$thisSearch*") {
                        $destination = $historicalFolders[$parseProgress]
                        Register-Package -logfile $logfile -package $package -destination $destination -historical
                        Continue
                }
            }
            for ($parseProgress=0; $typesList.Count -gt $parseProgress; $parseProgress++) {
                $thisSearch = $types[$parseProgress]
                Write-Verbose "Checking types, type number $parseProgress, $thisSearch"
                if ($script:packagesMoved -contains $package) {
                    Register-Package -logfile $logfile -package $package -inArray
                    Continue
                } else {
                    if ($package.BaseName -ilike "*$thisSearch*") {
                        $destination = $typesFolders[$parseProgress]
                        Register-Package -logfile $logfile -package $package -destination $destination -type
                        Continue
                    }
                }
            }
        }
    }
}

################################

$startingVars = Get-Variable
$VerbosePreference = "Continue"

###########VARS###############
$PSStyle.Progress.View = 'Minimal'

$yesNoQuestion = "&Yes", "&No"
$cleanUpFileNames = $Host.UI.PromptForChoice("File Names", "Clean file names up?", $yesNoQuestion, 1)
$folderToSort = <#"M:\The Sims 4 (Documents)\!UnmergedCC\testingfolder"#> Read-Host -prompt "Location of Unsorted Folder"
$generalCC = "$folderToSort\General\Unmerged_CC"
$modernCC = "$folderToSort\General\Unmerged_CC"

$typesList = @()
$typesFolders = @()
$creatorsList = @()
$recoloristList = @()
$recoloristFolders = @()
$outliers = @()
$outlierFolders = @()
$historicals = @()
$historicalFolders = @()

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

$CSV = Import-CSV ".\Sims4SortCC.csv"
Write-Verbose "Imported CSV"
for ($lineCounter=0; $CSV.Types.Count -gt $lineCounter; $lineCounter++){
    if ($CSV.Types[$lineCounter] -notlike ''){
        $toAdd = Invoke-Expression """$($CSV.Types[$lineCounter])"""
        $typesList += $toAdd
    }
}
Write-Verbose "Imported types list."
for ($lineCounter=0; $CSV.FoldersForType.Count -gt $lineCounter; $lineCounter++){    
    if ($CSV.FoldersForType[$lineCounter] -notlike ''){
        $toAdd = Invoke-Expression """$($CSV.FoldersForType[$lineCounter])"""
        $typesFolders += $toAdd
    }
}
Write-Verbose "Imported types folder list."
for ($lineCounter=0; $CSV.Creators.Count -gt $lineCounter; $lineCounter++){  
    if ($CSV.Creators[$lineCounter] -notlike ''){
        $toAdd1 = Invoke-Expression """$($CSV.Creators[$lineCounter])"""
        $toAdd = $toAdd1.ToUpper()
        $creatorsList += $toAdd
    }
}
Write-Verbose "Imported creators list."
for ($lineCounter=0; $CSV.Recolorists.Count -gt $lineCounter; $lineCounter++){
    if ($CSV.Recolorists[$lineCounter] -notlike ''){
        $toAdd = Invoke-Expression """$($CSV.Recolorists[$lineCounter])"""
        $recoloristList += $toAdd
    }
}
Write-Verbose "Imported recolorists list."
for ($lineCounter=0; $CSV.FoldersForRecolorists.Count -gt $lineCounter; $lineCounter++){
    if ($CSV.FoldersForRecolorists[$lineCounter] -notlike ''){
        $toAdd = Invoke-Expression """$($CSV.FoldersForRecolorists[$lineCounter])"""
        $recoloristFolders += $toAdd
    }
}
Write-Verbose "Imported recolorist folders list."
for ($lineCounter=0; $CSV.Historicals.Count -gt $lineCounter; $lineCounter++){
    if ($CSV.Historicals[$lineCounter] -notlike ''){
        $toAdd = Invoke-Expression """$($CSV.Historicals[$lineCounter])"""
        $historicals += $toAdd
    }
}
Write-Verbose "Imported historicals list."
for ($lineCounter=0; $CSV.HistoricalFolders.Count -gt $lineCounter; $lineCounter++){
    if ($CSV.HistoricalFolders[$lineCounter] -notlike ''){
        $toAdd = Invoke-Expression """$($CSV.HistoricalFolders[$lineCounter])"""
        $historicalFolders += $toAdd
    }
}
Write-Verbose "Imported historicals folders list."
for ($lineCounter=0; $CSV.Outliers.Count -gt $lineCounter; $lineCounter++){
    if ($CSV.Outliers[$lineCounter] -notlike ''){
        $toAdd = Invoke-Expression """$($CSV.Outliers[$lineCounter])"""
        $outliers += $toAdd
    }
}
Write-Verbose "Imported outliers list."
for ($lineCounter=0; $CSV.OutlierFolders.Count -gt $lineCounter; $lineCounter++){
    if ($CSV.OutlierFolders[$lineCounter] -notlike ''){
        $toAdd = Invoke-Expression """$($CSV.OutlierFolders[$lineCounter])"""
        $outlierFolders += $toAdd
    }
}
Write-Verbose "Imported outliers folders list."

$creators = $creators | Sort-Object -Uniq
$creators = $creators | Sort-Object { $_.length } -Descending

Initialize-MatchTwoArrays -arrayToSort $typesList -arrayToMatch $typesFolders 

$typesList = $script:arraySorted
$typesFolders = $script:sortedArray

Initialize-MatchTwoArrays -arrayToSort $recoloristList -arrayToMatch $recoloristFolders 

$recoloristList = $script:arraySorted
$recoloristFolders = $script:sortedArray

Initialize-MatchTwoArrays -arrayToSort $historicals -arrayToMatch $historicalFolders 

$historicals = $script:arraySorted
$historicalFolders = $script:sortedArray

Initialize-MatchTwoArrays -arrayToSort $outliers -arrayToMatch $outlierFolders 

$outliers = $script:arraySorted
$outlierFolders = $script:sortedArray

$typesList
$typesFolders
$recoloristList
$recoloristFolders
$historicals 
$historicalFolders
$outliers
$outlierFolders

#Initialize-Autosorting

Out-Script
