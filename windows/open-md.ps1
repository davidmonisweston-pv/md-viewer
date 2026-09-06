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

# Two layouts: the installed copy is flat, the repository keeps the web files
# in site/ so that only those are ever published.
$viewer = Join-Path $repo 'index.html'
if (-not (Test-Path -LiteralPath $viewer)) {
    $viewer = Join-Path $repo 'site\index.html'
}
$vendor = Join-Path (Split-Path -Parent $viewer) 'vendor'

# Explorer runs this with -WindowStyle Hidden, so an unhandled error would
# terminate PowerShell with nothing on screen and no clue why nothing opened.
function Show-Problem([string] $message) {
    if ($NoLaunch) { Write-Error $message; return }
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        [System.Windows.Forms.MessageBox]::Show(
            $message, 'md-viewer', 'OK', 'Warning') | Out-Null
    } catch {
        Write-Error $message
    }
}

try {

if (-not (Test-Path -LiteralPath $viewer)) {
    Show-Problem "The viewer is missing:`n$viewer`n`nRe-run windows\install.ps1 from the repository."
    exit 1
}
if (-not (Test-Path -LiteralPath $Path)) {
    Show-Problem "File not found:`n$Path"
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

# The document's folder, so relative links and images inside it still resolve
# once the page itself is living in the temp folder.
$baseUri = ([System.Uri]([System.IO.Path]::GetDirectoryName($full) +
                         [System.IO.Path]::DirectorySeparatorChar)).AbsoluteUri

$inject = '<script>window.addEventListener("load",function(){window.mdViewer.open(' +
          (ConvertTo-JsString $markdown) + ',' + (ConvertTo-JsString $name) + ',' +
          (ConvertTo-JsString $baseUri) + ');});</script>'

$html = $template.Replace('</body>', $inject + "`n</body>")

# Temp folder holds the generated page plus a copy of the vendored libraries,
# which the page loads by relative path.
$outDir = Join-Path $env:TEMP 'md-viewer'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $outDir 'vendor') | Out-Null
# Only copy the libraries when they are missing or have changed; when the
# viewer lives in WSL this saves reading them back over the WSL filesystem on
# every single open.
foreach ($lib in Get-ChildItem -LiteralPath $vendor -Filter '*.js' -File) {
    $dest = Join-Path $outDir "vendor\$($lib.Name)"
    $have = Get-Item -LiteralPath $dest -ErrorAction SilentlyContinue
    if (-not $have -or $have.Length -ne $lib.Length -or $have.LastWriteTime -lt $lib.LastWriteTime) {
        Copy-Item -LiteralPath $lib.FullName -Destination $dest -Force
    }
}

# Reopening the same document reuses its page rather than piling up files.
# The path is hashed exactly as given: WSL paths are case-sensitive, so
# .../A/notes.md and .../a/notes.md are different documents.
$md5  = [System.Security.Cryptography.MD5]::Create()
$hash = [System.BitConverter]::ToString(
            $md5.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($full))
        ).Replace('-', '').Substring(0, 10)

# The readable part is trimmed so a long but perfectly legal filename cannot
# push the generated name past what Windows accepts.
$safe = [System.IO.Path]::GetFileNameWithoutExtension($name) -replace '[^\w\-]', '-'
if ($safe.Length -gt 60) { $safe = $safe.Substring(0, 60) }
if (-not $safe)          { $safe = 'document' }
$out  = Join-Path $outDir "$safe-$hash.html"

[System.IO.File]::WriteAllText($out, $html, (New-Object System.Text.UTF8Encoding($false)))

# Clear out pages not opened in the last week.
Get-ChildItem -Path $outDir -Filter '*.html' -File -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } |
    Remove-Item -Force -ErrorAction SilentlyContinue

if ($NoLaunch) { Write-Output $out }
else           { Start-Process $out }

}
catch {
    Show-Problem ("Could not open`n$Path`n`n" + $_.Exception.Message)
    exit 1
}
