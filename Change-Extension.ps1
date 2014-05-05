param([string]$path=$(throw "File path required"), [string]$ext=$(throw "Extension required"))

$newName = [System.IO.Path]::GetFileName($path)
$newName = [System.IO.Path]::GetFileNameWithoutExtension($newName) + "." + $ext
rename-item $path $newName