
<#foreach ($inputVid in $originalVids) {
    $outputVid = [io.path]::ChangeExtension($inputVid.FullName, '.mp4')
    ffmpeg.exe -i $inputVid.FullName -c:v libx264 -crf 18 -c:a aac -map_metadata 0 $outputVid
}#>


Function Start-RestrictedStandard {
    $videos = Get-ChildItem "$location\*.mkv"
    foreach ($video in $videos) {
        ffmpeg -threads 2 -i $video -map 0:a:0 "$location\Converted\$($video.BaseName).mp3" -map 0:a:1 "$location\Converted\$($video.BaseName).mp3" -map 0:a:2 "$location\Converted\$($video.BaseName).mp3" -map 0:a:3 "$location\Converted\$($video.BaseName).mp3" -map 0:a:4 "$location\Converted\$($video.BaseName).mp3" -map 0:a:5 "$location\Converted\$($video.BaseName).mp3"
	    ffmpeg -threads 2 -i $video $dolby2 "$location\Converted\$($video.BaseName).mp4"
	    ffmpeg -threads 2 -i $video -c:v libx264 -profile:v baseline -crf 16  -pix_fmt yuv420p -vf "$dolby,scale=640:360" -an "$location\Converted\Proxy\$($video.BaseName).mp4" 
    }
}
Function Start-UnlimitedStandard {
    $videos = Get-ChildItem "$location\*.mkv"
    foreach ($video in $videos) {
        ffmpeg -i $video -map 0:a:0 "$location\Converted\$($video.BaseName).mp3" -map 0:a:1 "$location\Converted\$($video.BaseName).mp3" -map 0:a:2 "$location\Converted\$($video.BaseName).mp3" -map 0:a:3 "$location\Converted\$($video.BaseName).mp3" -map 0:a:4 "$location\Converted\$($video.BaseName).mp3" -map 0:a:5 "$location\Converted\$($video.BaseName).mp3"
	    ffmpeg -i $video $dolby2 "$location\Converted\$($video.BaseName).mp4"
	    ffmpeg -i $video -c:v libx264 -profile:v baseline -crf 16  -pix_fmt yuv420p -vf "$dolby,scale=640:360" -an "$location\Converted\Proxy\$($video.BaseName)_PROXY.mp4" 
    }
}

Function Start-RestrictedComplex {
    $videos = Get-ChildItem "$location\*.mkv"
    foreach ($video in $videos) {
        ffmpeg -threads 2 -i "$video" -filter_complex "channelsplit=channel_layout=5.1[$letterMap01][$letterMap02][$letterMap03][$letterMap04][$letterMap05][$letterMap06]"	-map "[$letterMap01]" "$location\Converted\$($video.BaseName)___TRACK01.mp3" -map "[$letterMap02]" "$location\Converted\$($video.BaseName)___TRACK02.mp3" -map "[$letterMap03]" "$location\Converted\$($video.BaseName)___DIALOGUE.mp3" -map "[$letterMap04]" "$location\Converted\$($video.BaseName)___TRACK04.mp3" -map "[$letterMap05]" "$location\Converted\$($video.BaseName)___TRACK05.mp3" -map "[$letterMap06]" "$location\Converted\$($video.BaseName)___TRACK06.mp3"
	    ffmpeg -threads 2 -i $video $dolby2 "$location\Converted\$($video.BaseName).mp4"
	    ffmpeg -threads 2 -i $video -c:v libx264 -profile:v baseline -crf 16  -pix_fmt yuv420p -vf "$dolby,scale=640:360" -an "$location\Converted\Proxy\$($video.BaseName)_PROXY.mp4" 
    }
}

Function Start-UnlimitedComplex {
    $videos = Get-ChildItem "$location\*.mkv"
    foreach ($video in $videos) {
        ffmpeg -threads 2 -i "$video" -filter_complex "channelsplit=channel_layout=5.1[$letterMap01][$letterMap02][$letterMap03][$letterMap04][$letterMap05][$letterMap06]"	-map "[$letterMap01]" "$location\Converted\$($video.BaseName)___TRACK01.mp3" -map "[$letterMap02]" "$location\Converted\$($video.BaseName)___TRACK02.mp3" -map "[$letterMap03]" "$location\Converted\$($video.BaseName)___DIALOGUE.mp3" -map "[$letterMap04]" "$location\Converted\$($video.BaseName)___TRACK04.mp3" -map "[$letterMap05]" "$location\Converted\$($video.BaseName)___TRACK05.mp3" -map "[$letterMap06]" "$location\Converted\$($video.BaseName)___TRACK06.mp3"
	    ffmpeg -threads 2 -i $video $dolby2 "$location\Converted\$($video.BaseName).mp4"
	    ffmpeg -threads 2 -i $video -c:v libx264 -profile:v baseline -crf 16  -pix_fmt yuv420p -vf "$dolby,scale=640:360" -an "$location\Converted\Proxy\$($video.BaseName)_PROXY.mp4" 
    }
}

Function Start-MakeScreencapsRestricted {
    $videos = Get-ChildItem "$location\*.mkv"

    foreach ($video in $videos) {
        New-Item -Itemtype Directory "$location\Screencaps\$($video.BaseName)"
        $outputDir = "$location\Screencaps\$($video.BaseName)"
        ffmpeg -threads 8 -i "$video" -vf "$dolby,$data" -vsync 0 -q:v 6 "$outputDir\$($video.BaseName)_%03d.jpg"
    }
}
Function Start-MakeScreencaps {
    $videos = Get-ChildItem "$location\*.mkv"    
    foreach ($video in $videos) {
        $alreadyDone = Test-Path "$location\Screencaps\$($video.BaseName)"
        if ($alreadyDone -eq $true) {
            Continue
        } else {
            New-Item -Itemtype Directory "$location\Screencaps\$($video.BaseName)"
            $outputDir = "$location\Screencaps\$($video.BaseName)"
            ffmpeg -i "$video" -vf "$dolby,$data" -vsync 0 -q:v 6 "$outputDir\$($video.BaseName)_%03d.jpg"
        }
    }
}



Function Out-Script {
    Write-Host "Finishing up."
    $endingVars = Get-Variable
    Remove-Variable $endingVars -Exclude $startingVars
    Exit
}

$startingVars = Get-Variable

$yesNoQuestion = "&Yes", "&No"
$letterMappingsQuestion = "&Standard", "&Complex"
$conCapQuestion = "Con&vert", "&Caps"

$location = Read-Host -prompt "Where are the files?"

$restrictCPUChoice = $Host.UI.PromptForChoice("CPU", "Restrict CPU Threads?", $yesNoQuestion, 0)

$conCapChoice = $Host.UI.PromptForChoice("Type", "Conversion or Caps?", $conCapQuestion, 0)

$dummyChoice = $Host.UI.PromptForChoice("Dummy", "Run a dummy to get crop size?", $yesNoQuestion, 1)

$cropChoice = $Host.UI.PromptForChoice("Crop?", "Does the video need cropping?", $yesNoQuestion, 1)

$data = "select='not(mod(n\,10))'"

$dolbyChoice = $Host.UI.PromptForChoice("Dolby?", "Is the video Dolby colored?", $yesNoQuestion, 1)

if ($dolbyChoice = 0) {
    $dolby = "hwupload,tonemap_opencl=tonemap=bt2390:desat=0:peak=100:format=nv12,hwdownload,format=nv12"
} else {
    $dolby = ""
}

if ($cropChoice -eq 0) {
    $crop = Read-Host -prompt "Crop"
    if ($crop -eq "") {
        $data2 = "crop=3840:1920:0:120,$data"
        $data = $data2
    } else {
    $data2 = "$crop,$data"
    $data = $data2
    }
}

if ($dummyChoice -eq 0) {
    $videos = Get-ChildItem -File $location
    ffmpeg -ss 600 -i "$video[0]" -vf "cropdetect=24:16:0" "$location\dummy.mkv"
}

if ($conCapChoice -eq 0) {
    New-Item -ItemType Directory "$location\Converted"
    New-Item -ItemType Directory "$location\Converted\Proxy"
    $letterMappingsChoice = $Host.UI.PromptForChoice("Audio Map", "What kind of Audio Mapping?", $letterMappingsQuestion, 0)
    
    if ($dolby -eq "") {
        $dolby2 = ""
    } else {
        $dolby2 = "-vf `"$dolby`""
    }

    if ($letterMappingsChoice -eq 0) {
        $letterMappings = "Standard"
    }
    if ($letterMappingsChoice -eq 1) {
        $letterMappings = "Complex"
        $letterMappingsDefault = $Host.UI.PromptForChoice("Letters", "Use the default letter mappings?", $yesNoQuestion, 0)
        if ($letterMappingsDefault -eq 0)
        {
            $letterMap01 = "L"
            $letterMap02 = "R"
            $letterMap03 = "C"
            $letterMap04 = "LFE"
            $letterMap05 = "Ls"
            $letterMap06 = "Rs"
        }
        if ($letterMappingsDefault -eq 1) {
            $letterMap01 = Read-Host -prompt "Channel map letter 1?"
            $letterMap02 = Read-Host -prompt "Channel map letter 2?"
            $letterMap03 = Read-Host -prompt "Channel map letter 3?"
            $letterMap04 = Read-Host -prompt "Channel map letter 4?"
            $letterMap05 = Read-Host -prompt "Channel map letter 5?"
            $letterMap06 = Read-Host -prompt "Channel map letter 6?"
        }
    }

    Write-Host "Mappings are $letterMappings"

}

if ($typeChoice -eq 0) {
    if ($letterMappings -eq "Standard" -and $restrictCPUChoice -eq 0) {
        Start-RestrictedStandard
        Out-Script
    }
    if ($letterMappings -eq "Complex" -and $restrictCPUChoice -eq 0) {
        Start-RestrictedComplex
        Out-Script
    }
    if ($letterMappings -eq "Standard" -and $restrictCPUChoice -eq 1) {
        Start-UnlimitedStandard
        Out-Script
    }
    if ($letterMappings -eq "Complex" -and $restrictCPUChoice -eq 1) {
        Start-UnlimitedComplex
        Out-Script
    }
} 

if ($conCapChoice -eq 1) {
    if ($restrictCPUChoice -eq 0)
    {
        Start-MakeScreencapsRestricted
        Out-Script
    }
    if ($restrictCPUChoice -eq 1) {
        Start-MakeScreencaps
        Out-Script
    }
}
