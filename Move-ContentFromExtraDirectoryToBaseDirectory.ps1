function getExtraDirectoryBaseFullName
{
    param($Directory)
    
    return $Directory.FullName.SubString(0, $Directory.FullName.Length - 4)
}

$extradirs = dir | where{$_.Name -match ' 00\d$'}

$extradirs | foreach {
    $baseFullName = getExtraDirectoryBaseFullName $_
    
    if(-not [System.IO.Directory]::Exists($baseFullName))
    {
        mkdir $baseFullName
    }

    write-host "Moving contents of $($_.FullName) to $baseFullName"
    move "$($_.FullName)\*.*" $baseFullName
}