#environment

set-strictmode -version latest

$profileDirectory = Split-Path $profile
$env:path = $env:path + ";$profileDirectory"

define-location scripts ([System.IO.Path]::GetDirectoryName($profile))
define-location desk ~\Desktop
define-location docs ~\Documents
define-location repos ~\Documents\Projects

#aliases
set-alias u goto-ancestor
set-alias e open-explorer
set-alias ">>" where-propertyvalue
set-alias gh get-help
set-alias cl clip-location
set-alias fs search-code
set-alias n open-texteditor
set-alias ss select-string
set-alias dl define-location
set-alias sudo elevate-process
set-alias ch Clip-History

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

