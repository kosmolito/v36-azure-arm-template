# The script is used to create a new domain controller in Azure
# Credentials are stored in Azure Automation Assets
# The script is used in Azure Automation DSC, it will be triggered by ARM template

configuration DomainController {
    param (
        [Parameter(Mandatory)]
        $DomainName,
        [Parameter(Mandatory)]
        $DomainAdminCredential
    )

    Import-DscResource -ModuleName xActiveDirectory
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    $DomainAdministratorCredential  = (Get-AutomationPSCredential -Name $DomainAdminCredential)

    node localhost
    {
        # Install Active Directory Domain Services
        WindowsFeature ADInstall {
            Ensure                  = "Present"
            Name                    = "AD-Domain-Services"
            IncludeAllSubFeature    = $true
        }
        # Install Active Directory Domain Services Tools
        WindowsFeature ADDSTools
        {
            Ensure      = "Present"
            Name        = "RSAT-ADDS"
            DependsOn   = "[WindowsFeature]ADInstall"

        }
        # Install Active Directory PowerShell Module
        WindowsFeature "RSATADPowerShell"
        {
            Ensure      = "Present"
            Name        = "RSAT-AD-PowerShell"
            DependsOn   = "[WindowsFeature]ADDSTools"
        }
        # Install Active Directory Tools
        WindowsFeature ActiveDirectoryTools {
            Ensure      = "Present"
            Name        = 'RSAT-AD-Tools'
            DependsOn   = "[WindowsFeature]ADDSTools"
        }
        # Install DNS Server Tools
        WindowsFeature DNSServerTools {
            Ensure      = "Present"
            Name        = 'RSAT-DNS-Server'
            DependsOn   = "[WindowsFeature]ActiveDirectoryTools"
        }
        # Install DNS Server
        WindowsFeature DNS
        {
            Ensure      = "Present"
            Name        = "DNS"
            DependsOn   = "[WindowsFeature]DNSServerTools"
        }
        # Promote server to Domain Controller
        xADDomain Domain {
            DomainName                      = $DomainName
            DomainAdministratorCredential   = $DomainAdministratorCredential
            SafemodeAdministratorPassword   = $DomainAdministratorCredential
            DependsOn                       = "[WindowsFeature]ActiveDirectoryTools"
        }
    }
}
