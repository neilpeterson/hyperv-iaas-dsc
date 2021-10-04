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
    Import-DscResource -ModuleName NetworkingDsc
    Import-DscResource -ModuleName xPendingReboot

    $Admincreds = Get-AutomationPSCredential 'Admincreds'
    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
    
    Node localhost
    {

        # TODO dynamically detect interface
        DnsServerAddress DnsServerAddress { 
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
            Credential = $DomainCreds
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
            # DependsOn = @("[WaitForADDomain]DscForestWait")
        } 

        xPendingReboot Reboot { 
            Name = "RebootServer"
            DependsOn = "[ADDomainController]RODC"
        }
   }
} 