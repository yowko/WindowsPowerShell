[CmdletBinding(DefaultParameterSetName='Id')]
param
(
    [Parameter(
        Mandatory=$true,
        Position=0,
        ParameterSetName='Id')]
    [int]$Id,

    [Parameter(
        Mandatory=$true,
        ParameterSetName='Count')]
    [int]$Count
)

if ($PSCmdlet.ParameterSetName -eq 'Id') {
    (Get-History -Id $Id).CommandLine | clip
    return
}

Get-History -Count $Count | ForEach-Object { $_.CommandLine } | clip