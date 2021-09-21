configuration rodc {
    
   param 
   ( 
        [Parameter(Mandatory)]
        [String]$DomainName,

        [Parameter(Mandatory)]
        [string]$DNSAddress
    ) 
    
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DSCResource -ModuleName StorageDsc
    Import-DscResource -ModuleName ActiveDirectoryDsc
    Import-DscResource -ModuleName xNetworking
    Import-DscResource -ModuleName xPendingReboot

    $Admincreds = Get-AutomationPSCredential 'Admincreds'
    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
    
    Node localhost
    {
        LocalConfigurationManager {
            ActionAfterReboot = 'ContinueConfiguration'            
            ConfigurationMode = 'ApplyAndAutoCorrect'
            RebootNodeIfNeeded = $true
        }

        # TODO dynamically detect interface
        xDnsServerAddress DnsServerAddress { 
            Address = $DNSAddress,'8.8.8.8'
            InterfaceAlias = "Ethernet 2"
            AddressFamily  = 'IPv4'
        }

        WindowsFeature ADDSInstall { 
            Ensure = "Present" 
            Name = "AD-Domain-Services"
        } 

        WindowsFeature ADDSTools {
            Ensure = "Present"
            Name = "RSAT-ADDS-Tools"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }

        WaitForADDomain DscForestWait { 
            DomainName = $DomainName
            PsDscRunAsCredential = $DomainCreds
            # DomainUserCredential= $DomainCreds
            # RetryCount = 30
            # RetryIntervalSec = 60
            DependsOn = "[xDnsServerAddress]DnsServerAddress"
        }

        # I am hitting this, but should be using the latest package
        # https://github.com/dsccommunity/ActiveDirectoryDsc/issues/611
        ADDomainController RODC {
            DomainName = $DomainName
            Credential = $DomainCreds
            SafemodeAdministratorPassword = $DomainCreds
            ReadOnlyReplica = $true
            SiteName = "Default-First-Site-Name"
            DependsOn = @("[xWaitForADDomain]DscForestWait")
        } 

        xPendingReboot Reboot { 
            Name = "RebootServer"
            DependsOn = "[ADDomainController]RODC"
        }
   }
} 