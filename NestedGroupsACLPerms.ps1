import-module activedirectory

$Results = @()
    $input = Read-Host "Enter Path: "
    $Path = Get-Item -Path $input
    $Acl = Get-Acl $Path
    foreach ($Access in $acl.Access) 
    {
        $Properties = [ordered]@{'FolderName'=$Path;'Principle'=$Access.IdentityReference;'Permissions'=$Access.FileSystemRights;'AccessControlType'=$Access.AccessControlType;'Inherited'=$Access.IsInherited}
        $Results += New-Object -TypeName PSObject -Property $Properties
    
        $groups = Get-ADGroup -Filter *
        foreach ($group in $groups)
        {
            $concat = $env:USERDOMAIN, $group.name -join"\"
            $concatBN = "BUILTIN",$group.name -join"\"

            if (($Properties.principle -eq $concat) -or ($Properties.principle -eq $concatBN))
            {
             Write-Host "GroupMembers By Principle: "$Properties.principle -Fore Cyan
             Get-GroupHierarchy $group.name
            }
        }
        
    }
    Write-Host "----------"
    Write-Host "Principle ACLs: "-Fore Cyan
    $Results | Ft 

    
