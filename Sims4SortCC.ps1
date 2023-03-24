Function Out-Script {
    Write-Host "Finishing up."
    $endingVars = Get-Variable
    Remove-Variable $endingVars -Exclude $startingVars
    Exit
}

Function Out-LogMessage {
    Write-Verbose $message
    $message | Out-File $logfile -Append
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
    "`“"
    "❤") 
    $replacelist = @(<#---0---#> "") 

    $message = "Preparing to clean file names."
    Out-LogMessage
    $cleanstarttime = Get-Date -Format "MM/dd/yyyy HH:mm K"
    
    
    $filestoClean = Get-ChildItem -File "$folderToSort\*.package" -Depth 0
    $numberOfFiles = $filestoClean.Count
    $message = "Files to clean: $numberOfFiles."
    Out-LogMessage

    

    for ($i=0; $matchlist.Count -gt $i; $i++) {  
        Write-Progress -activity "Cleaning File Names" -ID 2 -ParentId 1 -status "Cleaned: $i of $numberOfFiles" -percentComplete (($i / $numberOfFiles)  * 100) #the part / the whole
        $message = "Cleaning progress: $completed%."
        Out-LogMessage
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
    $message = "File names cleaned: $i/$numberOfFiles."
    Out-LogMessage    
    }
    $cleanendtime = Get-Date -Format "MM/dd/yyyy HH:mm K"
    $message = "File name cleaning started at $cleanstarttime and finished at $cleanendtime!"
    Out-LogMessage 
    Write-Progress -activity "Cleaning File Names" -ID 2 -ParentId 1 -status "Cleaned: $i of $numberOfFiles" -percentComplete (($i / $numberOfFiles)  * 100) -Completed #the part / the whole   
}

Function Initialize-MoveFiles ($results) {
    $foldersToMake = @()

    $message = "Number of results: $($results.Count). Keeping only unique."
    Out-LogMessage

    <#$lognum = 1

    if ($debug -eq 0) {
        $message = "Verbose testing log $lognum."
        $message = "Items in Results: $($results.Count)"
        Out-LogMessage
        $message = "Results contents:"
        Out-LogMessage
        $counter=0
        foreach ($r in $results) {
            $counter++
            $message = "Results $counter`:"
            $message = "$($results.Package)"
            Out-LogMessage
        }
        $lognum++
        Pause
    }#>

    $resultsDests = $results | Sort-Object -Property destination -Unique

    $message = "Unique results: $($resultsDests.Count)."
    Out-LogMessage

    <#if ($debug -eq 0) {
        $message = "Verbose testing log $lognum."
        $message = "Items in Results: $($results.Count)"
        Out-LogMessage
        $message = "Results contents:"
        Out-LogMessage
        $counter=0
        foreach ($r in $results) {
            $counter++
            $message = "Results $counter`:"
            $message = "$($results.Package)"
            Out-LogMessage
        }
        $lognum++
        Pause
    }#>

    $message = "Adding $($resultsDests.Count) results to list of folders to make."
    Out-LogMessage
    <#if ($debug -eq 0) {
        $message = "Verbose testing log $lognum."
        $message = "Items in Results: $($results.Count)"
        Out-LogMessage
        $message = "Results contents:"
        Out-LogMessage
        $counter=0
        foreach ($r in $results) {
            $counter++
            $message = "Results $counter`:"
            $message = "$($results.Package)"
            Out-LogMessage
        }
        $lognum++
        Pause
    }#>
    $filesCount = $resultsDests.Count
    $filesdone = 0
    
    foreach ($file in $resultsDests) {
        $filesdone++
        $message = "($filesdone/$filesCount) Adding $($file.Destination) to list. "
        Out-LogMessage
        $foldersToMake += $file.Destination
    }
    <#if ($debug -eq 0) {
        $message = "Verbose testing log $lognum."
        $message = "Items in Results: $($results.Count)"
        Out-LogMessage
        $message = "Results contents:"
        Out-LogMessage
        $counter=0
        foreach ($r in $results) {
            $counter++
            $message = "Results $counter`:"
            $message = "$($results.Package)"
            Out-LogMessage
        }
        $lognum++
        Pause
    }#>
    $foldersToMake = $foldersToMake | Sort-Object -Unique

    $message = "Folders we'll be making: "
    Out-LogMessage
    foreach ($f in $folderstomake) {
        $message = $f
        Out-LogMessage
    }
    <#if ($debug -eq 0) {
        $message = "Verbose testing log $lognum."
        $message = "Items in Results: $($results.Count)"
        Out-LogMessage
        $message = "Results contents:"
        Out-LogMessage
        $counter=0
        foreach ($r in $results) {
            $counter++
            $message = "Results $counter`:"
            $message = "$($results.Package)"
            Out-LogMessage
        }
        $lognum++
        Pause
    }#>
    foreach ($folder in $foldersToMake) {
        $message = "Creating folder: $folder."
        Out-LogMessage
        New-Item -ItemType Directory -Force $folder | Out-Null
    }
    <#if ($debug -eq 0) {
        $message = "Verbose testing log $lognum."
        $message = "Items in Results: $($results.Count)"
        Out-LogMessage
        $message = "Results contents:"
        Out-LogMessage
        $counter=0
        foreach ($r in $results) {
            $counter++
            $message = "Results $counter`:"
            $message = "$($results.Package)"
            Out-LogMessage
        }
        $lognum++
        Pause
    }#>
    $alreadymoved = @()
    $tomove = $results.Count
    $moving=0
    foreach ($resultingItem in $results) {
        Write-Progress -activity "Moving Files" -ID 3 -ParentId 4 -status "Progress: $moving of $tomove" -percentComplete (($moving / $tomove)  * 100) #the part / the whole
        $message = "Now checking if $($resultingItem.Package) has already been moved."
        Out-LogMessage
        <#if ($debug -eq 0) {
            $message = "Verbose testing log $lognum."
            $message = "Items in Results: $($results.Count)"
            Out-LogMessage
            $message = "Results contents:"
            Out-LogMessage
            $counter=0
            foreach ($r in $results) {
                $counter++
                $message = "Results $counter`:"
                $message = "$($results.Package)"
                Out-LogMessage
            }
            $lognum++
            Pause
        }#>
        if ($alreadymoved -contains $resultingItem.Package) {
            $message = "Found $($resultingItem.Package) in array. Continuing."
            Out-LogMessage
            <#if ($debug -eq 0) {
                $message = "Verbose testing log $lognum."
                $message = "Items in Results: $($results.Count)"
                Out-LogMessage
                $message = "Results contents:"
                Out-LogMessage
                $counter=0
                foreach ($r in $results) {
                    $counter++
                    $message = "Results $counter`:"
                    $message = "$($results.Package)"
                    Out-LogMessage
                }
                $lognum++
                Pause
            }#>
            Continue
        } else {
            if ($resultingItem.Creator -eq "") {
                $message = "File has not been moved and does not have a matching creator."
                Out-LogMessage
                $message = "Moving $($resultingItem.PackageLoc) to $($resultingItem.Destination)\$($resultingItem.Package)."
                Out-LogMessage
                New-Item -Itemtype Directory "$($resultingItem.Destination)" -Force | Out-Null
                Move-Item -Path $resultingItem.PackageLoc -Destination "$($resultingItem.Destination)\$($resultingItem.Package)" 
                $message = "Just dest: $($resultingItem.Destination)"
                Out-LogMessage
                $message = "Just package: $($resultingItem.Package)"
                Out-LogMessage
                $message = "Dest/package: $($resultingItem.Destination)\$($resultingItem.Package)"
                Out-LogMessage
                $message = "Flagging file as moved."
                Out-LogMessage                
                $alreadymoved += $resultingItem.Package
                $message = "Done! Continuing."
                Out-LogMessage
                <#if ($debug -eq 0) {
                    $message = "Verbose testing log $lognum."
                    $message = "Items in Results: $($results.Count)"
                    Out-LogMessage
                    $message = "Results contents:"
                    Out-LogMessage
                    $counter=0
                    foreach ($r in $results) {
                        $counter++
                        $message = "Results $counter`:"
                        $message = "$($results.Package)"
                        Out-LogMessage
                    }
                    $lognum++
                    Pause
                }#>
                Continue
            } elseif ($resultingItem.Creator -ne "") {
                $message = "File has not been moved and has a matching creator."
                Out-LogMessage
                $message = "Moving $($resultingItem.PackageLoc) to $($resultingItem.Destination)\$($resultingItem.Package)."
                Out-LogMessage
                New-Item -Itemtype Directory "$($resultingItem.Destination)\$($resultingItem.Creator)" -Force | Out-Null
                Move-Item -Path $resultingItem.PackageLoc -Destination "$($resultingItem.Destination)\$($resultingItem.Creator)\$($resultingItem.Package)" 
                $message = "Just dest: $($resultingItem.Destination)"
                Out-LogMessage
                $message = "Just creator: $($resultingItem.Creator)"
                Out-LogMessage                
                $message = "Just package: $($resultingItem.Package)"
                Out-LogMessage
                $message = "Dest/package: $($resultingItem.Destination)\$($resultingItem.Package)"
                Out-LogMessage
                $message = "Dest/creator/package: $($resultingItem.Destination)\$($resultingItem.Creator)\$($resultingItem.Package)"
                Out-LogMessage
                $message = "Flagging file as moved."
                Out-LogMessage
                $alreadymoved += $resultingItem.Package
                $message = "Done! Continuing."
                Out-LogMessage
                <#if ($debug -eq 0) {
                    $message = "Verbose testing log $lognum."
                    $message = "Items in Results: $($results.Count)"
                    Out-LogMessage
                    $message = "Results contents:"
                    Out-LogMessage
                    $counter=0
                    foreach ($r in $results) {
                        $counter++
                        $message = "Results $counter`:"
                        $message = "$($results.Package)"
                        Out-LogMessage
                    }
                    $lognum++
                    Pause
                }#>
                Continue
            }            
            Continue
        }
        Continue
        $moving++
    }
    Write-Progress -activity "Moving Files" -ID 3 -ParentId 4 -status "Progress: $moving of $tomove" -percentComplete (($moving / $tomove)  * 100) -Completed #the part / the whole
}

Function Initialize-ParseCheckerArray {
    param (
        [System.Collections.ArrayList]$arraytoparse,
        [System.Collections.ArrayList]$creatorCollection,
        [string]$arrayname,
        [int]$arraynum,
        [switch]$creators
    )
    
    $message = "Starting array ($arraynum) $arrayname."
    Out-LogMessage

    $num = 0
    $results = New-Object System.Collections.ArrayList
    $resultsNoCre = New-Object System.Collections.ArrayList
    $itemsInArray = $arraytoparse.Count 
    $itemscounted = 0

    foreach ($item in $arraytoparse) {        
        $num++
        $itemscounted++
        Write-Progress -activity "Checking files against $arrayname array" -ID 4 -ParentId 1 -status "Checked: $itemscounted of $itemsinarray" -percentComplete (($itemscounted / $itemsinarray)  * 100) #the part / the whole

        $resultChildren = Get-ChildItem $folderToSort -Depth 0 -File | Where-Object { $_.BaseName -ilike "*$($item.Type)*" }

        if ($lastresults) {
            
        } else {
            $lastresults = $resultChildren
        }        
        
        $message = "$arrayname ($arraynum): Processing item $itemscounted/$itemsInArray - $($item.Type)."
        Out-LogMessage

        foreach ($result in $resultChildren) {
            $toAdd = "" | Select-Object "Package", "PackageLoc", "Match", "Destination"
            $message = "Adding $($result.Name) to primary results."
            Out-LogMessage
            $toAdd.Package = $result.Name
            $message = "Base name of $($result.Name) added."
            Out-LogMessage
            $toAdd.PackageLoc = $result.FullName
            $message = "Location of $($result.Name) added."
            Out-LogMessage
            $toAdd.Match = $item.Type
            $message = "Outlier of $($result.Name) added."
            Out-LogMessage
            $toAdd.Destination = $item.Folder
            $message = "Destination of $($result.Name) added."
            Out-LogMessage
            $resultsNoCre.Add($toAdd) | Out-Null
        }
        $message = "$arrayname ($arraynum): Finished processing item $itemscounted/$itemsInArray - $($item.Type)."
        Out-LogMessage
    }

    $message = "Checking for matching creators in array."
    Out-LogMessage

    $crecount = $creatorCollection.Count
    $resultscount = $resultsNoCre.Count 
    $resultscheck = 0
    $foundcreator= @()
    foreach ($result in $resultsNoCre) {
        $resultscheck++
        Write-Progress -activity "Looking for matching creators" -ID 5 -ParentId 4 -status "Files: $resultscheck of $resultscount" -percentComplete (($resultscheck / $resultscount)  * 100) #the part / the whole
        $crecheck=0
        for ($c=0; $creatorCollection.Count -gt $c; $c++) {
            $crecheck++
            Write-Progress -activity "Checking creator names against files" -ID 8 -ParentId 5 -status "Checked: $crecheck of $crecount" -percentComplete (($crecheck / $crecount)  * 100) #the part / the whole            
            if ($result.Package -ilike "*$($($creatorCollection.Creator[$c]))*") {
                $message = "Matched $($result.Package) to $($($creatorCollection.Creator[$c])). Adding to array."
                Out-LogMessage
                $toAdd = "" | Select-Object "Package", "PackageLoc", "Match", "Destination", "Creator"
                $message = "Adding $($result.Package) to final results."
                Out-LogMessage
                $toAdd.Package = $result.Package
                $message = "Base name of $($result.Package) added."
                Out-LogMessage
                $toAdd.PackageLoc = $result.PackageLoc
                $message = "Location of $($result.Package) added."
                Out-LogMessage
                $toAdd.Match = $result.Match
                $message = "Outlier of $($result.Package) added."
                Out-LogMessage
                $toAdd.Destination = $result.Destination
                $message = "Destination of $($result.Package) added."
                Out-LogMessage
                $toAdd.Creator = $creatorCollection.Creator[$c]
                $message = "Matching creator of $($($creatorCollection.Creator[$c])) added."
                Out-LogMessage
                $results.Add($toAdd) | Out-Null
                $foundcreator += $result
                Continue
            } elseif ($crecheck -ge $crecount) {
                $message = "No creator could be found. Adding to list without a creator."
                Out-LogMessage
                $toAdd = "" | Select-Object "Package", "PackageLoc", "Match", "Destination", "Creator"
                $message = "Adding $($result.Package) to final results."
                Out-LogMessage
                $toAdd.Package = $result.Package
                $message = "Base name of $($result.Package) added."
                Out-LogMessage
                $toAdd.PackageLoc = $result.PackageLoc
                $message = "Location of $($result.Package) added."
                Out-LogMessage
                $toAdd.Match = $result.Match
                $message = "Outlier of $($result.Package) added."
                Out-LogMessage
                $toAdd.Destination = $result.Destination
                $message = "Destination of $($result.Package) added."
                Out-LogMessage
                $results.Add($toAdd) | Out-Null
                Continue
            }        
            
        }
    }
    Write-Progress -activity "Checking files against $arrayname array" -ID 4 -ParentId 1 -status "Checked: $itemscounted of $itemsinarray" -percentComplete (($itemscounted / $itemsinarray)  * 100) -Completed #the part / the whole
    Write-Progress -activity "Looking for matching creators" -ID 5 -ParentId 4 -status "Files: $resultscheck of $resultscount" -percentComplete (($resultscheck / $resultscount)  * 100) -Completed #the part / the whole
    Write-Progress -activity "Checking creator names against files" -ID 8 -ParentId 5 -status "Checked: $crecheck of $crecount" -percentComplete (($crecheck / $crecount)  * 100) -Completed #the part / the whole            
    $message = "Moving files."
    Out-LogMessage
    Initialize-MoveFiles $results
}

Function Initialize-FinalCheck {
    param (
        [System.Collections.ArrayList]$arraytoparse,
        [string]$arrayname,
        [int]$arraynum,
        [switch]$creators
    )    
    
    $message = "Checking remaining files against creator names."
    Out-LogMessage

    $num = 0
    $itemsInArray = $arraytoparse.Count 
    $itemscounted = 0

    foreach ($item in $arraytoparse){
        Write-Progress -activity "Running Final Checks" -ID 6 -ParentId 1 -status "Checked: $itemscounted of $itemsinarray" -percentComplete (($itemscounted / $itemsinarray)  * 100) #the part / the whole
        $num++
        $itemscounted++
        
        $resultChildren = Get-ChildItem $folderToSort -Depth 0 -File | Where-Object { $_.BaseName -ilike "*$($item.Creator)*" }
        
        $message = "$arrayname ($arraynum): Processing item $itemscounted/$itemsInArray - $($item.Creator)."
        Out-LogMessage        

        foreach ($result in $resultChildren) {
            $toAdd = "" | Select-Object "Package", "PackageLoc", "Match", "Destination"
            $message = "Adding $($result.Name) to primary results."
            Out-LogMessage
            $toAdd.Package = $result.Name
            $message = "Base name of $($result.BaseName) added."
            Out-LogMessage
            $toAdd.PackageLoc = $result.FullName
            $message = "Location of $($result.BaseName) added."
            Out-LogMessage
            $toAdd.Match = $item.Type
            $message = "Outlier of $($result.BaseName) added."
            Out-LogMessage
            $toAdd.Destination = "$folderToSort\Manual Sort"
            $message = "Destination of $($result.BaseName) added."
            Out-LogMessage
            $results.Add($toAdd) | Out-Null
        }
        $message = "$arrayname ($arraynum): Finished processing item $itemscounted/$itemsInArray - $($item.Type)."
        Out-LogMessage
    }

    $message = "Moving files."
    Out-LogMessage
    Initialize-MoveFiles $results

    $message = "Finding final files."
    Out-LogMessage

    $residuals = Get-ChildItem $folderToSort -Depth 0 -File

    $message = "$($results.Count) files to be moved."

    $amountremaining = $residuals.Count
    $moved=0

    foreach ($residual in $residuals) {
        Write-Progress -activity "Moving The Final Files" -ID 7 -ParentId 6 -status "Moved: $moved of $amountremaining" -percentComplete (($moved / $amountremaining)  * 100) #the part / the whole
        Move-Item -Path $residual.FullName -Destination "$folderToSort\Manual Sort" 
        $moved++
    }
    Write-Progress -activity "Running Final Checks" -ID 6 -ParentId 1 -status "Checked: $itemscounted of $itemsinarray" -percentComplete (($itemscounted / $itemsinarray)  * 100) -Completed #the part / the whole
    Write-Progress -activity "Moving The Final Files" -ID 7 -ParentId 6 -status "Moved: $moved of $amountremaining" -percentComplete (($moved / $amountremaining)  * 100) -Completed #the part / the whole
}

################################

$startingVars = Get-Variable

$starttime = Get-Date -Format "MM/dd/yyyy HH:mm K"

###########VARS###############
$ProgressPreference = 'Continue'
$PSStyle.Progress.View = 'Minimal'

$yesNoQuestion = "&Yes", "&No"
$cleanUpFileNames = $Host.UI.PromptForChoice("File Names", "Clean file names up?", $yesNoQuestion, 1)

$debug = $Host.UI.PromptForChoice("Debug", "Run in debug (verbose) mode?", $yesNoQuestion, 1)

if ($debug -eq 0){
    $VerbosePreference = "Continue"
} else {
    $VerbosePreference = "SilentlyContinue"
}

$folderToSort = <#"M:\The Sims 4 (Documents)\!UnmergedCC\testingfolder"#> Read-Host -prompt "Location of Unsorted Folder"
$generalCC = "$folderToSort\General\Unmerged_CC"
$modernCC = "$folderToSort\Modern\Unmerged_CC"

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
    $logbakExists = Test-Path "$foldertosort\Output.log.bak"
    $logexists = Test-Path "$foldertosort\Output.log"
    if ($logbakExists -eq $true) {
        Remove-Item "$folderToSort\Output.log.bak" -Force | Out-Null
    }
    if ($logexists -eq $true) {
        Rename-Item $logfile "Output.log.bak" -Force -PassThru | Out-Null
    }    
    New-Item $logfile -ItemType file | Out-Null

$CSV = Import-CSV ".\Sims4SortCC.csv"
$message = "Imported CSV"
Out-LogMessage

$outlierCollection = New-Object System.Collections.ArrayList
$typeCollection = New-Object System.Collections.ArrayList
$historicalCollection = New-Object System.Collections.ArrayList
$recoloristCollection = New-Object System.Collections.ArrayList
$creatorCollection = New-Object System.Collections.ArrayList

for ($lineCounter=0; $CSV.Outliers.Count -gt $lineCounter; $lineCounter++){
    if ($CSV.Outliers[$lineCounter] -notlike ''){
        $toAdd = "" | Select-Object "Type", "Folder", "Length"
        $toAdd.Type = Invoke-Expression """$($CSV.Outliers[$lineCounter])"""
        $length = Invoke-Expression """$($CSV.Outliers[$lineCounter])"""
        $toAdd.Folder = Invoke-Expression """$($CSV.OutlierFolders[$lineCounter])"""
        $toAdd.Length = $length.Length
        $outlierCollection.Add($toAdd) | Out-Null
    }
}
$message = "Imported outliers list."
Out-LogMessage

for ($lineCounter=0; $CSV.Recolorists.Count -gt $lineCounter; $lineCounter++){
    if ($CSV.Recolorists[$lineCounter] -notlike ''){
        $toAdd = "" | Select-Object "Type", "Folder", "Length"
        $toAdd.Type = Invoke-Expression """$($CSV.Recolorists[$lineCounter])"""
        $length = Invoke-Expression """$($CSV.Recolorists[$lineCounter])"""
        $toAdd.Folder = Invoke-Expression """$($CSV.FoldersforRecolorists[$lineCounter])"""
        $toAdd.Length = $length.Length        
        $recoloristCollection.Add($toAdd) | Out-Null
    }
}
$message = "Imported recolorist list."
Out-LogMessage

for ($lineCounter=0; $CSV.Historicals.Count -gt $lineCounter; $lineCounter++){
    if ($CSV.Historicals[$lineCounter] -notlike ''){
        $toAdd = "" | Select-Object "Type", "Folder", "Length"
        $toAdd.Type = Invoke-Expression """$($CSV.Historicals[$lineCounter])"""
        $length = Invoke-Expression """$($CSV.Historicals[$lineCounter])"""
        $toAdd.Folder = Invoke-Expression """$($CSV.HistoricalFolders[$lineCounter])"""
        $toAdd.Length = $length.Length        
        $historicalCollection.Add($toAdd) | Out-Null
    }
}
$message = "Imported historicals list."
Out-LogMessage

for ($lineCounter=0; $CSV.Types.Count -gt $lineCounter; $lineCounter++){
    if ($CSV.Types[$lineCounter] -notlike ''){
        $toAdd = "" | Select-Object "Type", "Folder", "Length"
        $toAdd.Type = Invoke-Expression """$($CSV.Types[$lineCounter])"""
        $toAdd.Folder = Invoke-Expression """$($CSV.FoldersforType[$lineCounter])"""
        $length = Invoke-Expression """$($CSV.Types[$lineCounter])"""
        $toAdd.Length = $length.Length
        $typeCollection.Add($toAdd) | Out-Null
    }
}
$message = "Imported types list."
Out-LogMessage 

for ($lineCounter=0; $CSV.Creators.Count -gt $lineCounter; $lineCounter++){
    if ($CSV.Creators[$lineCounter] -notlike ''){
        $toAdd = "" | Select-Object "Creator", "Length"
        $toAdd.Creator = Invoke-Expression """$($CSV.Creators[$lineCounter])"""
        $length = Invoke-Expression """$($CSV.Creators[$lineCounter])"""
        $toAdd.Length = $length.Length
        $creatorCollection.Add($toAdd) | Out-Null
    }
}
$message = "Imported types list."
Out-LogMessage 

$outlierCollection = $outlierCollection | Sort-Object -Property Type -Unique
$historicalCollection = $historicalCollection | Sort-Object -Property Type -Unique
$typeCollection = $typeCollection | Sort-Object -Property Type -Unique
$recoloristCollection = $recoloristCollection | Sort-Object -Property Type -Unique
$creatorCollection = $creatorCollection | Sort-Object -Property Creator -Unique

$outlierCollection = $outlierCollection | Sort-Object -Property Length -Descending
$historicalCollection = $historicalCollection | Sort-Object -Property Length -Descending
$typeCollection = $typeCollection | Sort-Object -Property Length -Descending
$recoloristCollection = $recoloristCollection | Sort-Object -Property Length -Descending
$creatorCollection = $creatorCollection | Sort-Object -Property Length -Descending


$message = "Reordered lists."
Out-LogMessage
$stages=1
if ($cleanUpFileNames -eq 0) {    
    $todo = 6

    Write-Progress -activity "Running through stages" -ID 1 -status "Progress: Stage $stages of $todo" -percentComplete (($stages / $todo)  * 100)
    
    $message = "Tidying the file names!"
    Out-LogMessage
    Initialize-TidyCharacters -folderToSort $folderToSort

    $stages++
    Write-Progress -activity "Running through stages" -ID 1 -status "Progress: Stage $stages of $todo" -percentComplete (($stages / $todo)  * 100)

    $message = "Starting first array."
    Out-LogMessage
    Initialize-ParseCheckerArray -arraytoparse $outlierCollection -arrayname "Outliers" -arraynum 1 -creatorCollection $creatorCollection
    $message = "First array complete."
    Out-LogMessage

    $stages++
    Write-Progress -activity "Running through stages" -ID 1 -status "Progress: Stage $stages of $todo" -percentComplete (($stages / $todo)  * 100)

    $message = "Starting second array."
    Out-LogMessage
    Initialize-ParseCheckerArray -arraytoparse $historicalCollection -arrayname "Historicals" -arraynum 2 -creatorCollection $creatorCollection
    $message = "Second array complete."
    Out-LogMessage

    $stages++
    Write-Progress -activity "Running through stages" -ID 1 -status "Progress: Stage $stages of $todo" -percentComplete (($stages / $todo)  * 100)

    $message = "Starting third array."
    Out-LogMessage
    Initialize-ParseCheckerArray -arraytoparse $recoloristCollection -arrayname "Recolorists" -arraynum 3 -creatorCollection $creatorCollection
    $message = "Third array complete."
    Out-LogMessage

    $stages++
    Write-Progress -activity "Running through stages" -ID 1 -status "Progress: Stage $stages of $todo" -percentComplete (($stages / $todo)  * 100)

    $message = "Starting fourth array."
    Out-LogMessage
    Initialize-ParseCheckerArray -arraytoparse $typeCollection -arrayname "Types" -arraynum 4 -creatorCollection $creatorCollection
    $message = "Fourth array complete."
    Out-LogMessage

    $message = "Initializing final check."
    Out-LogMessage
    Initialize-FinalCheck -arraytoparse $creatorCollection -arrayname "Types" -arraynum 5 -creatorCollection $creatorCollection
    $message = "Final check complete."
    Out-LogMessage

    Write-Progress -activity "Running through stages" -ID 1 -status "Progress: Stage $stages of $todo" -percentComplete (($stages / $todo)  * 100)

} else {
    $todo = 5
    Write-Progress -activity "Running through stages" -ID 1 -status "Progress: Stage $stages of $todo" -percentComplete (($stages / $todo)  * 100)
    $message = "Starting first array."
    Out-LogMessage
    Initialize-ParseCheckerArray -arraytoparse $outlierCollection -arrayname "Outliers" -arraynum 1 -creatorCollection $creatorCollection
    $message = "First array complete."
    Out-LogMessage

    $stages++
    Write-Progress -activity "Running through stages" -ID 1 -status "Progress: Stage $stages of $todo" -percentComplete (($stages / $todo)  * 100)

    $message = "Starting second array."
    Out-LogMessage
    Initialize-ParseCheckerArray -arraytoparse $historicalCollection -arrayname "Historicals" -arraynum 2 -creatorCollection $creatorCollection
    $message = "Second array complete."
    Out-LogMessage

    $stages++
    Write-Progress -activity "Running through stages" -ID 1 -status "Progress: Stage $stages of $todo" -percentComplete (($stages / $todo)  * 100)

    $message = "Starting third array."
    Out-LogMessage
    Initialize-ParseCheckerArray -arraytoparse $recoloristCollection -arrayname "Recolorists" -arraynum 3 -creatorCollection $creatorCollection
    $message = "Third array complete."
    Out-LogMessage

    $stages++
    Write-Progress -activity "Running through stages" -ID 1 -status "Progress: Stage $stages of $todo" -percentComplete (($stages / $todo)  * 100)

    $message = "Starting fourth array."
    Out-LogMessage
    Initialize-ParseCheckerArray -arraytoparse $typeCollection -arrayname "Types" -arraynum 4 -creatorCollection $creatorCollection
    $message = "Fourth array complete."
    Out-LogMessage

    $message = "Initializing final check."
    Out-LogMessage
    Initialize-FinalCheck -arraytoparse $creatorCollection -arrayname "Types" -arraynum 5 -creatorCollection $creatorCollection
    $message = "Final check complete."
    Out-LogMessage

    $stages++
    Write-Progress -activity "Running through stages" -ID 1 -status "Progress: Stage $stages of $todo" -percentComplete (($stages / $todo)  * 100)
}



$endtime = Get-Date -Format "MM/dd/yyyy HH:mm K"
$message = "Sorting started at $starttime and ended at $endtime."
Out-LogMessage



Out-Script
