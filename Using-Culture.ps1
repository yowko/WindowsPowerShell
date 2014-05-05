param
(
    [Parameter(Mandatory=$true)]
    [System.Globalization.CultureInfo]$Culture,
    [Parameter(Mandatory=$true)]
    [ScriptBlock]$Script
)

$oldCulture = [System.Threading.Thread]::CurrentThread.CurrentCulture
trap 
{
    [System.Threading.Thread]::CurrentThread.CurrentCulture = $oldCulture
}
[System.Threading.Thread]::CurrentThread.CurrentCulture = $Culture
Invoke-Command $Script
[System.Threading.Thread]::CurrentThread.CurrentCulture = $oldCulture
