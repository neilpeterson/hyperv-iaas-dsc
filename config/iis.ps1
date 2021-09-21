Configuration iis {

    param
    (
        [Parameter(Mandatory)]
        [string]$DomainName,

        [Parameter(Mandatory)]
        [string]$DNSAddress
    )

    Import-DscResource -ModuleName PsDesiredStateConfiguration
    Import-DscResource -ModuleName xActiveDirectory
    Import-DscResource -ModuleName xComputerManagement
    Import-DscResource -ModuleName xNetworking
    Import-DscResource -ModuleName xPendingReboot

    $Admincreds = Get-AutomationPSCredential 'Admincreds'
    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)

    node localhost {
        
        WindowsFeature IIS {
            Ensure = 'Present'
            Name   = 'Web-Server'
        }

        # TODO dynamically detect interface
        xDnsServerAddress DnsServerAddress { 
            Address = $DNSAddress,'8.8.8.8'
            InterfaceAlias = "Ethernet 2"
            AddressFamily  = 'IPv4'
        }

        xWaitForADDomain DscForestWait { 
            DomainName = $DomainName 
            DomainUserCredential= $DomainCreds
            RetryCount = 30
            RetryIntervalSec = 60
            DependsOn = "[xDnsServerAddress]DnsServerAddress"
        }
            
        xComputer JoinDomain {
            Name = $ComputerName
            DomainName = $DomainName
            Credential = $DomainCreds
            DependsOn = "[xWaitForADDomain]DscForestWait"
        }

        xPendingReboot Reboot { 
            Name = "RebootServer"
            DependsOn = "[xComputer]JoinDomain"
        }
    }
}