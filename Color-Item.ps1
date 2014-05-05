param($colorpredicates=$(throw "Specify a hash table with members that contain a color and predicate"))

begin
{
    $script:original = $host.UI.RawUI.ForegroundColor
}
process
{
    $host.UI.RawUI.ForegroundColor = $script:original    

    foreach($kvp in $colorpredicates.GetEnumerator())
    {
        if(($kvp.Predicate).Invoke())
        {
            $host.UI.RawUI.ForegroundColor = $kvp.Color
            break
        }
    }

    $_
}
end
{
    $host.UI.RawUI.ForegroundColor = $script:original
}
