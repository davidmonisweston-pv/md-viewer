<#
.SYNOPSIS
    Registers md-viewer as a program Windows can open .md files with.

.DESCRIPTION
    Writes a ProgID under HKEY_CURRENT_USER only — no admin rights, nothing
    machine-wide, and unregister-file-association.ps1 removes all of it.

    Windows will not let a script claim a file type as the default; that choice
    is yours to make once in the Open With dialog. This script makes md-viewer
    appear there. Instructions are printed at the end.
#>
$ErrorActionPreference = 'Stop'

$progId  = 'MdViewer.Markdown'
$label   = 'Markdown viewer'
$opener  = Join-Path $PSScriptRoot 'open-md.ps1'
$exts    = @('.md', '.markdown', '.mdown', '.mkd', '.mkdn', '.mdwn')

if (-not (Test-Path -LiteralPath $opener)) {
    throw "Cannot find open-md.ps1 next to this script (looked in $PSScriptRoot)."
}

$command = '"{0}" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "{1}" "%1"' -f `
           (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'), $opener

$classes = 'HKCU:\Software\Classes'

New-Item -Path "$classes\$progId\shell\open\command" -Force | Out-Null
Set-ItemProperty -Path "$classes\$progId"                   -Name '(default)'       -Value $label
Set-ItemProperty -Path "$classes\$progId"                   -Name 'FriendlyTypeName' -Value $label
Set-ItemProperty -Path "$classes\$progId\shell\open"        -Name 'FriendlyAppName'  -Value $label
Set-ItemProperty -Path "$classes\$progId\shell\open\command" -Name '(default)'       -Value $command

foreach ($ext in $exts) {
    New-Item -Path "$classes\$ext\OpenWithProgids" -Force | Out-Null
    New-ItemProperty -Path "$classes\$ext\OpenWithProgids" `
                     -Name $progId -Value ([byte[]]@()) -PropertyType None -Force | Out-Null
}

# Tell Explorer the associations changed, so the new entry shows up right away.
Add-Type -Namespace Shell -Name Notify -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("shell32.dll")]
public static extern void SHChangeNotify(int e, uint f, System.IntPtr a, System.IntPtr b);
'@
[Shell.Notify]::SHChangeNotify(0x08000000, 0, [System.IntPtr]::Zero, [System.IntPtr]::Zero)

Write-Host ''
Write-Host "Registered '$label' for: $($exts -join ' ')" -ForegroundColor Green
Write-Host "Opens with: $opener"
Write-Host ''
Write-Host 'To make it the default, once:' -ForegroundColor Cyan
Write-Host '  1. Right-click any .md file in Explorer'
Write-Host '  2. Open with  >  Choose another app'
Write-Host "  3. Pick '$label', tick 'Always use this app', then OK"
Write-Host ''
Write-Host 'To undo everything: unregister-file-association.ps1'
