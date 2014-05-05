param([string]$color=$(throw "Must specify a color"))

$host.UI.RawUI.BackgroundColor = $color