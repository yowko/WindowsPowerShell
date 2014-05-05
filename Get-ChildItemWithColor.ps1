$codeextensions = get-codeextensions
$filecolorpredicates = @(
    @{
        Color=[System.ConsoleColor]::Magenta;
        Predicate=
        {
            $_.psiscontainer
        }};
        
    @{
        Color=[System.ConsoleColor]::Red;
        Predicate=
        {
            if($null -ne $_.Name)
            {
                $ext = $_.Name.ToLower()
                if($ext.EndsWith(".exe") -or $ext.EndsWith(".dll"))
                {
                    return $true
                }            
            }
            return $false
        }};          
       
    @{
        Color=[System.ConsoleColor]::DarkYellow;
        Predicate=
        {
            if($null -ne $_.Name)
            {
                $ext = $_.Name.ToLower()
                if($ext.EndsWith(".designer.cs") -or $ext.EndsWith(".resx"))
                {
                    return $true
                }            
            }
            return $false
        }};        
        
    @{
        Color=[System.ConsoleColor]::Green;
        Predicate=
        {
            if($null -ne $_.Name)
            {
                $ext = [System.IO.Path]::GetExtension($_.Name.ToLower())                
                if($codeextensions -contains $ext)
                {
                    return $true
                }
            }
            return $false
        }}        
)

invoke-expression "get-childitem $args" | color-item $filecolorpredicates