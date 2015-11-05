param([string]$File="")

if($File -and -not (Test-Path $File))
{
    if(-not (Test-Path $File))
    {
        '' | Set-Content -Path $File -Encoding Ascii
    }

    $File = Resolve-Path $File
}

if(Test-Path variable:\psISE)
{
    psEdit $File
    return
}

if(Test-Path variable:\PGSE)
{
    $PGSE.DocumentWindows.Add($File)
    return 
}

$texteditor = Get-TextEditor;
Invoke-Expression "&`"$texteditor`" `"$File`""