import-module activedirectory

$GroupList = @{}
$indent = ""

    $all = Get-ADGroup -Filter *
    foreach ($group in $all)
        {
            $groupMember = get-adgroupmember $group.name| select name,objectClass | sort-object objectClass -descending
            foreach ($member in $groupMember)
                {
                Write-Host $group.name,":",$member.objectClass,":", $member.name;
                if (!($GroupList.ContainsKey($member.name)))
                {
                if ($member.objectClass -eq "group")
                    {
                    $GroupList.add($member.name,$member.name)
                    $indent += "`t"
                    Get-GroupHierarchy $member.name
                    $indent = "`t" * ($indent.length - 1)
                   }                   
                }
                 Else
            {
                Write-Host $indent "Group:" $member.name "has already been processed, or there is loop... Please verify."  -Fore DarkYellow
            }
         }       
                
        }
    