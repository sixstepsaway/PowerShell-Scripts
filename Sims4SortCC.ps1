
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

Function Initialize-MoveFiles ($results) {
    $foldersToMake = @()

    foreach ($file in $results) {
        $foldersToMake += $results.Destination
    }

    $foldersToMake = $foldersToMake | Sort-Object -Unique

    foreach ($folder in $foldersToMake) {
        New-Item -ItemType Directory $folder
    }

    foreach ($file in $results) {
        Move-Item -Path $file.PackageLoc -Destination "$($file.Destination)\$($file.Package)"
    }

}

Function Initialize-ParseCheckerArray {
    param (
        [System.Collections.ArrayList]$arraytoparse
    )
    $num = 0
    $results = New-Object System.Collections.ArrayList
    foreach ($item in $arraytoparse) {
        $num++
        $resultChildren = Get-ChildItem $folderToSort | Where-Object { $_.BaseName -ilike "*$($item.Type)*" }
        #$resultChildren
        foreach ($result in $resultChildren) {
            $toAdd = "" | Select-Object "Package", "PackageLoc", "Match", "Destination"
            Write-Verbose "Adding $($result.Name) to results."
            $toAdd.Package = $result.Name
            Write-Verbose "Base name of $($result.BaseName) added."
            $toAdd.PackageLoc = $result.FullName
            Write-Verbose "Location of $($result.BaseName) added."
            $toAdd.Match = $item.Type
            Write-Verbose "Outlier of $($result.BaseName) added."
            $toAdd.Destination = $item.Folder
            Write-Verbose "Destination of $($result.BaseName) added."
            $results.Add($toAdd) | Out-Null
        }
    }
    #Initialize-MoveFiles 
    $results
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
Write-Verbose "Imported CSV"

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
Write-Verbose "Imported outliers list."

for ($lineCounter=0; $CSV.Recolorists.Count -gt $lineCounter; $lineCounter++){
    if ($CSV.Recolorists[$lineCounter] -notlike ''){
        $toAdd = "" | Select-Object "Type", "Folder"
        $toAdd.Type = Invoke-Expression """$($CSV.Recolorists[$lineCounter])"""
        $toAdd.Folder = Invoke-Expression """$($CSV.FoldersforRecolorists[$lineCounter])"""
        $recoloristCollection.Add($toAdd) | Out-Null
    }
}
Write-Verbose "Imported recolorist list."

for ($lineCounter=0; $CSV.Historicals.Count -gt $lineCounter; $lineCounter++){
    if ($CSV.Historicals[$lineCounter] -notlike ''){
        $toAdd = "" | Select-Object "Type", "Folder"
        $toAdd.Type = Invoke-Expression """$($CSV.Historicals[$lineCounter])"""
        $toAdd.Folder = Invoke-Expression """$($CSV.HistoricalFolders[$lineCounter])"""
        $historicalCollection.Add($toAdd) | Out-Null
    }
}
Write-Verbose "Imported historicals list."

for ($lineCounter=0; $CSV.Types.Count -gt $lineCounter; $lineCounter++){
    if ($CSV.Types[$lineCounter] -notlike ''){
        $toAdd = "" | Select-Object "Type", "Folder"
        $toAdd.Type = Invoke-Expression """$($CSV.Types[$lineCounter])"""
        $toAdd.Folder = Invoke-Expression """$($CSV.FoldersforType[$lineCounter])"""
        $typeCollection.Add($toAdd) | Out-Null
    }
}
Write-Verbose "Imported types list."

$outlierCollection = $outlierCollection | Sort-Object -Property Length -Descending
$historicalCollection = $historicalCollection | Sort-Object -Property Length -Descending
$typeCollection = $typeCollection | Sort-Object -Property Length -Descending
$recoloristCollection = $recoloristCollection | Sort-Object -Property Length -Descending
$outlierCollection = $outlierCollection | Sort-Object -Property Length -Descending

$folderWithPackages = Get-ChildItem $folderToSort

Initialize-ParseCheckerArray -arraytoparse $outlierCollection

#$typeCollection.GetType()

#Initialize-Autosorting

Out-Script
