#environment

Set-StrictMode -version latest

$profileDirectory = Split-Path $profile
$env:path = $env:path + ";$profileDirectory"

Set-Location $profileDirectory

Set-LocationAlias scripts (Split-Path $profile)
Set-LocationAlias desk ~\Desktop
Set-LocationAlias docs ~\Documents
Set-LocationAlias repos ~\Documents\Projects

#aliases
Set-Alias u Set-LocationAncestor
Set-Alias e Open-Explorer
Set-Alias ">>" Where-PropertyValue
Set-Alias gh Get-Help
Set-Alias cl Copy-LocationToClipboard
Set-Alias fs Search-Code
Set-Alias n Open-TextEditor
Set-Alias ss Select-String
Set-Alias dl Set-LocationAlias
Set-Alias sudo Elevate-Process
Set-Alias ch Copy-HistoryToClipboard
Set-Alias sw Search-Web

#functions
function prompt {
    Set-StrictMode -Off

    if ($null -eq $global:initial_forecolor) {
        $global:initial_forecolor = $host.UI.RawUI.ForegroundColor
    } else {
        $host.UI.RawUI.ForegroundColor = $global:initial_forecolor
    }
    
    $chunks = (Get-Location).Path -split '\\'

    Write-Host ''
    
    foreach ($c in $chunks) {
        Write-Host "$c" -ForegroundColor DarkGray -NoNewline
        Write-Host "\" -ForegroundColor Gray -NoNewline
    }
    	
	Write-VcsStatus
    
    $nextHistoryId = (Get-History -Count 1).Id + 1
    Write-Host "`n[$nextHistoryId]>" -ForegroundColor DarkGray -NoNewline
    return " "
}

Import-Module posh-git

# Load posh-git example profile
# . 'C:\Users\Rafael\Documents\WindowsPowerShell\Modules\posh-git\profile.example.ps1'

if ($PSVersionTable.PSVersion -gt [System.Version]'2.0' -and $host.Name -eq 'ConsoleHost') {
    Import-Module PSReadline
    Initialize-PSReadLineKeyHandler
}