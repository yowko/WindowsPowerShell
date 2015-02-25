param([string]$file="")

if($file -and -not (Test-Path $file))
{
    '' | Set-Content -Path $file -Encoding Ascii
}

$file = Resolve-Path $file

if(Test-Path variable:\psISE)
{
    psEdit $file
    return
}

if(Test-Path variable:\PGSE)
{
    $PGSE.DocumentWindows.Add($file)
    return 
}

$texteditor = Get-TextEditor;
Invoke-Expression "&`"$texteditor`" `"$file`""