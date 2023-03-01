Function Out-Script {
    Write-Host "Finishing up."
    $endingVars = Get-Variable
    Remove-Variable $endingVars -Exclude $startingVars
    Exit
}

$startingVars = Get-Variable
$VerbosePreference = "Continue"

$rimworld = Read-Host -prompt "Where is your Rimworld install? (eg. C:\GOG Games\Rimworld 1.4)"

$newRimworldFolder = Read-Host -prompt "Where is the new Rimworld folder? (eg. C:\GOG Games\Rimworld - Multiplayer)"

$rwfolders = Get-ChildItem -Directory $rimworld

foreach ($folder in $rwfolders) {
    if ($folder.Name -eq "Mods") {
        Continue
    } else {
        New-Item -ItemType Junction -Path "$newRimworldFolder\$($folder.Name)" -Target "$folder"
    }
}

$rwfiles = Get-ChildItem -File $rimworld

foreach ($file in $rwfiles){
    if ($file.Extension -eq ".bat" -or $file.Extension -eq ".ps1") {
        Continue
    } else {
        New-Item -Itemtype SymbolicLink -Path "$newRimworldFolder\$($file.Name)" -Target "$file"
    }
}

Out-Script
