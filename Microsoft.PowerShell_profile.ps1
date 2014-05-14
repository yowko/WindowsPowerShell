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

#functions
function prompt
{
    set-strictmode -off

    if($null -eq $global:initial_forecolor)
    {
        $global:initial_forecolor = $host.UI.RawUI.ForegroundColor
    }
    else
    {
        $host.UI.RawUI.ForegroundColor = $global:initial_forecolor
    }
    
    $chunks = (get-location).Path.Split('\', [System.StringSplitOptions]::RemoveEmptyEntries)

    write-host "`n[$((get-date).ToString())]" -fore darkgray
    
    foreach($c in $chunks)
    {
        write-host "$c" -fore darkgray -no
        write-host "\" -fore gray -no
    }
	
	 Write-VcsStatus
    
    write-host "`n>" -fore darkgray -no
    return " "
}

Import-Module posh-git
Enable-GitColors
$global:GitPromptSettings.WorkingForegroundColor = [ConsoleColor]::Red
$global:GitPromptSettings.UntrackedForegroundColor = [ConsoleColor]::Red

# Load posh-git example profile
# . 'C:\Users\Rafael\Documents\WindowsPowerShell\Modules\posh-git\profile.example.ps1'

