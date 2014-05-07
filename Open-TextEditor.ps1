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

if(Test-Path variable:\psISE)
{
    psEdit $file
    return
}

if($psExtensions -contains [System.IO.Path]::GetExtension($file))
{
    & PowerShell_ISE.exe $file
    return
}

$texteditor = Get-TextEditor;
Invoke-Expression "&`"$texteditor`" `"$file`""