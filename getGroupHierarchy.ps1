import-module activedirectory

$GroupList = @{}
$indent = ""

function Get-GroupHierarchy
{
    param
        (
            [Parameter(Mandatory=$true)]
            [String]$groupName
        ) 

    $groupMember = get-adgroupmember $groupName | sort-object objectClass -descending
    foreach ($member in $groupMember)
    {
        Write-Host $indent $groupName, ":",$member.objectClass,":", $member.name;
    
        if (!($groupList.containsKey($member.name)))
        {
                if ($member.objectClass -eq "group")
                    {
                        $groupList.add($member.name,$member.name)
                        $indent += "`t"
                        Get-GroupHierarchy $member.name
                        $indent = "`t" * ($indent.length - 1)  
                    }
        }
            Else
            {
                Write-Host $indent "Group:" $member.name "has already been processed. If you get this output then re-run Get-GroupHierarchy and Get-NestedACLPerms"
            }
    }
}
