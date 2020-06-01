#Takes a user and path and outputs user permissions, whether stand alone, as a group member, or as a nested group member

#Output explanation:
#If ParentGroup and ChildGroup is none then the AD user is a direct member for the path given
#If ParentGroup is populated and ChildGroup is not populated it means the AD user given is a member of that group
#If ParentGroup and ChildGroup is populated it means the user is nested more than 1 group down, and the ChildGroup is the group the AD user is a member of
#To get GroupHierarchy run the Get-GroupHierarchy function. Would recommend doing this for the manufacturing and Administrators groups to see what the hierarchy between parent and child looks like
#Permissions are sorted first by Inheritance, True listed first, and then sorted by AccessControlType, Deny listed first.
#Still need to work on the nuances of Windows permission structure. Ideally want the permissions sorts by effective access

#Empty array used to capture all the permissions where $userInput is a member of
$Perms = @()

#User input for object path location and AD user to review permissions
$Path = Read-Host "Enter Path: "
$userInput = Read-Host "Enter User: "

#Used to get all the AD groups, which will later be used to identify where AD user is a group member
$ADgroups = Get-ADGroup -Filter *

#Gets the access control list for the path, focusing on the Access parameter to see what permissions the AD user has
$ACL = Get-ACL $Path | select -expand access

#Provides some general environment information: AD User, Domain Name, Path of interest
Write-Host ("-"*10) -Fore Yellow
Write-Host "User Lookup:"$userInput -Fore Cyan
Write-Host "Domain Name:"$env:USERDOMAIN -Fore Cyan
Write-Host "Object Path:"$Path -Fore Cyan
Write-Host ("-"*10) -Fore Yellow

#ForEach is being used to get through every principal within the path given
    foreach ($principal in $ACL)
        {
        #Separates the Domain from the user name
        $principalName = ($principal.IdentityReference -split "\\")[1]
        #If the AD user is listed within the ACL of the path given, get all the permissions information from that user
        if ($principalName -eq $userInput)
            {
            #Properties is gathering the data that will later be added to the $Perms array. ParentGroup is the group that is listed within the ACL of the path, ChildGroup is the nested group that has the AD user as a member
            $Properties = [ordered]@{'Path'=$Path;'Principal'=$principalName;'ParentGroup'='None';'ChildGroup'='None';'Permissions'=$principal.FileSystemRights;'AccessControlType'=$principal.AccessControlType;'Inherited'=$principal.IsInherited}
            $Perms += New-Object -TypeName PSObject -Property $Properties
            }
            #If the AD user is not listed within the ACL of the path given, but there are groups within that path, start gathering information on that group
            if ($ADgroups.name -contains $principalName)
                {
                #Get all the group member of that group
                $groupMembers = Get-ADGroupMember $principalName
                #For each group member, let's see if one is the AD user
                foreach ($groupMember in $groupMembers)
                    {
                    #if AD user is a member of the group, get all the data for the user, parent group, child group, and permissions based on the Parent Group and add to the Perms Array
                    if ($groupMember.name -eq $userInput)
                        {
                        $gMember = [ordered]@{'Path'=$Path;'Principal'=$userInput;'ParentGroup'=$principalName;'ChildGroup'='None';'Permissions'=$principal.FileSystemRights;'AccessControlType'=$principal.AccessControlType;'Inherited'=$principal.IsInherited}
                        $Perms += New-Object -TypeName PSObject -Property $gMember
                        }
                    #if AD user is not a member of that group, but the group contains group members that are groups, do a loop through all groups that are group members. Do/while loop is used to do this for all groups 
                    #that are nested. if the nested group has the AD user as a member it will add to the Perms array, if not it will continue on until all nested groups are searched through. Once there are no more
                    #groups the while loop returns false and breaks, going back up to the principals that are in the path ACL and executes through the process again
                    elseif ($ADgroups.name -contains $groupMember.name)
                        {
                        do
                            {
                            $nestedGroupMembers = Get-ADGroupMember $groupMember
                            foreach ($nestedMember in $nestedGroupMembers)
                                {
                                if ($nestedMember.name -eq $userInput)
                                    {
                                    $nestedGMember = [ordered]@{'Path'=$Path;'Principal'=$userInput;'ParentGroup'=$principalName;'ChildGroup'=$groupMember.name;'Permissions'=$principal.FileSystemRights;'AccessControlType'=$principal.AccessControlType;'Inherited'=$principal.IsInherited}
                                    $Perms += New-Object -TypeName PSObject -Property $nestedGMember
                                    }
                                elseif ($ADgroups.name -contains $nestedMember.name)
                                    {
                                    $loopNested = Get-ADGroupMember $nestedMember
                                    foreach ($nested in $loopNested)
                                        {
                                            if ($ADgroups.name -contains $nested.name)
                                                {
                                                $finalNest = Get-ADGroupMember $nested
                                                    foreach ($member in $finalNest.name)
                                                    {
                                                    if ($member -eq $userInput)
                                                        {
                                                        $nestedUMember = [ordered]@{'Path'=$Path;'Principal'=$userInput;'ParentGroup'=$principalName;'ChildGroup'=$nested.name;'Permissions'=$principal.FileSystemRights;'AccessControlType'=$principal.AccessControlType;'Inherited'=$principal.IsInherited}
                                                        $Perms += New-Object -TypeName PSObject -Property $nestedUMember
                                                        }
                                                    else
                                                        {
                                                        continue
                                                        }
                                                    } 
                                                }
                                            else
                                                {
                                                continue
                                                }
                                        }
                                    }
                                }
                            
                            }
                            while ($ADgroups.name -contains $nestedMember)
                        }
                }
       }
       
    }
    $Perms | Sort-Object -Property Inherited | Sort-Object AccessControlType -Descending | Fl
