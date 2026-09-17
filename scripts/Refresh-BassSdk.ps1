[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Apply,
    [switch]$KeepDownloads
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$bassRoot = Join-Path $repositoryRoot 'BASS'
$workRoot = Join-Path $repositoryRoot 'build\vendor-cache\bass-stack-refresh'
$downloadRoot = Join-Path $workRoot 'downloads'
$extractRoot = Join-Path $workRoot 'extract'

$packages = @(
    @{ Name = 'BASS'; Version = '2.4.18.3'; Url = 'https://www.un4seen.com/files/bass24.zip'; Directory = 'bass24'; Header = 'bass.h'; Library = 'bass.lib'; Dll = 'bass.dll' },
    @{ Name = 'BASSMIDI'; Version = '2.4.16'; Url = 'https://www.un4seen.com/files/bassmidi24.zip'; Directory = 'bassmidi24'; Header = 'bassmidi.h'; Library = 'bassmidi.lib'; Dll = 'bassmidi.dll' },
    @{ Name = 'BASSmix'; Version = '2.4.13'; Url = 'https://www.un4seen.com/files/bassmix24.zip'; Directory = 'bassmix24'; Header = 'bassmix.h'; Library = 'bassmix.lib'; Dll = 'bassmix.dll' },
    @{ Name = 'BASS FX'; Version = '2.4.12.6'; Url = 'https://www.un4seen.com/files/z/0/bass_fx24.zip'; Directory = 'bass_fx24'; Header = 'bass_fx.h'; Library = 'bass_fx.lib'; Dll = 'bass_fx.dll' }
)

function Require-File {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Expected file was not found: $Path"
    }
}

function Resolve-SdkRoot {
    param(
        [string]$ExtractedPath,
        [hashtable]$Package
    )

    $candidates = @($ExtractedPath)
    $candidates += Get-ChildItem -LiteralPath $ExtractedPath -Directory -Recurse |
        Select-Object -ExpandProperty FullName

    foreach ($candidate in $candidates) {
        $header = Join-Path $candidate $Package.Header
        $library = Join-Path $candidate ('x64\' + $Package.Library)
        $dll = Join-Path $candidate ('x64\' + $Package.Dll)
        if ((Test-Path -LiteralPath $header -PathType Leaf) -and
            (Test-Path -LiteralPath $library -PathType Leaf) -and
            (Test-Path -LiteralPath $dll -PathType Leaf)) {
            return $candidate
        }
    }

    throw "Unable to find a compatible x64 SDK layout for $($Package.Name) below: $ExtractedPath"
}

New-Item -ItemType Directory -Force -Path $downloadRoot, $extractRoot | Out-Null
$resolvedPackages = @()

foreach ($package in $packages) {
    $archive = Join-Path $downloadRoot ($package.Directory + '.zip')
    if (-not (Test-Path -LiteralPath $archive -PathType Leaf)) {
        Write-Host "Downloading $($package.Name) $($package.Version)..."
        Invoke-WebRequest -Uri $package.Url -OutFile $archive
    }

    $destination = Join-Path $extractRoot $package.Directory
    if (Test-Path -LiteralPath $destination) {
        Remove-Item -LiteralPath $destination -Recurse -Force
    }
    Expand-Archive -LiteralPath $archive -DestinationPath $destination -Force

    $sdkRoot = Resolve-SdkRoot -ExtractedPath $destination -Package $package
    $header = Join-Path $sdkRoot $package.Header
    $library = Join-Path $sdkRoot ('x64\' + $package.Library)
    $dll = Join-Path $sdkRoot ('x64\' + $package.Dll)
    Require-File $header
    Require-File $library
    Require-File $dll

    $resolvedPackages += [PSCustomObject]@{
        Name = $package.Name
        Version = $package.Version
        Header = $header
        Library = $library
        Dll = $dll
        Directory = $package.Directory
    }
}

Write-Host ''
Write-Host 'Validated BASS SDK files:'
$resolvedPackages | Select-Object Name, Version, Header, Library, Dll | Format-Table -AutoSize

if (-not $Apply) {
    Write-Host 'Dry run completed. No repository files were changed.'
    Write-Host 'After confirming the BASS licence for your distribution, rerun with -Apply.'
    exit 0
}

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupRoot = Join-Path $repositoryRoot ('build\vendor-backups\bass-stack-' + $timestamp)
New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null

foreach ($package in $resolvedPackages) {
    $targetRoot = Join-Path $bassRoot $package.Directory
    $targetHeader = Join-Path $targetRoot (Split-Path -Leaf $package.Header)
    $targetLibrary = Join-Path $targetRoot ('x64\' + (Split-Path -Leaf $package.Library))
    $targetDll = Join-Path $targetRoot ('x64\' + (Split-Path -Leaf $package.Dll))
    Require-File $targetHeader
    Require-File $targetLibrary
    Require-File $targetDll

    $backupPackageRoot = Join-Path $backupRoot $package.Directory
    New-Item -ItemType Directory -Force -Path (Join-Path $backupPackageRoot 'x64') | Out-Null
    Copy-Item -LiteralPath $targetHeader -Destination (Join-Path $backupPackageRoot (Split-Path -Leaf $targetHeader)) -Force
    Copy-Item -LiteralPath $targetLibrary -Destination (Join-Path $backupPackageRoot ('x64\' + (Split-Path -Leaf $targetLibrary))) -Force
    Copy-Item -LiteralPath $targetDll -Destination (Join-Path $backupPackageRoot ('x64\' + (Split-Path -Leaf $targetDll))) -Force

    if ($PSCmdlet.ShouldProcess($targetRoot, "refresh $($package.Name) to $($package.Version)")) {
        Copy-Item -LiteralPath $package.Header -Destination $targetHeader -Force
        Copy-Item -LiteralPath $package.Library -Destination $targetLibrary -Force
        Copy-Item -LiteralPath $package.Dll -Destination $targetDll -Force
    }
}

Write-Host 'BASS stack refresh applied.'
Write-Host "Backup of the previous files: $backupRoot"
if (-not $KeepDownloads) {
    Write-Host "Downloaded archives remain at: $downloadRoot"
}
