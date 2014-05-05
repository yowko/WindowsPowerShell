param
(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    $InputObject,
    
    [Parameter(Mandatory=$true, Position=0)]
    [string]$ValuePattern,
    
    [string[]]$Property,
    
    [switch]$Match
)

process
{
    if(-not $Property)
    {
        $inputObjectProperties = ($InputObject | get-member -membertype property | foreach{$_.Name})
    }        
    else
    {
        $inputObjectProperties = $Property
    }

    foreach ($inputObjectProperty in $inputObjectProperties)
    {
        if($Match)
        {
            if($InputObject.$inputObjectProperty -match $ValuePattern)
            {
                return $InputObject
            }                
        }
        else
        {
            if($InputObject.$inputObjectProperty -like $ValuePattern)
            {
                return $InputObject
            }                       
        }
    }        
}
