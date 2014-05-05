param([string]$file="")

$texteditor = Get-TextEditor;
Invoke-Expression "&`"$texteditor`" `"$file`""