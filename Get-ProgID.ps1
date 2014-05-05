param([string]$filter="*")

$clsIdPath = "REGISTRY::HKey_Classes_Root\clsid\*\progid"
dir $clsIdPath |
    Where-Object { $_.name -match '\\ProgID$' } |
    ForEach-Object { $_.GetValue("") } |
    Where-Object { $_ -like $filter }
