param([string]$locationHint)

if("" -eq $locationHint)
{
  set-location ..
  return
}

$item = (get-item .).Parent
while($item -ne $null)
{
    if($item.Name -like "$locationHint*")
    {
        push-location $item.FullName    
        break
    }

    $item = $item.Parent
}