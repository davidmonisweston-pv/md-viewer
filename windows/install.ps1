<#
.SYNOPSIS
    Copies md-viewer to a Windows-side folder and registers it for .md files.

.DESCRIPTION
    The repository lives in WSL, but opening a document from there means waiting
    for WSL to start and reading the viewer back across the WSL filesystem on
    every open. This installs a plain Windows copy and points the file
    association at that instead.

    Re-run it after changing the viewer to update the installed copy. The
    association survives: Windows binds your default-app choice to the ProgID,
    not to the path behind it, so you do not have to pick the app again.
#>
param(
    [string] $Destination = (Join-Path $env:LOCALAPPDATA 'md-viewer')
)

$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent $PSScriptRoot

if ((Resolve-Path -LiteralPath $repo).ProviderPath -eq
    (Resolve-Path -LiteralPath $Destination -ErrorAction SilentlyContinue).ProviderPath) {
    throw 'Run this from the repository, not from the installed copy.'
}

Write-Host "Installing from $repo"
Write-Host "            to $Destination"

foreach ($dir in @($Destination, (Join-Path $Destination 'vendor'), (Join-Path $Destination 'windows'))) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

# Web files live in site/ in the repository; the installed copy is flat.
$web = Join-Path $repo 'site'
if (-not (Test-Path -LiteralPath $web)) { $web = $repo }

foreach ($page in @('index.html', 'privacy.html')) {
    $from = Join-Path $web $page
    if (Test-Path -LiteralPath $from) {
        Copy-Item -LiteralPath $from -Destination $Destination -Force
    }
}
# -LiteralPath throughout: a checkout in a folder like "md-viewer [main]"
# would otherwise be read as a wildcard pattern and quietly match nothing.
foreach ($pair in @(@{ Root = $web;   From = 'vendor';  Filter = '*.js'  },
                    @{ Root = $repo;  From = 'windows'; Filter = '*.ps1' })) {
    $src = Join-Path $pair.Root $pair.From
    foreach ($item in Get-ChildItem -LiteralPath $src -Filter $pair.Filter -File) {
        Copy-Item -LiteralPath $item.FullName `
                  -Destination (Join-Path $Destination "$($pair.From)\$($item.Name)") -Force
    }
}

$sample = Join-Path $web 'sample.md'
if (Test-Path -LiteralPath $sample) {
    Copy-Item -LiteralPath $sample -Destination $Destination -Force
}

Write-Host ''
& (Join-Path $Destination 'windows\register-file-association.ps1')

Write-Host ''
Write-Host 'To remove it completely:' -ForegroundColor Cyan
Write-Host "  powershell -ExecutionPolicy Bypass -File `"$Destination\windows\unregister-file-association.ps1`""
Write-Host "  Remove-Item -Recurse `"$Destination`""
