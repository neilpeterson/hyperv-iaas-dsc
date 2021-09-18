configuration dhcp {
    
    param 
    ( 
         [Parameter(Mandatory)]
         [String]$DomainName,

         [Parameter(Mandatory)]
         [string]$DNSAddress
     ) 
     
     Import-DscResource -ModuleName PSDesiredStateConfiguration
     Import-DSCResource -ModuleName xDhcpServer
     Import-DscResource -ModuleName xActiveDirectory
     Import-DscResource -ModuleName xPendingReboot
     Import-DscResource -ModuleName xComputerManagement
 
     $Admincreds = Get-AutomationPSCredential 'Admincreds'
     [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
     
     Node localhost {
         
        WindowsFeature dhcp {
            Name = "DHCP"
            Ensure = "Present"
            IncludeAllSubFeature = $true 
        }

        WindowsFeature rsat-dhcp {
            Name = "RSAT-DHCP"
            Ensure = "Present"
            DependsOn = "[WindowsFeature]dhcp"
        }

        xComputer JoinDomain {
            Name = 'dhcp'
            DomainName    = $DomainName
            Credential    = $DomainCreds
            DependsOn = "[xWaitForADDomain]DscForestWait"
        }

        xPendingReboot Reboot2
        { 
            Name = "RebootServer"
            DependsOn = "[xComputer]JoinDomain"
        }

        xWaitForADDomain DscForestWait { 
            DomainName = $DomainName 
            DomainUserCredential= $DomainCreds
            RetryCount = 60
            RetryIntervalSec = 60
        }

        xDhcpServerScope Scope {
            DependsOn = '[WindowsFeature]dhcp'
            Ensure = 'Present'
            ScopeId = '192.168.0.0'
            IPStartRange = '192.168.0.10'
            IPEndRange = '192.168.0.50'
            Name = 'AzureNAT'
            SubnetMask = '255.255.255.0'
            LeaseDuration = '00:08:00'
            State = 'Active'
            AddressFamily = 'IPv4'
        } 

        xDhcpServerAuthorization autho {
            ensure='present'
            IsSingleInstance = 'Yes'
        }
    }
 }