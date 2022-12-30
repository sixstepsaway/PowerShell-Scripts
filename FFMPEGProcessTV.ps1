Function Out-Script {
    Write-Host "Finishing up."
    $endingVars = Get-Variable
    Remove-Variable $endingVars -Exclude $startingVars
    Exit
}



Function Start-MKVtoMP4 {
    param (       
        [switch]$dolby,
        [switch]$UHD,
        [switch]$HD,
        [switch]$sample,
        [switch]$crop,
        [string]$cropSize,
        [int]$threads,
        [string]$location,
        [object]$video
    )

    New-Item -Itemtype Directory "$location\Converted" -Force
    New-Item -Itemtype Directory "$location\Converted\Proxy" -Force

    if ($threads -gt 0) {
        $threadsSetting = "-threads $threads"
    }
    if ($sample) {
        $sampleSet = "-ss 00:10:00 -t 00:12:00"
    }

    if ($crop) {
        $cropping = $cropSize
    }

    if ($UHD) {
        if ($crop) {
            $mainSettings = "-fps_mode passthrough -vf $cropping,zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709:r=tv,format=yuv420p -c:v libx264 -crf 15 -r:v 30 -c:a copy -preset ultrafast -tune fastdecode -max_muxing_queue_size 1024"
            $proxySettings = "-fps_mode passthrough -vf $cropping,zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709:r=tv,format=yuv420p,zscale=640:360 -c:v libx264 -crf 25 -r:v 30 -c:a copy -preset ultrafast -tune fastdecode  -max_muxing_queue_size 1024"
        } else {
            $mainSettings = "-fps_mode passthrough -vf zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709:r=tv,format=yuv420p -c:v libx264 -crf 15 -r:v 30 -c:a copy -preset ultrafast -tune fastdecode -max_muxing_queue_size 1024"
            $proxySettings = "-fps_mode passthrough -vf zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709:r=tv,format=yuv420p -c:v libx264 -crf 25 -r:v 30 -c:a copy -preset ultrafast -tune fastdecode -max_muxing_queue_size 1024 `"scale=640:360`""
        }
        
    } elseif ($dolby) {
        if ($crop) {
            $mainSettings = "-fps_mode passthrough -c:v -c:v libx265 -crf 15 -vf `"$cropping,hwupload,tonemap_opencl=tonemap=bt2390:desat=0:peak=100:format=nv12,hwdownload,format=nv12`" -c:a copy"
            $proxySettings = "-fps_mode passthrough -c:v libx265 -crf 25 -profile:v baseline -pix_fmt yuv420p10le -vf `"scale=640:360,hwupload,tonemap_opencl=tonemap=bt2390:desat=0:peak=100:format=nv12,hwdownload,format=nv12,$cropping`" -c:a copy"
        } else {
            $mainSettings = "-fps_mode passthrough -c:v -c:v libx265 -crf 15 -vf `"hwupload,tonemap_opencl=tonemap=bt2390:desat=0:peak=100:format=nv12,hwdownload,format=nv12`" -c:a copy"
            $proxySettings = "-fps_mode passthrough -c:v libx265 -crf 25 -profile:v baseline -pix_fmt yuv420p10le -fps_mode passthrough -vf `"hwupload,tonemap_opencl=tonemap=bt2390:desat=0:peak=100:format=nv12,hwdownload,format=nv12,scale=640:360`" -c:a copy"
        }
        
    } elseif ($HD) {
        if ($crop) {
            $mainSettings = "-fps_mode passthrough -c:a copy $cropping"
            $proxySettings = "-fps_mode passthrough -c:v libx264 -profile:v baseline -crf 16  -pix_fmt yuv420p -vf `"$cropping,scale=640:360`" -c:a copy" 
        } else {
            $mainSettings = "-fps_mode passthrough -c:a copy"
            $proxySettings = "-fps_mode passthrough -c:v libx264 -profile:v baseline -crf 16  -pix_fmt yuv420p -vf `"scale=640:360`" -c:a copy" 
        }
        
    } else {
        Write-Host "No settings provided. Exiting."
        Exit
    }

    $existsAlready = Test-Path "$location\Converted\$($video.BaseName).mp4"

    if ($existsAlready -eq $true) {
        Write-Host "This file has already been at least partially converted."
    } else {
        $mainRun = "ffmpeg $sampleSet -i `"$video`" $mainSettings $threadsSetting `"$location\Converted\$($video.BaseName).mp4`" -y"
        $proxyRun = "ffmpeg $sampleSet -i `"$video`" $proxySettings $threadsSetting `"$location\Converted\Proxy\$($video.BaseName)_PROXY.mp4`" -y"

        Invoke-Expression $mainRun
        Invoke-Expression $proxyRun
    }
}

Function Start-ExtractAudio {
    param (
        [switch]$complex,
        [switch]$basic,
        [int]$threads,
        [array]$letterMapping,
        [string]$location,
        [switch]$sample,
        [object]$video
    )

    New-Item -Itemtype Directory "$location\Converted" -Force
    New-Item -Itemtype Directory "$location\Converted\Proxy" -Force

    if ($sample) {
        $sampleSet = "-ss 00:10:00 -t 00:12:00"
    }
    if ($complex) {
        if ($letterMapping) {
            #do not overwrite
        } else {
            $letterMapping = @("L", "R", "C", "LFE", "Ls", "Rs")
        }

        $audioMap = "-filter_complex `"channelsplit=channel_layout=5.1[$($letterMapping[0])][$($letterMapping[1])][$($letterMapping[2])][$($letterMapping[3])][$($letterMapping[4])][$($letterMapping[5])]`" -map `"[$($letterMapping[0])]`" `"$location\Converted\$($video.BaseName)___TRACK01.mp3`" -map `"[$($letterMapping[1])]`" `"$location\Converted\$($video.BaseName)___TRACK02.mp3`" -map `"[$($letterMapping[2])]`" `"$location\Converted\$($video.BaseName)___DIALOGUE.mp3`" -map `"[$($letterMapping[3])]`" `"$location\Converted\$($video.BaseName)___TRACK04.mp3`" -map `"[$($letterMapping[4])]`" `"$location\Converted\$($video.BaseName)___TRACK05.mp3`" -map `"[$($letterMapping[5])]`" `"$location\Converted\$($video.BaseName)___TRACK06.mp3`""

    } else {
        $audioMap = "-map 0:a:0 `"$location\Converted\$($video.BaseName)_TRACK01.mp3`" -map 0:a:1 `"$location\Converted\$($video.BaseName)_TRACK02.mp3`" -map 0:a:2 `"$location\Converted\$($video.BaseName)_TRACK03.mp3`" -map 0:a:3 `"$location\Converted\$($video.BaseName)_TRACK04.mp3`" -map 0:a:4 `"$location\Converted\$($video.BaseName)_TRACK05.mp3`" -map 0:a:5 `"$location\Converted\$($video.BaseName)_TRACK06.mp3`""
    }

    if ($threads -gt 0) {
        $threadsSetting = "-threads $threads "
    }

    $existsAlready = Test-Path "$location\Converted\$($video.BaseName)_TRACK01.mp3"

    if ($existsAlready -eq $true) {
        Write-Host "This file has already been at least partially converted."
    } else {
        $audioExtraction = "ffmpeg $sampleset -i `"$video`" $threadsSetting$audioMap"
        Invoke-Expression $audioExtraction
    }    
    #$audioExtraction

    
}

Function Start-MakeScreencaps {
    param (        
        [switch]$dolby,
        [switch]$UHD,
        [switch]$HD,
        [int]$threads,
        [string]$location,
        [string]$cropSize,
        [switch]$sample,
        [switch]$crop,
        [object]$video
    )

    if ($threads -gt 0) {
        $threadsSetting = "-threads $threads "
    }
    if ($sample) {
        $sampleSet = "-ss 00:10:00 -t 00:12:00"
    }

    if ($crop) {
        $cropping = $cropSize
    }

    if ($UHD) {
        if ($crop) {
            $screenSettings = "-vf $cropping,zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709:r=tv,format=yuv420p,select='not(mod(n\,10))'"
        } else {
            $screenSettings = "-vf zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709:r=tv,format=yuv420p,select='not(mod(n\,10))'"
        }
        
    } elseif ($dolby) {
        $screenSettings = "-vf `"hwupload,tonemap_opencl=tonemap=bt2390:desat=0:peak=100:format=nv12,hwdownload,format=nv12,select='not(mod(n\,10))'`""
    } elseif ($HD) {
        $screenSettings = "`"select='not(mod(n\,10))'`""
    }

    $alreadyExists = Test-Path "$location\Screencaps\$($video.BaseName)\*.jpg"

    if ($alreadyExists) {
        Write-Host "This file has already been at least partially converted."
    } else {
        New-Item -Itemtype Directory "$location\Screencaps"
        New-Item -Itemtype Directory "$location\Screencaps\$($video.BaseName)"

        $capsRun = "ffmpeg $sampleSet -i `"$video`" $screenSettings -vsync 0 -q:v 6 $threadsSetting`"$location\Screencaps\$($video.BaseName)\$($video.BaseName)_%03d.jpg`" -y"

        Invoke-Expression $capsRun
    }
}

Function Start-GetCrop {
    Param(
        [array]$videos,
        [switch]$widescreen,
        [switch]$square,
        [string]$location
    )
    $video = $videos[0]
    ffmpeg -ss "00:05:00" -t "00:10:00" -i "$video" -vf "cropdetect=24:16:0" "$location\croptest.mkv"
}

Function Start-TestCrop {
    Param(
        [object]$video,
        [string]$cropTest,
        [string]$location
    )
    New-Item -Itemtype Directory "$location\tests"
    ffmpeg -ss 00:10:00 -t 00:11:00 -i "$video" -vf $cropTest -sn "$location\tests\croptest-crop.mkv" -y
}

#FUNCTIONS ABOVE#

$startingVars = Get-Variable

#SCRIPT START#
Function Start-RunMultiple {
    $itemOneLoc = "H:\TV\House of the Dragon\Season 1"
    $itemOneEpisodes = Get-ChildItem "H:\TV\House of the Dragon\Season 1\*.mkv"
    
    $itemTwoLoc = "J:\TV\The Witcher\Season 1"
    $itemTwoEpisodes = Get-ChildItem "J:\TV\The Witcher\Season 1\*.mkv"

    $itemThreeLoc = "J:\TV\The Witcher\Season 2"
    $itemThreeEpisodes = Get-ChildItem "J:\TV\The Witcher\Season 2\*.mkv"

    $itemFourLoc = "H:\TV\Upright\Season 1"
    $itemFourEpisodes = "H:\TV\Upright\Season 1\*.mkv"

    $itemFiveLoc = "H:\TV\Upright\Season 2"
    $itemFiveEpisodes = "H:\TV\Upright\Season 2\*.mkv"

    $useThreads = 8

    foreach ($episode in $itemThreeEpisodes) { #WITCHER SEASON 2
        Start-MKVtoMP4 -cropSize $basicCrop -location $itemThreeLoc -video $episode -threads $useThreads -UHD -crop
        Start-ExtractAudio -Complex -location $itemThreeLoc -video $episode 
        Start-MakeScreencaps -location $itemThreeLoc -video $episode -cropSize $basicCrop -threads $useThreads -UHD -crop
    }

    foreach ($episode in $itemOneEpisodes) { #HOUSE OF THE DRAGON
        Start-MKVtoMP4 -cropSize $basicCrop -location $itemOneLoc -video $episode -threads $useThreads -UHD -crop
        Start-ExtractAudio -Complex -location $itemOneLoc -video $episode 
        Start-MakeScreencaps -location $itemOneLoc -video $episode -cropSize $basicCrop -threads $useThreads -UHD -crop
    }

    foreach ($episode in $itemTwoEpisodes) { #WITCHER SEASON 1
        Start-MKVtoMP4 -location $itemTwoLoc -video $episode -threads $useThreads -HD
        Start-ExtractAudio -Complex -location $itemTwoLoc -video $episode 
        Start-MakeScreencaps -location $itemTwoLoc -video $episode -threads $useThreads -HD
    }

    foreach ($episode in $itemFourEpisodes) { #UPRIGHT SEASON 1
        Start-MKVtoMP4 -location $itemFourLoc -video $episode -threads $useThreads -HD
        Start-ExtractAudio -Complex -location $itemFourLoc -video $episode 
        Start-MakeScreencaps -location $itemFourLoc -video $episode -threads $useThreads -HD
    }
    foreach ($episode in $itemFiveEpisodes) { #UPRIGHT SEASON 2
        Start-MKVtoMP4 -location $itemFiveLoc -video $episode -threads $useThreads -HD
        Start-ExtractAudio -Complex -location $itemFiveLoc -video $episode 
        Start-MakeScreencaps -location $itemFiveLoc -video $episode -threads $useThreads -HD
    }
}

$basicCrop = "crop=iw:in_h-2*120"
$customLetterMapping = @("L", "R", "C", "LFE", "Ls", "Rs")



Start-RunMultiple


#SCRIPT END#

Out-Script
