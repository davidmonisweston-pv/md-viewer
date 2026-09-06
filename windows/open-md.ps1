<#
.SYNOPSIS
    Opens a Markdown file in md-viewer in the default browser.

.DESCRIPTION
    A page loaded from file:// cannot read another local file, so the viewer
    cannot simply be pointed at a path. Instead this builds a self-contained
    copy of the viewer with the document baked in, drops it in the temp folder
    and opens that.

    Registered as the handler for .md by register-file-association.ps1.
#>
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string] $Path,

    # Build the page but don't open a browser. For testing.
    [switch] $NoLaunch
)

$ErrorActionPreference = 'Stop'

$repo   = Split-Path -Parent $PSScriptRoot
$viewer = Join-Path $repo 'index.html'
$vendor = Join-Path $repo 'vendor'

if (-not (Test-Path -LiteralPath $viewer)) {
    [void][System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
    [System.Windows.Forms.MessageBox]::Show(
        "The viewer is missing:`n$viewer", 'md-viewer') | Out-Null
    exit 1
}
if (-not (Test-Path -LiteralPath $Path)) {
    [void][System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
    [System.Windows.Forms.MessageBox]::Show(
        "File not found:`n$Path", 'md-viewer') | Out-Null
    exit 1
}

$full = (Resolve-Path -LiteralPath $Path).ProviderPath
$name = [System.IO.Path]::GetFileName($full)

$template = Get-Content -LiteralPath $viewer -Raw -Encoding UTF8
$markdown = Get-Content -LiteralPath $full   -Raw -Encoding UTF8
if ($null -eq $markdown) { $markdown = '' }

# Encode as JSON so the document survives as a JavaScript string literal.
# "<" is escaped as well, so a "</script>" inside the document cannot close
# the tag it is embedded in.
function ConvertTo-JsString([string] $value) {
    ($value | ConvertTo-Json -Compress) -replace '<', '\u003c'
}

$inject = '<script>window.addEventListener("load",function(){window.mdViewer.open(' +
          (ConvertTo-JsString $markdown) + ',' + (ConvertTo-JsString $name) + ');});</script>'

$html = $template.Replace('</body>', $inject + "`n</body>")

# Temp folder holds the generated page plus a copy of the vendored libraries,
# which the page loads by relative path.
$outDir = Join-Path $env:TEMP 'md-viewer'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $outDir 'vendor') | Out-Null
# Only copy the libraries when they are missing or have changed; when the
# viewer lives in WSL this saves reading them back over the WSL filesystem on
# every single open.
foreach ($lib in Get-ChildItem -Path (Join-Path $vendor '*.js') -File) {
    $dest = Join-Path $outDir "vendor\$($lib.Name)"
    $have = Get-Item -LiteralPath $dest -ErrorAction SilentlyContinue
    if (-not $have -or $have.Length -ne $lib.Length -or $have.LastWriteTime -lt $lib.LastWriteTime) {
        Copy-Item -LiteralPath $lib.FullName -Destination $dest -Force
    }
}

# Reopening the same document reuses its page rather than piling up files.
$md5  = [System.Security.Cryptography.MD5]::Create()
$hash = [System.BitConverter]::ToString(
            $md5.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($full.ToLower()))
        ).Replace('-', '').Substring(0, 10)
$safe = [System.IO.Path]::GetFileNameWithoutExtension($name) -replace '[^\w\-]', '-'
$out  = Join-Path $outDir "$safe-$hash.html"

[System.IO.File]::WriteAllText($out, $html, (New-Object System.Text.UTF8Encoding($false)))

# Clear out pages not opened in the last week.
Get-ChildItem -Path $outDir -Filter '*.html' -File -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } |
    Remove-Item -Force -ErrorAction SilentlyContinue

if ($NoLaunch) { Write-Output $out }
else           { Start-Process $out }
