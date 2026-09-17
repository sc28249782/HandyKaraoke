[CmdletBinding()]
param(
    [string]$BuildDir,
    [string]$StageDir,
    [string]$OutputDir,
    [string]$Version = '3.0.0-alpha-recovery',
    [switch]$SkipStage
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if (-not $BuildDir) { $BuildDir = Join-Path $repositoryRoot 'build\msvc-x64-release' }
if (-not $StageDir) { $StageDir = Join-Path $BuildDir 'stage\HandyKaraoke' }
if (-not $OutputDir) { $OutputDir = Join-Path $BuildDir 'package' }
$issScript = Join-Path $repositoryRoot '_iss_setup\handykaraoke-stage-x64.iss'

function Find-Iscc {
    $command = Get-Command ISCC.exe -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }
    $candidates = @(
        (Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe'),
        (Join-Path $env:ProgramFiles 'Inno Setup 6\ISCC.exe')
    )
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
    }
    throw 'Inno Setup 6 was not found. Install it, or add ISCC.exe to PATH.'
}

if (-not $SkipStage) {
    & cmake --build $BuildDir --target stage-smoke --parallel
    if ($LASTEXITCODE -ne 0) { throw 'stage-smoke failed; installer was not built.' }
}

foreach ($required in @(
    (Join-Path $StageDir 'HandyKaraoke.exe'),
    (Join-Path $StageDir 'platforms\qwindows.dll'),
    (Join-Path $StageDir 'sqldrivers\qsqlite.dll'),
    (Join-Path $StageDir 'bass.dll'),
    (Join-Path $StageDir 'bassmidi.dll')
)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) {
        throw "Verified stage is incomplete: $required"
    }
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$iscc = Find-Iscc
& $iscc ("/DSourceDir=" + $StageDir) ("/DOutputDir=" + $OutputDir) ("/DMyAppVersion=" + $Version) $issScript
if ($LASTEXITCODE -ne 0) { throw "Inno Setup failed with exit code $LASTEXITCODE." }

Write-Host "Installer created in: $OutputDir"
