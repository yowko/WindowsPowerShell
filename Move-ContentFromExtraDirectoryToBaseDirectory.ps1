function getExtraDirectoryBaseFullName {
    param($Directory)
    
    return $Directory.FullName.SubString(0, $Directory.FullName.Length - 4)
}

$extradirs = dir | Where-Object { $_.Name -match ' 00\d$' }

$extradirs | ForEach-Object {
    $baseFullName = getExtraDirectoryBaseFullName $_
    
    if (-not [System.IO.Directory]::Exists($baseFullName)) {
        mkdir $baseFullName
    }

    Write-Host "Moving contents of $($_.FullName) to $baseFullName"
    move "$($_.FullName)\*.*" $baseFullName
}