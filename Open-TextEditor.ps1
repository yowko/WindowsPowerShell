param([string]$file="")

$psExtensions = @(
    '.ps1'
    '.psm1'
    '.psd1'
)

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

if($psExtensions -contains [System.IO.Path]::GetExtension($file))
{
    $powershellEditor = Get-PowerShellEditor.ps1
    & $powershellEditor $file
    return
}

$texteditor = Get-TextEditor;
Invoke-Expression "&`"$texteditor`" `"$file`""