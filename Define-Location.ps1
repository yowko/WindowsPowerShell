param([string]$name=$(throw "A name is required for the location"), $path=$pwd)

set-variable -name $name -value "$([string]$path)" -scope global
invoke-expression "function global:goto-$name{push-location `$$name}"
set-alias -name $name -value "goto-$name" -scope global