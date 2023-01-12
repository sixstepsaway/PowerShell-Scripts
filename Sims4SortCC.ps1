
Function Out-Script {
    Write-Host "Finishing up."
    $endingVars = Get-Variable
    Remove-Variable $endingVars -Exclude $startingVars
    Exit
}

Function Initialize-MatchTwoArrays {
    Param(
        [array]$arrayToSort,
        [array]$arrayToMatch,
        [string]$debug
    )

    "RUNNING MATCH PASS`n 
This pass is for $debug. `n
`n
Acquired params are the array to sort: `n
$arrayToSort`n
`n
and the array to match:`n 
$arrayToMatch.
`n
Potentially lingering variables: `n
arraySorted: `n
$arraySorted `n
sortedArray: `n
$sortedArray `n
numItems: `n
$numItems `n
itemsCount: `n
$itemsCount" | Out-File $outfileTest -Append

    Remove-Variable arraySorted
    Remove-Variable sortedArray
    Remove-Variable numItems
    Remove-Variable itemsCount

"Removed the variables for arraySorted, sortedArray, numItems and itemsCount.`n
The following should be blank: `n" | Out-File $outfileTest -Append
$arraySorted | Out-File $outfileTest -Append
$sortedArray | Out-File $outfileTest -Append
$numItems | Out-File $outfileTest -Append
$itemsCount | Out-File $outfileTest -Append
"If the above is not blank, something went wrong.
`n" | Out-File $outfileTest -Append

    $numItems = $arrayToSort.Count
    "numItems has been established as $numItems." | Out-File $outfileTest -Append
    $numItems++
    "numItems is now $numItems." | Out-File $outfileTest -Append
    $script:sortedArray = @()
    "sortedArray established and should be blank. It is:`n" | Out-File $outfileTest -Append 
    $sortedArray | Out-File $outfileTest -Append
    for ($itemsCount=0; $numItems -gt $itemsCount; $itemsCount++) {
        $script:sortedArray += "$itemsCount"
    }
    "SortedArray has been populated with numbers as strings. SortedArray: `n" | Out-File $outfileTest -Append
    $sortedArray | Out-File $outfileTest -Append

    $script:arraySorted = $arrayToSort | Sort-Object {$_.Length} -Descending
    "arraySorted is the sorted version of the first array. It has been sorted:`n" | Out-File $outfileTest -Append
    $script:arraySorted | Out-File $outfileTest -Append

    "The sortednum is the number for parsing through. It has been established as $sortednum." | Out-File $outfileTest -Append
    $sortednum=-1


    foreach ($sortedOrderItem in $script:arraySorted) {        
        $sortednum++
        $unsortednum=-1
        "Parsing through the sorted version of the array. Currently checking $sortedOrderItem, which is number $sortednum" | Out-File $outfileTest -Append
        foreach ($originalOrderItem in $typesList) {
            $unsortednum++
            "Now checking through the original array and comparing the two. We are comparing $sortedOrderItem from the sorted array with $originalOrderItem (number $unsortednum) in the unsorted array." | Out-File $outfileTest -Append
            if ($sortedOrderItem -contains $originalOrderItem) {
                ":::::::::::::: `n
                A match has been made. $sortedOrderItem matches $originalOrderItem. SortedArray will now be populated with the correct corrolated item." | Out-File $outfileTest -Append
                $script:sortedArray[$sortednum] = "$($arrayToMatch[$unsortedNum])"
                "Item $sortednum of the sorted array is:`n
                $($sortedArray[$sortednum])`n
                `n
                The full SortedArray currently is: `n" | Out-File $outfileTest -Append
                $sortedArray | Out-File $outfileTest -Append
                ":::::::::::::
                `nThe script will now continue." | Out-File $outfileTest -Append
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

$logfile = "$folderToSort\Output.log"
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

for ($lineCounter=0; $CSV.Creators.Count -gt $lineCounter; $lineCounter++){  
    if ($CSV.Creators[$lineCounter] -notlike ''){
        $toAdd1 = Invoke-Expression """$($CSV.Creators[$lineCounter])"""
        $toAdd = $toAdd1.ToUpper()
        $creatorsList += $toAdd
    }
}
Write-Verbose "Imported creators list."

#import column types to variable
for ($lineCounter=0; $CSV.Types.Count -gt $lineCounter; $lineCounter++){
    if ($CSV.Types[$lineCounter] -notlike ''){
        $toAdd = Invoke-Expression """$($CSV.Types[$lineCounter])"""
        $typesList += $toAdd
    }
}
Write-Verbose "Imported types list."

#import column folders for type to variable
for ($lineCounter=0; $CSV.FoldersforType.Count -gt $lineCounter; $lineCounter++){    
    if ($CSV.FoldersforType[$lineCounter] -notlike ''){
        $toAdd = Invoke-Expression """$($CSV.FoldersforType[$lineCounter])"""
        $typesFolders += $toAdd
    }
}
Write-Verbose "Imported types folder list."

#import column recolorists to variable
for ($lineCounter=0; $CSV.Recolorists.Count -gt $lineCounter; $lineCounter++){
    if ($CSV.Recolorists[$lineCounter] -notlike ''){
        $toAdd = Invoke-Expression """$($CSV.Recolorists[$lineCounter])"""
        $recoloristList += $toAdd
    }
}
Write-Verbose "Imported recolorists list."

#import column recolorist folders to variable
for ($lineCounter=0; $CSV.FoldersforRecolorists.Count -gt $lineCounter; $lineCounter++){
    if ($CSV.FoldersforRecolorists[$lineCounter] -notlike ''){
        $toAdd = Invoke-Expression """$($CSV.FoldersforRecolorists[$lineCounter])"""
        $recoloristFolders += $toAdd
    }
}
Write-Verbose "Imported recolorist folders list."

#import column historicals to variable
for ($lineCounter=0; $CSV.Historicals.Count -gt $lineCounter; $lineCounter++){
    if ($CSV.Historicals[$lineCounter] -notlike ''){
        $toAdd = Invoke-Expression """$($CSV.Historicals[$lineCounter])"""
        $historicals += $toAdd
    }
}
Write-Verbose "Imported historicals list."

#import column historical folders to variable
for ($lineCounter=0; $CSV.HistoricalFolders.Count -gt $lineCounter; $lineCounter++){
    if ($CSV.HistoricalFolders[$lineCounter] -notlike ''){
        $toAdd = Invoke-Expression """$($CSV.HistoricalFolders[$lineCounter])"""
        $historicalFolders += $toAdd
    }
}
Write-Verbose "Imported historicals folders list."

#import column outliers to variable
for ($lineCounter=0; $CSV.Outliers.Count -gt $lineCounter; $lineCounter++){
    if ($CSV.Outliers[$lineCounter] -notlike ''){
        $toAdd = Invoke-Expression """$($CSV.Outliers[$lineCounter])"""
        $outliers += $toAdd
    }
}
Write-Verbose "Imported outliers list."

#import column outlier folders to variable
for ($lineCounter=0; $CSV.OutlierFolders.Count -gt $lineCounter; $lineCounter++){
    if ($CSV.OutlierFolders[$lineCounter] -notlike ''){
        $toAdd = Invoke-Expression """$($CSV.OutlierFolders[$lineCounter])"""
        $outlierFolders += $toAdd
    }
}
Write-Verbose "Imported outliers folders list."

$outfileTest = "$foldertosort\!TestingLog.log"

":::BEFORE ORDERING::: `n
`n
OUTLIERS::: `n" | Out-File $outfileTest
$outliers | Out-File $outfileTest -Append
"`n
OUTLIER FOLDERS::: `n" | Out-File $outfileTest -Append
$outlierFolders | Out-File $outfileTest -Append
"`n
TYPES:::`n" | Out-File $outfileTest -Append
$typesList | Out-File $outfileTest -Append
"`n
TYPES FOLDERS:::`n" | Out-File $outfileTest -Append
$typesFolders | Out-File $outfileTest -Append
"`n
RECOLORSTS:::`n" | Out-File $outfileTest -Append
$recoloristList | Out-File $outfileTest -Append
"`n
RECOLORIST FOLDERS:::`n"
$recoloristFolders | Out-File $outfileTest -Append
"`n
HISTORICALS:::`n" | Out-File $outfileTest -Append
$historicals | Out-File $outfileTest -Append
"`n
HISTORICAL FOLDERS:::`n" | Out-File $outfileTest -Append
$historicalFolders | Out-File $outfileTest -Append


#reorder creators array to sort by length, descending
$creators = $creators | Sort-Object -Uniq
$creators = $creators | Sort-Object { $_.length } -Descending


#reorder outliers array to sort by length, descending, and match against second array
Initialize-MatchTwoArrays -arrayToSort $outliers -arrayToMatch $outlierFolders -debug "OUTLIERS (1)"
$outliers = $script:arraySorted
$outlierFolders = $script:sortedArray

#reorder types array to sort by length, descending, and match against second array
Initialize-MatchTwoArrays -arrayToSort $typesList -arrayToMatch $typesFolders -debug "TYPES (2)"
$typesList = $script:arraySorted
$typesFolders = $script:sortedArray

#reorder recolorist array to sort by length, descending, and match against second array
Initialize-MatchTwoArrays -arrayToSort $recoloristList -arrayToMatch $recoloristFolders -debug "RECOLORISTS (3)"
$recoloristList = $script:arraySorted
$recoloristFolders = $script:sortedArray

#reorder historicals array to sort by length, descending, and match against second array
Initialize-MatchTwoArrays -arrayToSort $historicals -arrayToMatch $historicalFolders -debug "HISTORICALS (3)"
$historicals = $script:arraySorted
$historicalFolders = $script:sortedArray

":::AFTER ORDERING::: `n
`n
OUTLIERS::: `n" | Out-File $outfileTest -Append
$outliers | Out-File $outfileTest -Append
"`n
OUTLIER FOLDERS::: `n" | Out-File $outfileTest -Append
$outlierFolders | Out-File $outfileTest -Append
"`n
TYPES:::`n" | Out-File $outfileTest -Append
$typesList | Out-File $outfileTest -Append
"`n
TYPES FOLDERS:::`n" | Out-File $outfileTest -Append
$typesFolders | Out-File $outfileTest -Append
"`n
RECOLORSTS:::`n" | Out-File $outfileTest -Append
$recoloristList | Out-File $outfileTest -Append
"`n
RECOLORIST FOLDERS:::`n"
$recoloristFolders | Out-File $outfileTest -Append
"`n
HISTORICALS:::`n" | Out-File $outfileTest -Append
$historicals | Out-File $outfileTest -Append
"`n
HISTORICAL FOLDERS:::`n" | Out-File $outfileTest -Append
$historicalFolders | Out-File $outfileTest -Append


#Initialize-Autosorting

Out-Script
