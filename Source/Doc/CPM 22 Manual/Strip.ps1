function StripFile($Filename)
{
	$Content = Get-Content "${Filename}.prn"
#	$Content = $Content -replace "\0", ""
#	$Content = $Content -replace "\e.", ""
	$Content = $Content -replace "\x1A", ""
	Set-Content "${Filename}.txt" $Content[0..($Content.count - 3)]
}

StripFile("part1")
StripFile("part2")
StripFile("part3")

return
