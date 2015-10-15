#environment

Set-StrictMode -version latest

$profileDirectory = Split-Path $profile
$env:path = $env:path + ";$profileDirectory"
$env:path = $env:path + ";$profileDirectory\bin"

Set-Location $profileDirectory

Define-Location scripts (Split-Path $profile)
Define-Location desk ~\Desktop
Define-Location docs ~\Documents
Define-Location repos ~\Documents\Projects

#aliases
Set-Alias u Goto-Ancestor
Set-Alias e Open-Explorer
Set-Alias ">>" Where-PropertyValue
Set-Alias gh Get-Help
Set-Alias cl Clip-Location
Set-Alias fs Search-Code
Set-Alias n Open-TextEditor
Set-Alias ss Select-String
Set-Alias dl Define-Location
Set-Alias sudo Elevate-Process
Set-Alias ch Clip-History
Set-Alias sw Search-Web

#functions
function prompt
{
    Set-StrictMode -Off

    if($null -eq $global:initial_forecolor)
    {
        $global:initial_forecolor = $host.UI.RawUI.ForegroundColor
    }
    else
    {
        $host.UI.RawUI.ForegroundColor = $global:initial_forecolor
    }
    
    $chunks = (Get-Location).Path -split '\\'

    Write-Host ''
    
    foreach($c in $chunks)
    {
        Write-Host "$c" -ForegroundColor DarkGray -NoNewline
        Write-Host "\" -ForegroundColor Gray -NoNewline
    }
    	
	Write-VcsStatus
    
    $nextHistoryId = (Get-History -Count 1).Id + 1
    Write-Host "`n[$nextHistoryId]>" -ForegroundColor DarkGray -NoNewline
    return " "
}

Import-Module posh-git
Enable-GitColors
$global:GitPromptSettings.WorkingForegroundColor = [ConsoleColor]::Red
$global:GitPromptSettings.UntrackedForegroundColor = [ConsoleColor]::Red

# Load posh-git example profile
# . 'C:\Users\Rafael\Documents\WindowsPowerShell\Modules\posh-git\profile.example.ps1'

if ($PSVersionTable.PSVersion -gt [System.Version]'2.0' -and $host.Name -eq 'ConsoleHost')
{
    Import-Module PSReadline
    Initialize-PSReadLineKeyHandler
}

if (Get-Command choco -ErrorAction SilentlyContinue) {
    choco feature enable -n allowGlobalConfirmation | Out-Null
}


