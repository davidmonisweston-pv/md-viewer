<#
.SYNOPSIS
    Removes the md-viewer file association written by register-file-association.ps1.
#>
$ErrorActionPreference = 'Stop'

$progId  = 'MdViewer.Markdown'
$exts    = @('.md', '.markdown', '.mdown', '.mkd', '.mkdn', '.mdwn')
$classes = 'HKCU:\Software\Classes'

Remove-Item -Path "$classes\$progId" -Recurse -Force -ErrorAction SilentlyContinue

foreach ($ext in $exts) {
    Remove-ItemProperty -Path "$classes\$ext\OpenWithProgids" `
                        -Name $progId -Force -ErrorAction SilentlyContinue
}

Add-Type -Namespace Shell -Name Notify2 -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("shell32.dll")]
public static extern void SHChangeNotify(int e, uint f, System.IntPtr a, System.IntPtr b);
'@
[Shell.Notify2]::SHChangeNotify(0x08000000, 0, [System.IntPtr]::Zero, [System.IntPtr]::Zero)

Write-Host 'Removed the md-viewer file association.' -ForegroundColor Green
Write-Host 'If Windows still lists it as the default, set a different app in'
Write-Host 'Settings > Apps > Default apps > Choose defaults by file type.'
