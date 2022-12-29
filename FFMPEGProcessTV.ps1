Function Out-Script {
    Write-Host "Finishing up."
    $endingVars = Get-Variable
    Remove-Variable $endingVars -Exclude $startingVars
    Exit
}

Function Start-MKVtoMP4 {
    param (       
        [switch]$dolby,
        [switch]$4kStandard,
        [switch]$1080p,
        [int]$threads,
        [string]$location,        
        [object]$video
    )
    New-Item -Itemtype Directory "$location\Converted"
    New-Item -Itemtype Directory "$location\Converted\Proxy"

    if ($threads -gt 0) {
        $threadsSetting = "-threads $threads"
    } else {
        $threadsSetting = ""
    }

    if ($4kStandard) {
        $mainSettings = "-c:a copy -c:v libx265 -crf 16 -color_primaries bt2020 -color_trc smpte2084 -colorspace bt2020nc -profile:v main10 -pix_fmt yuv420p10le"
        $proxySettings = "-c:a copy -c:v libx265 -crf 30 -color_primaries bt2020 -color_trc smpte2084 -colorspace bt2020nc -profile:v baseline -pix_fmt yuv420p `"scale=640:360`""
    } elseif ($dolby) {
        $mainSettings = "c:a copy -c:v -c:v libx265 -crf 16 -vf `"hwupload,tonemap_opencl=tonemap=bt2390:desat=0:peak=100:format=nv12,hwdownload,format=nv12`""
        $proxySettings = "-c:a copy -c:v libx265 -crf 30 -profile:v baseline -pix_fmt yuv420p10le -vf `"hwupload,tonemap_opencl=tonemap=bt2390:desat=0:peak=100:format=nv12,hwdownload,format=nv12,scale=640:360`" -an"
    } elseif ($1080p) {
        $mainSettings = "-c:a copy"
        $proxySettings = "-c:a copy -c:v libx264 -profile:v baseline -crf 16  -pix_fmt yuv420p -vf `"scale=640:360`" -an" 
    }

    ffmpeg $threadsSetting -i "$video" $mainSettings "$location\Converted\Proxy\$($video.BaseName).mp4"
    ffmpeg $threadsSetting -i "$video" $proxySettings "$location\Converted\Proxy\$($video.BaseName)_PROXY.mp4"
}

Function Start-ExtractAudio {
    param (
        [switch]$complex,
        [switch]$basic,
        [int]$threads,
        [array]$letterMapping,
        [string]$location,
        [object]$video
    )

    if ($complex) {
        if ($letterMapping = 0) {
            $letterMapping[0] = "L"
            $letterMapping[1] = "R"
            $letterMapping[2] = "C"
            $letterMapping[3] = "LFE"
            $letterMapping[4] = "Ls"
            $letterMapping[5] = "Rs"
        }

        $audioMap = "-filter_complex `"channelsplit=channel_layout=5.1[${$letterMapping[0]}][${$letterMapping[1]}][${$letterMapping[2]}][${$letterMapping[3]}][${$letterMapping[4]}][${$letterMapping[5]}]`"	-map `"[${$letterMapping[0]}]`" `"$location\Converted\$($video.BaseName)___TRACK01.mp3`" -map `"[${$letterMapping[1]}]`" `"$location\Converted\$($video.BaseName)___TRACK02.mp3`" -map `"[${$letterMapping[2]}]`" `"$location\Converted\$($video.BaseName)___DIALOGUE.mp3`" -map `"[${$letterMapping[3]}]`" `"$location\Converted\$($video.BaseName)___TRACK04.mp3`" -map `"[${$letterMapping[4]}]`" `"$location\Converted\$($video.BaseName)___TRACK05.mp3`" -map `"[${$letterMapping[5]}]`" `"$location\Converted\$($video.BaseName)___TRACK06.mp3`""

    } else {
        $audioMap = "-map 0:a:0 `"$location\Converted\$($video.BaseName).mp3`" -map 0:a:1 `"$location\Converted\$($video.BaseName).mp3`" -map 0:a:2 `"$location\Converted\$($video.BaseName).mp3`" -map 0:a:3 `"$location\Converted\$($video.BaseName).mp3`" -map 0:a:4 `"$location\Converted\$($video.BaseName).mp3`" -map 0:a:5 `"$location\Converted\$($video.BaseName).mp3`""
    }

    if ($threads -gt 0) {
        $threadsSetting = "-threads $threads"
    } else {
        $threadsSetting = ""
    }

    ffmpeg $threadsSetting -i "$video" $audioMap

}

Function Start-MakeScreencaps {
    param (        
        [switch]$dolby,
        [switch]$4kStandard,
        [switch]$1080p,
        [int]$threads,
        [string]$location,
        [object]$video
    )

    if ($threads -gt 0) {
        $threadsSetting = "-threads $threads"
    } else {
        $threadsSetting = ""
    }

    if ($dolby) {
        $screenSettings = "-vf `"hwupload,tonemap_opencl=tonemap=bt2390:desat=0:peak=100:format=nv12,hwdownload,format=nv12,select='not(mod(n\,10))'`""
    } elseif ($4kStandard) {
        $screenSettings = "-color_primaries bt2020 -color_trc smpte2084 -colorspace bt2020nc -vf `"hwupload,tonemap_opencl=tonemap=bt2390:desat=0:peak=100:format=nv12,hwdownload,format=nv12,select='not(mod(n\,10))'`""
    } elseif ($1080p) {
        $screenSettings = "`"select='not(mod(n\,10))'`""
    }

    New-Item -Itemtype Directory "$location\Screencaps"
    New-Item -Itemtype Directory "$location\Screencaps\$($video.BaseName)"

    ffmpeg $threadsSetting -i "$video" $screenSettings -vsync 0 -q:v 6 "$location\Screencaps\$($video.BaseName)\$($video.BaseName)_%03d.jpg"
}





#FUNCTIONS ABOVE#

$startingVars = Get-Variable

#SCRIPT START#

$video = Get-Item "H:\TV\House of the Dragon\Season 1\House.of.the.Dragon.S01E01.2160p.HMAX.WEB-DL.x265.10bit.HDR.DDP5.1.Atmos-SMURF.mkv"

Start-MKVtoMP4 -location "H:\TV\House of the Dragon\Season 1\" -video $video -4kStandard





#SCRIPT END#

Out-Script
