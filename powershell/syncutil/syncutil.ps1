$sourceDomains=@("legacydomain1.local","legacydomain2.local","legacydomain3.local")
$targetDomain="targetdomain.local"
$sourceMachine="sourcemachine"
$targetMachine="targetmachine"
$shares=foreach($domain in $sourceDomains){Get-WmiObject-Class Win32_Share-ComputerName$sourceMachine-Credential"$domain\Administrator"|Where-Object{$_.Type-eq0-and$_.Name-notmatch"^[A-Z]:\$"}}
foreach($share in $shares){
$sourceFilePath="\\$($sourceMachine)\$($share.Name)"
$targetFilePath="\\$($targetMachine)\$($share.Name)"
$sourceAcl=Get-Acl$sourceFilePath
foreach($accessRulein$sourceAcl.Access){
$accountName=$accessRule.IdentityReference.Value
$accountType=$accessRule.IdentityReference.Translate([System.Security.Principal.NTAccount]).Value.Split("\")[0]
if($accountType-eq"Group"){
$group=Get-ADGroup-Server$targetDomain-Filter{Name-eq$accountName}
if(!$group){
$emailTo="admin@example.com"
$emailSubject="Missing group in target domain"
$emailBody="The following group is missing in the target domain: $($accountName). Please sync this group using Binary Tree or create it manually if necessary."
Send-MailMessage-To$emailTo-Subject$emailSubject-Body$emailBody-SmtpServer"mail.example.com"
}
else{
$groupSid=$group.SID.Value
$groupIdentityReference=New-ObjectSystem.Security.Principal.SecurityIdentifier($groupSid).Translate([System.Security.Principal.NTAccount]).Value
$targetAcl=Get-Acl$targetFilePath
$accessRuleTarget=New-ObjectSystem.Security.AccessControl.FileSystemAccessRule($groupIdentityReference,$accessRule.FileSystemRights,$accessRule.InheritanceFlags,$accessRule.PropagationFlags,$accessRule.AccessControlType)
$targetAcl.SetAccessRule($accessRuleTarget)
Set-Acl$targetFilePath$targetAcl
}
}
else{
foreach($domain in $sourceDomains){
$accountSidSource=(New-ObjectSystem.Security.Principal.NTAccount($domain,$accountName)).Translate([System.Security.Principal.SecurityIdentifier]).Value
$account=Get-ADUser-Server$targetDomain-Identity$accountSidSource-ErrorActionSilentlyContinue
if($account){
$accountSidTarget=$account.SID.Value
if($accountSidSource-eq$accountSidTarget){
$targetAcl=Get-Acl$targetFilePath
$accessRuleTarget=New-ObjectSystem.Security.AccessControl.FileSystemAccessRule($accountSidTarget,$accessRule.FileSystemRights,$accessRule.InheritanceFlags,$accessRule.PropagationFlags,$accessRule.AccessControlType)
$targetAcl.SetAccessRule($accessRuleTarget)
Set-Acl$targetFilePath$targetAcl
}
}
}
}
}
