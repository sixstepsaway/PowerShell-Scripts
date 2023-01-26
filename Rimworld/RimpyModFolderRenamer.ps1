Function Out-Script {
    Write-Host "Finishing up."
    $endingVars = Get-Variable
    Remove-Variable $endingVars -Exclude $startingVars
    Exit
}

Function Start-RenameFoldersFromXML {
    param (
        [string]$location
    )
    $folderList = Get-ChildItem $location -Directory
    $matchlist = @("."
    ":"
    "*"
    "|"
    "?"
    "!"
    "/"
    <#to add another match to this list, simply hit enter after the last match (for example: "/") and add your own in double quotes (for example: "^"). This character will be removed from any file names.#>)
    $replacelist = ""

    $numberOfSubFolders = $folderList.Count
    foreach ($folder in $folderList) {
        $Completed = ($i/$numberOfSubFolders) * 100
        Write-Progress -Id 1 -Activity "Parsing Folders" -Status "Progress: " -PercentComplete $Completed
        Write-Verbose "Parsing $($folder.BaseName)."
        [xml]$xml = Get-Content "$folder\About\About.xml"
        Write-Verbose "Parsing XML at $folder\About\About.xml."
        $newName = $xml.ModMetaData.name
        for ($i=0; $matchlist.Count -gt $i; $i++) {
            $newName = $newName -replace [regex]::Escape($matchlist[$i]),$replacelist
        }
        Write-Verbose "New name will be $newName."
        if ($debugMode -eq 0) {
            Rename-Item $folder -NewName $newName -WhatIf
            Write-Verbose "File has not been renamed as script is running in debug mode."
        } else {
            Rename-Item $folder -NewName $newName
        }
        Continue
    }
}

$startingVars = Get-Variable
$PSStyle.Progress.View = 'Minimal'

$yesNoQuestion = "&Yes", "&No"

$debugMode = $Host.UI.PromptForChoice("Debug", "Run in debug mode?", $yesNoQuestion, 1)

if ($debugMode -eq 0) {
    $VerbosePreference = "Continue"
    Write-Verbose "This script is running in debug mode. No real changes will be made to your folders."
} else {
    $VerbosePreference = "SilentlyContinue"
}

$alreadySubfolders = $Host.UI.PromptForChoice("Subfolders", "Are your files already in subfolders? (For example you're linking to a folder containing folders such as `"Factions`" and `"Scenarios`" and within those folders live the numbered workshop folders.)", $yesNoQuestion, 1)

if ($alreadySubfolders -eq 1) {
    $foldertoparse = Read-Host "Where is the folder full of folders? (For example: C:\Games\Rimworld\Mods)"
    Start-RenameFoldersFromXML -location $foldertoparse
} elseif ($alreadySubfolders -eq 0) {
    $foldertoparse = Read-Host "Where is the folder full of semi-organized folders? (For example: C:\Games\Rimworld\Mods which contains folders like `"Factions`" and `"Animals`")"
    $foldertoparse = Get-ChildItem "C:\GOG Games\Mods Organized"
    $NumberOfFolders = $folderthatcontainsfolders.Count
    foreach ($folder in $foldertoparse) {    
        $Completed = ($i/$NumberOfFolders) * 100
        Write-Progress -Id 0 -Activity "Parsing Containing Folders" -Status "Progress: " -PercentComplete $Completed
        Write-Host "Sending $($folder.BaseName) to function."
        Start-RenameFoldersFromXML -location $folder
    }
}

if ($debugMode -eq 0) {
    Write-Verbose "Console paused so you can check for errors."
    Pause
}

Out-Script
