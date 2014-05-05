param
(
    [Parameter(Mandatory=$true, Position=0)]
    [System.Uri]
    $Url
)

$client = New-object System.Net.WebClient
$client.Headers.Add("User-Agent:Mozilla/4.0 (compatible; MSIE 7.0b; Windows NT 6.0)")
return [xml]$client.DownloadString($url)

