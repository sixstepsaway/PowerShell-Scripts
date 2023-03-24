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
            $mainSettings = "-vf $cropping,zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709:r=tv,format=yuv420p -c:v libx265 -r:v 30 -c:a copy -preset slow -tune fastdecode -max_muxing_queue_size 1024"
            $proxySettings = "-vf $cropping,zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709:r=tv,format=yuv420p,zscale=640:360 -c:v libx265 -r:v 30 -c:a copy -preset slow -tune fastdecode  -max_muxing_queue_size 1024"
        } else {
            $mainSettings = "-vf zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709:r=tv,format=yuv420p -c:v libx265 -r:v 30 -c:a copy -preset slow -tune fastdecode -max_muxing_queue_size 1024"
            $proxySettings = "-vf zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709:r=tv,format=yuv420p -c:v libx265 -r:v 30 -c:a copy -preset slow -tune fastdecode -max_muxing_queue_size 1024 `"scale=640:360`""
        }
        
    } elseif ($dolby) {
        if ($crop) {
            $mainSettings = "-c:v libx265 -vf `"$cropping,tonemap_opencl=tonemap=bt2390:desat=0:peak=100:format=nv12,hwdownload,format=nv12`" -c:a copy"
            $proxySettings = "-c:v libx265 -profile:v baseline -pix_fmt yuv420p10le -vf `"scale=640:360,tonemap_opencl=tonemap=bt2390:desat=0:peak=100:format=nv12,hwdownload,format=nv12,$cropping`" -c:a copy"
        } else {
            $mainSettings = "-c:v libx265 -vf `"hwupload,tonemap_opencl=tonemap=bt2390:desat=0:peak=100:format=nv12,hwdownload,format=nv12`" -c:a copy"
            $proxySettings = "-c:v libx265 -profile:v baseline -pix_fmt yuv420p10le -vf `"hwupload,tonemap_opencl=tonemap=bt2390:desat=0:peak=100:format=nv12,hwdownload,format=nv12,scale=640:360`" -c:a copy"
        }
        
    } elseif ($HD) {
        if ($crop) {
            $mainSettings = "-c:v libx265 -r:v 30 -c:a copy -preset slow -tune fastdecode -max_muxing_queue_size 1024 -vf $cropping"
            $proxySettings = "-c:v libx265 -profile:v baseline  -pix_fmt yuv420p -vf `"$cropping,scale=640:360`" -c:a copy" 
        } else {
            $mainSettings = " -c:v libx265 -r:v 30 -c:a copy -preset slow -tune fastdecode -max_muxing_queue_size 1024"
            $proxySettings = "-c:v libx265 -profile:v baseline  -pix_fmt yuv420p -vf `"scale=640:360`" -c:a copy" 
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
        $screenSettings = "-vf hwupload,tonemap_opencl=tonemap=bt2390:desat=0:peak=100:format=nv12,hwdownload,format=nv12,select='not(mod(n\,10))'"
    } elseif ($HD) {
        $screenSettings = "-vf select='not(mod(n\,10))'"
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

Function Start-MakeGifs {
    param (       
        [switch]$dolby,
        [switch]$UHD,
        [switch]$HD,
        [string]$gifStart,
        [string]$gifEnd,
        [switch]$crop,
        [string]$cropSize,
        [int]$threads,
        [string]$location,
        [object]$video,
        [string]$gifName
    )

    New-Item -Itemtype Directory "$location\Gifs" -Force

    if ($threads -gt 0) {
        $threadsSetting = "-threads $threads"
    }

    if ($crop) {
        $cropping = $cropSize
    }

    #$sampleSet = "-ss $gifStart -t $gifEnd"

    if ($UHD) {
        if ($crop) {
            $mainSettings = "-vf $cropping,zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709:r=tv,format=yuv420p,scale=640:360 -c:v libx265 -crf 15 -r:v 30 -c:a copy -preset slow -tune fastdecode -max_muxing_queue_size 1024"
        } else {
            $mainSettings = "-vf zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709:r=tv,format=yuv420p,scale=640:360 -c:v libx265 -crf 15 -r:v 30 -c:a copy -preset slow -tune fastdecode -max_muxing_queue_size 1024"
        }
        
    } elseif ($dolby) {
        if ($crop) {
            $mainSettings = "-c:v libx265 -crf 15 -vf $cropping,tonemap_opencl=tonemap=bt2390:desat=0:peak=100:format=nv12,hwdownload,format=nv12,scale=640:360 -c:a copy"
        } else {
            $mainSettings = "-c:v libx265 -crf 15 -vf hwupload,tonemap_opencl=tonemap=bt2390:desat=0:peak=100:format=nv12,hwdownload,format=nv12,scale=640:360 -c:a copy"
        }
        
    } elseif ($HD) {
        if ($crop) {
            $mainSettings = "-c:v libx265 -crf 15 -r:v 30 -c:a copy -preset slow -tune fastdecode -max_muxing_queue_size 1024 -vf $cropping,scale=640:360"
        } else {
            $mainSettings = " -c:v libx265 -crf 15 -r:v 30 -c:a copy -preset slow -tune fastdecode -max_muxing_queue_size 1024 -vf scale=640:360"
        }
        
    } else {
        Write-Host "No settings provided. Exiting."
        Exit
    }
    $mainRun = "ffmpeg $sampleSet -i `"$video`" $mainSettings $threadsSetting `"$location\Gifs\$gifName.mp4`" -y"

        Invoke-Expression $mainRun
}

#FUNCTIONS ABOVE#

$startingVars = Get-Variable

#SCRIPT START#

$video = Get-Item "K:\TV\Wednesday\Season 1\Wednesday.S01E01.Wednesdays.Child.is.Full.of.Woe.2160p.NF.WEB-DL.DDP5.1.Atmos.DV.HDR.H.265-APEX.mkv"
$videos = Get-ChildItem "K:\TV\Wednesday\Season 1"
$location = "K:\TV\Wednesday\Season 1"
$witcherCrop = "crop=3840:2160:0:0"
$basicCrop = "crop=iw:in_h-2*120"
$customLetterMapping = @("L", "R", "C", "LFE", "Ls", "Rs")
$croptest = "crop=3840:2000:0:0"
$useThreads = 0

$wednesday = Get-ChildItem "K:\TV\Wednesday\Season 1"
$medium = Get-ChildItem "H:\TV\Medium" -Directory
$witcher = Get-ChildItem "J:\TV\The Witcher" -Directory
$upright = Get-ChildItem "H:\TV\Upright" -Directory
$hotd = Get-ChildItem "H:\TV\House of the Dragon\Season 1"

foreach ($episode in $wednesday) {
    Start-MKVtoMP4 -cropSize $basicCrop -location $location -video $episode -threads $useThreads -UHD -crop
    Start-ExtractAudio -Complex -location $location -video $episode 
    Start-MakeScreencaps -location $location -video $episode -cropSize $basicCrop -threads $useThreads -UHD -crop
}

foreach ($folder in $medium) {
    $videos = Get-ChildItem $folder
    foreach ($episode in $videos) {
        Start-MKVtoMP4 -location $location -video $episode -threads $useThreads -UHD
        Start-ExtractAudio -Complex -location $location -video $episode 
        Start-MakeScreencaps -location $location -video $episode -threads $useThreads -UHD
    }
}

foreach ($folder in $witcher) {
    $videos = Get-ChildItem $folder
    foreach ($episode in $videos) {
        Start-MKVtoMP4 -location $location -video $episode -threads $useThreads -cropSize $witcherCrop -crop -UHD
        Start-ExtractAudio -Complex -location $location -video $episode 
        Start-MakeScreencaps -location $location -video $episode -threads $useThreads -cropSize $witcherCrop -crop -UHD
    }
}

foreach ($folder in $upright) {
    $videos = Get-ChildItem $folder
    foreach ($episode in $videos) {
        Start-MKVtoMP4 -location $location -video $episode -threads $useThreads -UHD
        Start-ExtractAudio -Complex -location $location -video $episode 
        Start-MakeScreencaps -location $location -video $episode -threads $useThreads -UHD
    }
}

foreach ($episode in $wednesday) {
    Start-MKVtoMP4 -cropSize $basicCrop -location $location -video $episode -threads $useThreads -UHD -crop
    Start-ExtractAudio -Complex -location $location -video $episode 
    Start-MakeScreencaps -location $location -video $episode -cropSize $basicCrop -threads $useThreads -UHD -crop
}


#SCRIPT END#

Out-Script
