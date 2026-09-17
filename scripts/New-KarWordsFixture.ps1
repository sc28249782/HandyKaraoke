[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$StageDir
)

$ErrorActionPreference = 'Stop'

function Add-Bytes {
    param(
        [System.Collections.Generic.List[byte]]$Target,
        [byte[]]$Bytes
    )
    $Target.AddRange($Bytes)
}

function Add-Ascii {
    param(
        [System.Collections.Generic.List[byte]]$Target,
        [string]$Text
    )
    Add-Bytes -Target $Target -Bytes ([System.Text.Encoding]::ASCII.GetBytes($Text))
}

function Add-UInt32BE {
    param(
        [System.Collections.Generic.List[byte]]$Target,
        [uint32]$Value
    )
    $bytes = [System.BitConverter]::GetBytes($Value)
    [Array]::Reverse($bytes)
    Add-Bytes -Target $Target -Bytes $bytes
}

function Add-VariableLength {
    param(
        [System.Collections.Generic.List[byte]]$Target,
        [uint32]$Value
    )
    $encoded = [System.Collections.Generic.List[byte]]::new()
    $encoded.Add([byte]($Value -band 0x7f))
    while ($Value -gt 0x7f) {
        $Value = $Value -shr 7
        $encoded.Add([byte](($Value -band 0x7f) -bor 0x80))
    }
    for ($i = $encoded.Count - 1; $i -ge 0; $i--) {
        $Target.Add($encoded[$i])
    }
}

function Add-MetaText {
    param(
        [System.Collections.Generic.List[byte]]$Track,
        [uint32]$Delta,
        [byte]$MetaType,
        [string]$Text
    )
    $textBytes = [System.Text.Encoding]::ASCII.GetBytes($Text)
    Add-VariableLength -Target $Track -Value $Delta
    $Track.Add(0xff)
    $Track.Add($MetaType)
    Add-VariableLength -Target $Track -Value $textBytes.Length
    Add-Bytes -Target $Track -Bytes $textBytes
}

function Add-ChannelEvent2 {
    param(
        [System.Collections.Generic.List[byte]]$Track,
        [uint32]$Delta,
        [byte]$Status,
        [byte]$Data1,
        [byte]$Data2
    )
    # This helper is only for MIDI events with two data bytes (for example,
    # Note On and Note Off). Program Change is intentionally not emitted here.
    Add-VariableLength -Target $Track -Value $Delta
    Add-Bytes -Target $Track -Bytes ([byte[]]($Status, $Data1, $Data2))
}

function Add-TimeSignature44 {
    param(
        [System.Collections.Generic.List[byte]]$Track,
        [uint32]$Delta
    )
    Add-VariableLength -Target $Track -Value $Delta
    Add-Bytes -Target $Track -Bytes ([byte[]](0xff, 0x58, 0x04, 0x04, 0x02, 0x18, 0x08))
}

function Add-EndOfTrack {
    param(
        [System.Collections.Generic.List[byte]]$Track,
        [uint32]$Delta
    )
    Add-VariableLength -Target $Track -Value $Delta
    Add-Bytes -Target $Track -Bytes ([byte[]](0xff, 0x2f, 0x00))
}

function Add-TrackChunk {
    param(
        [System.Collections.Generic.List[byte]]$File,
        [System.Collections.Generic.List[byte]]$Track
    )
    Add-Ascii -Target $File -Text 'MTrk'
    Add-UInt32BE -Target $File -Value ([uint32]$Track.Count)
    Add-Bytes -Target $File -Bytes $Track.ToArray()
}

$stage = (Resolve-Path -LiteralPath $StageDir).Path
$outputDirectory = Join-Path $stage 'Songs\KAR'
New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
$output = Join-Path $outputDirectory 'KAR-Words-FF01-Regression.kar'

$headerTrack = [System.Collections.Generic.List[byte]]::new()
Add-MetaText -Track $headerTrack -Delta 0 -MetaType 0x03 -Text 'Soft Karaoke'
Add-MetaText -Track $headerTrack -Delta 0 -MetaType 0x01 -Text '@KMIDI KARAOKE FILE'
Add-MetaText -Track $headerTrack -Delta 0 -MetaType 0x01 -Text '@V0100'
Add-VariableLength -Target $headerTrack -Value 0
Add-Bytes -Target $headerTrack -Bytes ([byte[]](0xff, 0x51, 0x03, 0x07, 0xa1, 0x20))
Add-TimeSignature44 -Track $headerTrack -Delta 0
Add-EndOfTrack -Track $headerTrack -Delta 0

$wordsTrack = [System.Collections.Generic.List[byte]]::new()
Add-MetaText -Track $wordsTrack -Delta 0 -MetaType 0x03 -Text 'Words'
Add-MetaText -Track $wordsTrack -Delta 0 -MetaType 0x01 -Text '\Words track test'
Add-MetaText -Track $wordsTrack -Delta 384 -MetaType 0x01 -Text '/Second line'
Add-MetaText -Track $wordsTrack -Delta 384 -MetaType 0x01 -Text '\Third line'
Add-MetaText -Track $wordsTrack -Delta 384 -MetaType 0x01 -Text ' finish'
Add-EndOfTrack -Track $wordsTrack -Delta 768

$musicTrack = [System.Collections.Generic.List[byte]]::new()
Add-MetaText -Track $musicTrack -Delta 0 -MetaType 0x03 -Text 'Regression tone'
Add-ChannelEvent2 -Track $musicTrack -Delta 0 -Status 0x90 -Data1 0x3c -Data2 0x40
Add-ChannelEvent2 -Track $musicTrack -Delta 192 -Status 0x80 -Data1 0x3c -Data2 0x00
Add-EndOfTrack -Track $musicTrack -Delta 1728

$file = [System.Collections.Generic.List[byte]]::new()
Add-Ascii -Target $file -Text 'MThd'
Add-UInt32BE -Target $file -Value 6
Add-Bytes -Target $file -Bytes ([byte[]](0x00, 0x01, 0x00, 0x03, 0x00, 0x60))
Add-TrackChunk -File $file -Track $headerTrack
Add-TrackChunk -File $file -Track $wordsTrack
Add-TrackChunk -File $file -Track $musicTrack

[System.IO.File]::WriteAllBytes($output, $file.ToArray())
Write-Host "Created KAR Words/FF 01 regression fixture: $output" -ForegroundColor Green
