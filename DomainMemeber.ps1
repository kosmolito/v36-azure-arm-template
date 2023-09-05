param (
    [Parameter(Mandatory=$true)][string]$domainName,
    [Parameter(Mandatory=$true)][string]$adminUsername,
    [Parameter(Mandatory=$true)][string]$AdminPassword
)

$DomainAdmin = $domainName + "\" + $adminUsername
$Password = ConvertTo-SecureString -String $AdminPassword -AsPlainText -Force
$DomainCredential = New-Object System.Management.Automation.PSCredential -ArgumentList $DomainAdmin, $Password

Add-Computer -DomainName $domainName -credential $DomainCredential -Restart