[CmdletBinding()]
param
(
    [Parameter(Mandatory=$true)]
    [string]$SourceFolderId,

    [Parameter(Mandatory=$true)]
    [string]$DestinationDirectoryPath,

    [Parameter(Mandatory=$true)]
    [string]$ClientId,

    [Parameter(Mandatory=$true)]
    [string]$Secret,

    [Parameter(Mandatory=$true)]
    [string]$ProfileName
)

function GetAccessToken
{
    Get-LiveAccessToken -ClientId $ClientId -Secret $Secret -ProfileName $ProfileName
}

Set-StrictMode -Version latest
$ErrorActionPreference = 'Stop'
Import-Module Live

if(-not (Test-Path $DestinationDirectoryPath -PathType Container))
{
    mkdir $DestinationDirectoryPath | Out-Null
}

$page = "$SourceFolderId/files?limit=1"
while($page)
{
    $file = Invoke-LiveRestMethod -Resource $page -AccessToken (GetAccessToken)
    $filePath = Join-Path $DestinationDirectoryPath $file.data.name
    $fileUrl = $file.data.images | Where-Object type -eq 'full' | ForEach-Object source

    if($fileUrl)
    {
        Write-Host "Downloading $fileUrl to $filePath"
        Invoke-WebRequest $fileUrl -OutFile $filePath

        Write-Host "Deleting $fileUrl"
        Invoke-LiveRestMethod $file.data.Id -Method Delete -AccessToken (GetAccessToken)
    }

    if($file.paging)
    {
        $page = $file.paging.next
    }
    else
    {
        $page = $null
    }
}
