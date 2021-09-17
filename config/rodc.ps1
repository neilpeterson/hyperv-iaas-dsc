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
    
    # Configuration is compiled in Azure Automation, this will not work.
    # TODO this needs to be fixed.
    # $Interface = Get-NetAdapter | Where Name -Like "Ethernet*" | Select-Object -First 1

    Node localhost
    {
        LocalConfigurationManager {
            ActionAfterReboot = 'ContinueConfiguration'            
            ConfigurationMode = 'ApplyAndAutoCorrect'
            RebootNodeIfNeeded = $true
        }

        WaitForDisk Disk2 {
            DiskId = 2
            RetryIntervalSec = 60
            RetryCount = 20
        }
        
        Disk FVolume {
            DiskId = 2
            DriveLetter = 'F'
            FSLabel = 'Data'
            FSFormat = 'NTFS'
            DependsOn = '[WaitForDisk]Disk2'
        }   

        WindowsFeature DNS { 
            Ensure = "Present" 
            Name = "DNS"		
        }

        WindowsFeature DnsTools {
            Ensure = "Present"
            Name = "RSAT-DNS-Server"
            DependsOn = "[WindowsFeature]DNS"
        }

        # xDnsServerAddress DnsServerAddress { 
        #     Address        = '127.0.0.1' 
        #     # InterfaceAlias = $Interface.Name
        #     # InterfaceAlias = Get-NetAdapter | Where Name -Like "Ethernet*" | Select-Object -First 1
        #     InterfaceAlias = "Ethernet 2"
        #     AddressFamily  = 'IPv4'
        #     DependsOn = "[WindowsFeature]DNS"
        # }

        # WindowsFeature ADAdminCenter {
        #     Ensure = "Present"
        #     Name = "RSAT-AD-AdminCenter"
        #     DependsOn = "[WindowsFeature]ADDSInstall"
        # }
            
        # xADDomain FirstDS {
        #     DomainName = $DomainName
        #     DomainAdministratorCredential = $DomainCreds
        #     SafemodeAdministratorPassword = $DomainCreds
        #     DatabasePath = "F:\NTDS"
        #     LogPath = "F:\NTDS"
        #     SysvolPath = "F:\SYSVOL"
        #     DependsOn = @("[WindowsFeature]ADDSInstall")
        # } 

        xDnsServerAddress DnsServerAddress { 
            Address = $DNSAddress,'8.8.8.8'
            # InterfaceAlias = $Interface.Name
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

        ADDomainController RODC {
            DomainName = $DomainName
            Credential = $DomainCreds
            SafemodeAdministratorPassword = $DomainCreds
            DatabasePath = "F:\NTDS"
            LogPath = "F:\NTDS"
            SysvolPath = "F:\SYSVOL"
            SiteName = "Default"
            ReadOnlyReplica = $true
            DependsOn = @("[WindowsFeature]ADDSInstall")
        } 

        xPendingReboot Reboot { 
            Name = "RebootServer"
            DependsOn = "[ADDomainController]RODC"
        }
   }
} 