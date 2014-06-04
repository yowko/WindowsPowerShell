param
(
    [Parameter(Mandatory=$true, Position=0)]
    [int]$Id
)

(Get-History -Id $Id).CommandLine | clip
