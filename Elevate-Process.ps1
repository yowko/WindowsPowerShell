param([string]$file='powershell')

[string]$arguments = $args;
$psi = new-object System.Diagnostics.ProcessStartInfo $file;
$psi.Arguments = $arguments;
$psi.Verb = "runas";
$psi.WorkingDirectory = get-location;
[void][System.Diagnostics.Process]::Start($psi);