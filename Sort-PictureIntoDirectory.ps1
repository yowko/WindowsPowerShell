function addDateTakenMember
{
	param (
		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $true)]
		$FileInfo
	)

	begin {
		add-type -AssemblyName System.Drawing
	}

	process {
		$dateTaken = $null   
		$fileStream = $null
		$image = $null
		try
		{
			$fileStream = new-object System.IO.FileStream $FileInfo.FullName, "Open", "Read"
			$image = [System.Drawing.Image]::FromStream($fileStream, $false, $false)
			$dateTakenString = [System.Text.Encoding]::UTF8.GetString($image.GetPropertyItem(36867).Value)
			$dateTakenString = ($dateTakenString -split " ")[0]
			$dateTakenString = $dateTakenString -replace ":","-"
			$dateTaken = [datetime]$dateTakenString    
		}
		catch
		{
		}
		finally
		{
			if($null -ne $image)
			{
				$image.Dispose()
				$image = $null        
			}

			if($null -ne $fileStream)
			{
				$fileStream.Dispose()
				$fileStream = $null
			}
		}
		
		Add-Member -InputObject $FileInfo -MemberType NoteProperty -Name DateTaken -Value $dateTaken -PassThru
	}
}

dir |
	where { -not $_.PSIsContainer } |
	addDateTakenMember |
	foreach {
		$destDir = "$($_.DateTaken.Year)-$($_.DateTaken.Month.ToString('D2'))-$($_.DateTaken.Day.ToString('D2'))"
		if(-not (Test-Path $destDir -PathType "Container"))
		{
			Write-Host "Creating directory: $destDir"
			mkdir $destDir | Out-Null
		}
		
		$destPath = Join-Path $destDir $_.Name
		
		Write-Host "Moving $($_.Name) to $destPath"
		move $_ $destPath
	}