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
        $Completed = ($i/$NumberOfFiles) * 100
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
}

Function Initialize-MoveFiles ($results) {
    $foldersToMake = @()

    $message = "Number of results: $($results.Count). Keeping only unique."
    Out-LogMessage
    
    $resultsDests = $results | Sort-Object -Property destination -Unique

    $message = "Unique results: $($resultsDests.Count)."
    Out-LogMessage

    $message = "Adding $($resultsDests.Count) results to list of folders to make."
    Out-LogMessage

    $filesCount = $resultsDests.Count
    $filesdone = 0
    
    foreach ($file in $resultsDests) {
        $filesdone++
        $message = "($filesdone/$filesCount) Adding $($file.Destination) to list. "
        Out-LogMessage
        $foldersToMake += $file.Destination
    }
    $message = "Results:"
    Out-LogMessage
    foreach ($re in $results) {
        $message = $re.Package
        Out-LogMessage
    }

    $foldersToMake = $foldersToMake | Sort-Object -Unique

    $message = "Folders we'll be making: "
    Out-LogMessage
    foreach ($f in $folderstomake) {
        $message = $f.Destination
        Out-LogMessage
    }

    foreach ($folder in $foldersToMake) {
        $message = "Creating folder: $folder."
        Out-LogMessage
        New-Item -ItemType Directory -Force $folder
    }

    $alreadymoved = @()
    foreach ($file in $results) {
        $message = "Now checking if $($file.BaseName) has already been moved."
        Out-LogMessage

        if ($alreadymoved -contains $file) {
            $message = "Found file in array. Continuing."
            Out-LogMessage
            Continue
        } else {
            $message = "File has not been moved."
            Out-LogMessage
            $message = "Moving $($file.PackageLoc) to $($file.Destination)\$($file.Package)."
            Out-LogMessage
            Move-Item -Path $file.PackageLoc -Destination "$($file.Destination)\$($file.Package)" 
            $message = "Flagging file as moved."
            Out-LogMessage
            $alreadymoved += $file
            $message = "Done! Continuing."
            Out-LogMessage
            Continue
        }
    }

}

Function Initialize-ParseCheckerArray {
    param (
        [System.Collections.ArrayList]$arraytoparse,
        [string]$arrayname,
        [int]$arraynum,
        [switch]$creators
    )
    
    $message = "Starting array ($arraynum) $arrayname."
    Out-LogMessage

    $num = 0
    $results = New-Object System.Collections.ArrayList
    $itemsInArray = $arraytoparse.Count 
    $itemscounted = 0

    foreach ($item in $arraytoparse) {
        $num++
        $itemscounted++
        if ($creators) {
            $resultChildren = Get-ChildItem $folderToSort -Depth 50 -File | Where-Object { $_.BaseName -ilike "*$($item.Type)*" }
        } else {
            $resultChildren = Get-ChildItem $folderToSort -Depth 0 -File | Where-Object { $_.BaseName -ilike "*$($item.Type)*" }
        }
        
        $message = "$arrayname ($arraynum): Processing item $itemscounted/$itemsInArray - $($item.Type)."
        Out-LogMessage

        foreach ($result in $resultChildren) {
            $toAdd = "" | Select-Object "Package", "PackageLoc", "Match", "Destination"
            $message = "Adding $($result.Name) to results."
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
            $toAdd.Destination = $item.Folder
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
}

################################

$startingVars = Get-Variable
$VerbosePreference = "Continue"
$starttime = Get-Date -Format "MM/dd/yyyy HH:mm K"

###########VARS###############
$PSStyle.Progress.View = 'Minimal'

$yesNoQuestion = "&Yes", "&No"
$cleanUpFileNames = $Host.UI.PromptForChoice("File Names", "Clean file names up?", $yesNoQuestion, 1)
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

$outlierCollection = $outlierCollection | Sort-Object -Property Type -Unique
$historicalCollection = $historicalCollection | Sort-Object -Property Type -Unique
$typeCollection = $typeCollection | Sort-Object -Property Type -Unique
$recoloristCollection = $recoloristCollection | Sort-Object -Property Type -Unique

$outlierCollection = $outlierCollection | Sort-Object -Property Length -Descending
$historicalCollection = $historicalCollection | Sort-Object -Property Length -Descending
$typeCollection = $typeCollection | Sort-Object -Property Length -Descending
$recoloristCollection = $recoloristCollection | Sort-Object -Property Length -Descending


$message = "Reordered lists."
Out-LogMessage

if ($cleanUpFileNames -eq 0) {
    $message = "Tidying the file names!"
    Out-LogMessage
    Initialize-TidyCharacters -folderToSort $folderToSort
}


$message = "Starting first array."
Out-LogMessage
Initialize-ParseCheckerArray -arraytoparse $outlierCollection -arrayname "Outliers" -arraynum 1
$message = "First array complete."
Out-LogMessage

$message = "Starting second array."
Out-LogMessage
Initialize-ParseCheckerArray -arraytoparse $historicalCollection -arrayname "Historicals" -arraynum 2
$message = "Second array complete."
Out-LogMessage

$message = "Starting third array."
Out-LogMessage
Initialize-ParseCheckerArray -arraytoparse $recoloristCollection -arrayname "Recolorists" -arraynum 3
$message = "Third array complete."
Out-LogMessage

$message = "Starting fourth array."
Out-LogMessage
Initialize-ParseCheckerArray -arraytoparse $typeCollection -arrayname "Types" -arraynum 4
$message = "Fourth array complete."
Out-LogMessage

$endtime = Get-Date -Format "MM/dd/yyyy HH:mm K"
$message = "Sorting started at $starttime and ended at $endtime."
Out-LogMessage

Out-Script
