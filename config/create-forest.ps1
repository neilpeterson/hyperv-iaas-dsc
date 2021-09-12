configuration ADDC {
    
   param 
   ( 
        [Parameter(Mandatory)]
        [String]$DomainName

    ) 
    
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DSCResource -ModuleName StorageDsc
    Import-DscResource -ModuleName xActiveDirectory
    Import-DscResource -ModuleName xNetworking
    Import-DscResource -ModuleName xPendingReboot

    # Pulls admin credentials from Azure Automation object, used on the VM and domain authentication.
    $Admincreds = Get-AutomationPSCredential 'Admincreds'
    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
    
    # Configuration is compiled in Azure Automation, this will not work.
    # TODO this needs to be fixed.
    # $Interface = Get-NetAdapter | Where Name -Like "Ethernet*" | Select-Object -First 1

    Node localhost
    {
        LocalConfigurationManager 
        {
            ActionAfterReboot = 'ContinueConfiguration'            
            ConfigurationMode = 'ApplyAndAutoCorrect'
            RebootNodeIfNeeded = $true
        }

        # TODO add disk to Azure deployment
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

        WindowsFeature ADAdminCenter {
            Ensure = "Present"
            Name = "RSAT-AD-AdminCenter"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }
         
        xADDomain FirstDS {
            DomainName = $DomainName
            DomainAdministratorCredential = $DomainCreds
            SafemodeAdministratorPassword = $DomainCreds
            DatabasePath = "C:\NTDS"
            LogPath = "C:\NTDS"
            SysvolPath = "C:\SYSVOL"
	        DependsOn = @("[WindowsFeature]ADDSInstall")
        } 

   }
} 