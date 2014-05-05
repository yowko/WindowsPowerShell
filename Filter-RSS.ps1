param([scriptblock]$filter=$(throw "Please specify a filter script block"))

function filterFeedItems
{
 param([xml]$feed)

 $items = ($feed.rss.channel.SelectNodes("item") | where {-not $filter.Invoke()})
 if($null -ne $items){foreach ($item in $items) {$item.get_ParentNode().RemoveChild($item) | out-null }}
 return $feed
}

$input | foreach { filterFeedItems($_)}


