$path = Read-Host "Enter path: "
$acl = Get-ACL $path
$dacl = ConvertFrom-SddlString -Sddl $acl.Sddl | Foreach-Object {$_.DiscretionaryACL}
Write-Host ("-" * 10) -Fore Cyan
Write-Host "Advanced Permissions for"$path -Fore Yellow
foreach ($principal in $dacl)
    { 
    $split = $principal -split " "
    $aces = $split.Trim(",",")","(",":")
    Write-Host ("-" * 10) -Fore Cyan
    Write-Host ""
    Write-Host "Principal:"$aces[0] -Fore Cyan
    Write-Host "Allow/Deny:"$aces[1] -Fore Cyan
    Write-Host ""
    $aces[2..($aces.length -1)] | Get-Unique
    }
