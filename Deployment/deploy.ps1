Set-StrictMode -Version latest

# Determine if we are running as admin
$wid = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$prp = New-Object System.Security.Principal.WindowsPrincipal($wid)
$adm = [System.Security.Principal.WindowsBuiltInRole]::Administrator
$isAdmin = $prp.IsInRole($adm)

if(-not $isAdmin)
{
   # Run elevated
   Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Unrestricted -Command `"& $($MyInvocation.MyCommand.Definition)`""
   return
}

# Create symbolic link to the "public" .gitconfig and create a .gitconfig_private for "private" stuff
if(-not (Test-Path "$HOME\.gitconfig"))
{
    Write-Host 'Create symbolic link to the "public" .gitconfig'
    Invoke-Expression "cmd /c mklink '$HOME\.gitconfig' '$(Split-Path $PROFILE)\Deployment\Git\.gitconfig'"
    if(-not (Test-Path "$HOME\.gitconfig_private"))
    {
        Write-Host 'Create a .gitconfig_private for "private" stuff'
        '' | Set-Content "$HOME\.gitconfig_private" -Encoding ascii
    }
}
pause

# Install Chocolatey
Invoke-Expression ((New-Object Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
$env:PATH += ";$env:SystemDrive\chocolatey\bin"

choco feature enable -n allowGlobalConfirmation

# Install PowerShell 4
# cinst powershell4

# Install ConEmu
cinst conemu

# Install Notepad++
cinst notepadplusplus.install

# Install Chrome
cinst GoogleChrome

# Install Firefox
cinst Firefox

# Install VS2013 Premium
# To include you product key, include the following in the InstallArguments: /ProductKey:<your key here>
cinst VisualStudio2013Premium -InstallArguments "/Features:'Blend VC_MFC_Libraries WebTools SQL WebTools Win8SDK SilverLight_Developer_Kit WindowsPhone80'"

# Install ReSharper
cinst resharper

# Install Reflector
cinst reflector

# Install GitExtensions
cinst gitextensions

# Install Beyond Compare
cinst beyondcompare

# Install PowerGUI
# cinst PowerGUI

# Install WebStorm
cinst WebStorm

# Install Fiddler
cinst fiddler4

# Install Process Explorer
cinst procexp 

# Install Paint.NET
cinst paint.net

# Install WinDbg
cinst windbg

# Install Screenpresso
cinst screenpresso

cinst icofx2 

cinst 7zip
cinst ffmpeg

cinst brackets

cinst crashplan

cinst truecrypt

cinst nodejs.install

# Configure IIS
# cinst IIS-WebServerRole -source windowsfeatures 
# cinst IIS-ISAPIFilter -source windowsfeatures 
# cinst IIS-ISAPIExtensions -source windowsfeatures 
# cinst IIS-NetFxExtensibility -source windowsfeatures 
# cinst IIS-ASPNET -source windowsfeatures 

Write-Host @"

All done!

"@

pause


