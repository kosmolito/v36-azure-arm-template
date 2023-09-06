param (
    [Parameter(Mandatory = $true)]
    [string]$DomainName,
    [Parameter(Mandatory = $true)]
    [string]$AdminUsername,
    [Parameter(Mandatory = $true)]
    [string]$AdminPassword
)

Configuration tenta4 {

$NetBiosName = $DomainName.Split(".")[0]
$DomainAdmin = $NetBiosName + "\" + $AdminUsername
$DomainAdminPassword = ConvertTo-SecureString -String $AdminPassword -AsPlainText -Force
$DomainAdminCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $DomainAdmin, $DomainAdminPassword

Import-DscResource -ModuleName PSDesiredStateConfiguration -ModuleVersion "1.1"
Import-DscResource -ModuleName xActiveDirectory -ModuleVersion "3.0.0.0"
Import-DscResource -ModuleName xNetworking -ModuleVersion "5.7.0.0"
Import-DscResource -ModuleName xDSCDomainjoin -ModuleVersion "1.2.23"

node dc01
{
    # Install Active Directory Domain Services
    WindowsFeature ADInstall {
        Ensure               = "Present"
        Name                 = "AD-Domain-Services"
        IncludeAllSubFeature = $true
    }
    # Install Active Directory Domain Services Tools
    WindowsFeature ADDSTools {
        Ensure    = "Present"
        Name      = "RSAT-ADDS"
        DependsOn = "[WindowsFeature]ADInstall"

    }
    # Install Active Directory PowerShell Module
    WindowsFeature "RSATADPowerShell" {
        Ensure    = "Present"
        Name      = "RSAT-AD-PowerShell"
        DependsOn = "[WindowsFeature]ADDSTools"
    }
    # Install Active Directory Tools
    WindowsFeature ActiveDirectoryTools {
        Ensure    = "Present"
        Name      = 'RSAT-AD-Tools'
        DependsOn = "[WindowsFeature]ADDSTools"
    }
    # Install DNS Server Tools
    WindowsFeature DNSServerTools {
        Ensure    = "Present"
        Name      = 'RSAT-DNS-Server'
        DependsOn = "[WindowsFeature]ActiveDirectoryTools"
    }
    # Install DNS Server
    WindowsFeature DNS {
        Ensure    = "Present"
        Name      = "DNS"
        DependsOn = "[WindowsFeature]DNSServerTools"
    }
    # Promote server to Domain Controller
    xADDomain Domain {
        DomainName                    = $DomainName
        DomainAdministratorCredential = $DomainAdminCredential
        SafemodeAdministratorPassword = $DomainAdminCredential
        DependsOn                     = "[WindowsFeature]ActiveDirectoryTools"
    }
}

Node win01 {

    xFirewall AllowPing {
        Name        = "Allow Ping"
        DisplayName = "Allow Ping"
        Action      = "Allow"
        Direction   = "Inbound"
        Protocol    = "ICMPv4"
    }

    xFirewall AllowNetwrokDiscovery {
        Name        = "Allow Netwrok Discovery"
        DisplayName = "Allow Netwrok Discovery"
        Action      = "Allow"
        Direction   = "Inbound"
        Protocol    = "UDP"
        LocalPort   = "3702"
        DependsOn   = "[xFirewall]AllowPing"
    }
    xDSCDomainjoin JoinDomain {
        Domain     = $DomainName
        Credential = $DomainAdminCredential
        DependsOn  = "[xFirewall]AllowNetwrokDiscovery"
    }

}
}

$ConfigData = @{
AllNodes = @(
    @{
        NodeName                    = "dc01"
        PSDscAllowPlainTextPassword = $true
        PSDscAllowDomainUser        = $true
    }

        @{
        NodeName                    = "win01"
        PSDscAllowPlainTextPassword = $true
        PSDscAllowDomainUser        = $true

    }
)
}

tenta4 -ConfigurationData $ConfigData -OutputPath C:\DSCConfig
Start-DscConfiguration -Path C:\DSCConfig -Wait -Verbose -Force
