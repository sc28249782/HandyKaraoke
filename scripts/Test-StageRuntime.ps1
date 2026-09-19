[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$StageDir
)

$ErrorActionPreference = 'Stop'

$stage = (Resolve-Path -LiteralPath $StageDir).Path

$requiredFiles = @(
    'HandyKaraoke.exe',
    'Style.ini',
    'HandyKaraoke-SafeMode.cmd',
    'HandyKaraoke-ResetSettings.cmd',
    'bass.dll',
    'bassmidi.dll',
    'bass_fx.dll',
    'bassmix.dll',
    'bass_vst.dll',
    'WinSparkle.dll',
    'languages\en.qm',
    'platforms\qwindows.dll',
    'sqldrivers\qsqlite.dll'
)

$requiredDirectories = @(
    'Songs',
    'Songs\KAR',
    'Songs\NCN\Song',
    'Songs\NCN\Lyrics',
    'Songs\NCN\Cursor',
    'Songs\HNK',
    'SoundFonts',
    'VST'
)

$missing = [System.Collections.Generic.List[string]]::new()

foreach ($relativePath in $requiredFiles) {
    $path = Join-Path $stage $relativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $missing.Add("file: $relativePath")
    }
}

foreach ($relativePath in $requiredDirectories) {
    $path = Join-Path $stage $relativePath
    if (-not (Test-Path -LiteralPath $path -PathType Container)) {
        $missing.Add("directory: $relativePath")
    }
}

$qtDllPatterns = @('Qt*Core.dll', 'Qt*Gui.dll', 'Qt*Widgets.dll', 'Qt*Sql.dll')
foreach ($pattern in $qtDllPatterns) {
    if (-not (Get-ChildItem -LiteralPath $stage -Filter $pattern -File -ErrorAction SilentlyContinue)) {
        $missing.Add("Qt runtime DLL matching: $pattern")
    }
}

if ($missing.Count -gt 0) {
    Write-Host "Stage runtime check FAILED: $stage" -ForegroundColor Red
    $missing | ForEach-Object { Write-Host "  missing $_" -ForegroundColor Red }
    exit 1
}

Write-Host "Stage runtime check PASSED: $stage" -ForegroundColor Green
Write-Host "Static package layout is complete. Run the manual playback matrix in docs/P1C-RELEASE-QUALITY-GATE.md."
