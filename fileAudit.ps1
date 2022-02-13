Write-Host ''
Write-Host ('*' * 25)
Write-Host 'Configure GPO (Local Only)'
Write-Host ('*' * 25)
Write-Host ''
#Prompt User input for if they want to change their Object Access GPO and do a loop until the input is either Y or N (not case sensitive)
do {$SetObjectAccess = Read-Host -Prompt 'Do you want to make changes to Object Access GPO? (Y/N)'} 
until (($SetObjectAccess -eq 'Y') -or ($SetObjectAccess -eq 'N'))

#Step through to determine audit changes for success and failure

If ($SetObjectAccess -eq 'Y')
{
    #Ask for user input and do a loop until the input matches int 1-4
    do {$auditSettings = Read-Host -Prompt 'Enable SuccessAudit Only (1), Enable FailureAudit Only (2), Enable Both (3), Disable Both (4)'}
    until (($auditSettings -eq '1') -or ($auditSettings -eq '2') -or ($auditSettings -eq '3') -or ($auditSettings -eq '4'))
    If ($auditSettings -eq '1')
    {
    auditpol /set /Category:"Object Access" /failure:disable /success:enable
    }
    elseif ($auditSettings -eq '2')
    {
    auditpol /set /Category:'Object Access' /failure:enable /success:disable
    }
    elseif ($auditSettings -eq '3')
    {
    auditpol /set /Category:'Object Access' /failure:enable /success:enable
    }
    else
    {
    auditpol /set /Category:'Object Access' /failure:disable /success:disable
    }
}
Write-Host ''
Write-Host ('*' * 25)
Write-Host 'Choose your senstive data target(s)'
Write-Host ('*' * 25)   
Write-Host '' 
do {$auditType = Read-Host -Prompt 'Audit Object (1), Audit Folders and Subfolders (2), Audit multiple objects; different locations (3)'}
until (($auditType -eq '1') -or ($auditType -eq '2') -or ($auditType -eq '3'))

    if ($auditType -eq '1')
    {
    $objAudit = Read-Host -Prompt 'Enter object path'
    $fOutput = Get-ACL -path $objAudit -Audit | select PSParentPath, PSChildname, PSDrive, Owner, Group, Sddl, AccessToString, AuditToString, AreAccessRulesProtected, AreAuditRulesProtected, AreAccessRulesCanonical, AreAuditRulesCanonical | Out-GridView 
    }
    elseif ($auditType -eq '2')
    {
    $rObjAudit = Read-Host -Prompt 'Enter parent directory'
    $rObjOutput = Get-ChildItem $rObjAudit -Recurse
    $fOutput = foreach ($obj in $rObjOutput)
        {
        Get-ACL -path $obj.fullname -Audit  
        }
    $fOutput | select PSParentPath, PSChildname, PSDrive, Owner, Group, Sddl, AccessToString, AuditToString, AreAccessRulesProtected, AreAuditRulesProtected, AreAccessRulesCanonical, AreAuditRulesCanonical | Out-GridView
    }
    else
    {
    $mObjAudit = (Read-Host -path 'Enter all file paths, separated by a comma') -split ','
    $fOutput = foreach ($obj in $mObjAudit)
        {
        Get-ACL $obj.trim() -Audit  
        }
    $fOutput | select PSParentPath, PSChildname, PSDrive, Owner, Group, Sddl, AccessToString, AuditToString, AreAccessRulesProtected, AreAuditRulesProtected, AreAccessRulesCanonical, AreAuditRulesCanonical | Out-GridView
    }

Write-Host ''
Write-Host ('*' * 25)
Write-Host 'Review File output and determine if there are any settings you would like to change - Not currently working for changing so enter N'
Write-Host ('*' * 25)    
Write-Host ''

do {$aclReview = Read-Host -prompt 'Are there any objects that should have their settings changed? (Y/N)'}
until (($aclReview -eq 'Y') -or ($aclReview -eq 'N'))

Write-Host ''
Write-Host ('*' * 25)
Write-Host 'Get all Security Events with EventID 4668 last 2 hours (limited functionality; static)'
Write-Host ('*' * 25)
Write-Host ''
    If ($aclReview -eq 'N')
    {
    $eventLog = Get-EventLog -LogName Security -After (Get-Date).AddHours(-2)| Where-Object {$_.EventID -eq (4663)} | select TimeGenerated,EntryType,@{Name="SID";Expression={$_.ReplacementStrings[0]}},@{Name="Username";Expression={$_.ReplacementStrings[1]}}, @{Name="DomainName";Expression={$_.ReplacementStrings[2]}},EventID,@{Name="ObjName";Expression={ $_.ReplacementStrings[6] }}
    $eventLog | Out-GridView
    }
    else
    {
    Write-Host ''
    Write-Host '*************'
    Write-Host 'Let me Finish'
    Write-Host '*************'
    }

#can be any user or groupfl 
#$principal= Read-Host -prompt 'Who should have access audited? (Recommend Set to Everyone)'
#$AccessRule = New-Object System.Security.AccessControl.FileSystemAuditRule($principal,"ReadAndExecute","None","None",("Failure","Success"))

#$acl.SetAuditRule($AccessRule)
#$acl | Set-ACL $fileAudit -ErrorAction Stop
break
#$objACL | select PSParentPath, PSChildname, PSDrive, Owner, Group, Sddl, AccessToString, AuditToString, AreAccessRulesProtected, AreAuditRulesProtected, AreAccessRulesCanonical, AreAuditRulesCanonical | Out-GridView 

