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
    Import-DscResource -ModuleName xActiveDirectory
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

        # WaitForDisk Disk2 {
        #     DiskId = 2
        #     RetryIntervalSec = 60
        #     RetryCount = 20
        # }
        
        # Disk FVolume {
        #     DiskId = 2
        #     DriveLetter = 'F'
        #     FSLabel = 'Data'
        #     FSFormat = 'NTFS'
        #     DependsOn = '[WaitForDisk]Disk2'
        # }   

        # WindowsFeature DNS { 
        #     Ensure = "Present" 
        #     Name = "DNS"		
        # }

        # WindowsFeature DnsTools {
        #     Ensure = "Present"
        #     Name = "RSAT-DNS-Server"
        #     DependsOn = "[WindowsFeature]DNS"
        # }

        # TODO dynamically detect interface
        xDnsServerAddress DnsServerAddress { 
            Address = $DNSAddress,'8.8.8.8'
            InterfaceAlias = "Ethernet 2"
            AddressFamily  = 'IPv4'
        }

        WindowsFeature ADDSInstall { 
            Ensure = "Present" 
            Name = "AD-Domain-Services"
            DependsOn="[WindowsFeature]DNS" 
        } 

        WindowsFeature ADDSTools {
            Ensure = "Present"
            Name = "RSAT-ADDS-Tools"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }

        xWaitForADDomain DscForestWait { 
            DomainName = $DomainName 
            DomainUserCredential= $DomainCreds
            RetryCount = 30
            RetryIntervalSec = 60
            DependsOn = "[xDnsServerAddress]DnsServerAddress"
        }

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