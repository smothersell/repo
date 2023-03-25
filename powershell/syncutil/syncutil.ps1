$sourceDomain = "legacydomain.local"
$targetDomain = "targetdomain.local"
$sourceMachine = "sourcemachine"
$targetMachine = "targetmachine"
$shares = Get-WmiObject -Class Win32_Share -ComputerName $sourceMachine | Where-Object { $_.Type -eq 0 -and $_.Name -notmatch "^[A-Z]:\$" }
foreach ($share in $shares) {
    $sourceFilePath = "\\$($sourceMachine)\$($share.Name)"
    $targetFilePath = "\\$($targetMachine)\$($share.Name)"
    $sourceAcl = Get-Acl $sourceFilePath
    foreach ($accessRule in $sourceAcl.Access) {
        $accountName = $accessRule.IdentityReference.Value
        $accountType = $accessRule.IdentityReference.Translate([System.Security.Principal.NTAccount]).Value.Split("\")[0]
        if ($accountType -eq "Group") {
            $group = Get-ADGroup -Server $targetDomain -Filter { Name -eq $accountName }
            if (!$group) {
                $emailTo = "admin@example.com"
                $emailSubject = "Missing group in target domain"
                $emailBody = "The following group is missing in the target domain: $($accountName). Please sync this group using Binary Tree or create it manually if necessary."
                Send-MailMessage -To $emailTo -Subject $emailSubject -Body $emailBody -SmtpServer "mail.example.com"
            }
            else {
                $groupSid = $group.SID.Value
                $groupIdentityReference = New-Object System.Security.Principal.SecurityIdentifier($groupSid).Translate([System.Security.Principal.NTAccount]).Value
                $targetAcl = Get-Acl $targetFilePath
                $accessRuleTarget = New-Object System.Security.AccessControl.FileSystemAccessRule($groupIdentityReference, $accessRule.FileSystemRights, $accessRule.InheritanceFlags, $accessRule.PropagationFlags, $accessRule.AccessControlType)
                $targetAcl.SetAccessRule($accessRuleTarget)
                Set-Acl $targetFilePath $targetAcl
            }
        }
        else {
            $accountSidSource = (New-Object System.Security.Principal.NTAccount($sourceDomain, $accountName)).Translate([System.Security.Principal.SecurityIdentifier]).Value
            $account = Get-ADUser -Server $targetDomain -Identity $accountSidSource -ErrorAction SilentlyContinue
            if ($account) {
                $accountSidTarget = $account.SID.Value
                if ($accountSidSource -eq $accountSidTarget) {
                    $targetAcl = Get-Acl $targetFilePath
                    $accessRuleTarget = New-Object System.Security.AccessControl.FileSystemAccessRule($accountSidTarget, $accessRule.FileSystemRights, $accessRule.InheritanceFlags, $accessRule.PropagationFlags, $accessRule.AccessControlType)
                    $targetAcl.SetAccessRule($accessRuleTarget)
                    Set-Acl $targetFilePath $targetAcl
                }
            }
        }
    }
}
