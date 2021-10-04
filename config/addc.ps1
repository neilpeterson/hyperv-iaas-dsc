configuration addc {
    
   param 
   ( 
        [Parameter(Mandatory)]
        [String]$DomainName
    ) 
    
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DSCResource -ModuleName StorageDsc
    Import-DscResource -ModuleName ActiveDirectoryDsc
    Import-DscResource -ModuleName NetworkingDsc
    Import-DscResource -ModuleName xPendingReboot

    $Admincreds = Get-AutomationPSCredential 'Admincreds'
    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
    
    Node localhost {
        
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
         
        ADDomain FirstDS {
            DomainName = $DomainName
            Credential = $DomainCreds
            SafemodeAdministratorPassword = $DomainCreds
            DatabasePath = "F:\NTDS"
            LogPath = "F:\NTDS"
            SysvolPath = "F:\SYSVOL"
	        DependsOn = @("[WindowsFeature]ADDSInstall")
        } 

        xPendingReboot Reboot { 
            Name = "RebootServer"
            DependsOn = "[ADDomain]FirstDS"
        }
   }
} 