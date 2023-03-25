PowerShell Script to Mirror Permissions on Files and Folders with File Shares
This PowerShell script automates the process of mirroring permissions on files and folders with file shares for users across two domains that have a full trust. The users have accounts in both domains, and the shares are in the legacy domain while the user devices are in the target domain.

Setup
To use the script, set the source and target domains and machine names at the beginning of the script.

Usage
The script gets the list of shares on the source machine and loops through each share found. For each share, it sets the source and target file paths and gets the source ACL.

The script then loops through each access rule in the source ACL and gets the account name and type (user or group) from the access rule. If the account type is a group, it checks if the group exists in the target domain. If the group does not exist, it sends an email. If the group exists, it gets the group's identity reference in the target domain and creates a new access rule using the group's identity reference.

If the account type is a user, the script gets the account SID from the source domain and gets the account in the target domain. If the account exists, it gets the account SID from the target domain and checks if the account SIDs match. If the account SIDs match, it creates a new access rule using the account's SID.

Finally, the script sets the access rule in the target ACL and sets the ACL on the target file path.

Requirements
The script requires PowerShell version 3.0 or later and the Active Directory PowerShell module. The script should be run as a user with permissions to read the source ACLs and write the target ACLs.
