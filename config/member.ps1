Configuration member {

    param
    (
        [Parameter(Mandatory)]
        [string]$DomainName,

        [Parameter(Mandatory)]
        [string]$DNSAddress
    )

    Import-DscResource -ModuleName PsDesiredStateConfiguration
    Import-DscResource -ModuleName ActiveDirectoryDsc
    Import-DscResource -ModuleName xComputerManagement
    Import-DscResource -ModuleName NetworkingDsc
    Import-DscResource -ModuleName xPendingReboot

    $Admincreds = Get-AutomationPSCredential 'Admincreds'
    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)

    node localhost {
        
        WindowsFeature IIS {
            Ensure = 'Present'
            Name   = 'Web-Server'
        }

        # TODO dynamically detect interface
        DnsServerAddress DnsServerAddress { 
            Address = $DNSAddress,'8.8.8.8'
            InterfaceAlias = "Ethernet 2"
            AddressFamily  = 'IPv4'
        }

        WaitForADDomain DscForestWait { 
            DomainName = $DomainName 
            Credential = $DomainCreds
            DependsOn = "[DnsServerAddress]DnsServerAddress"
        }
            
        xComputer JoinDomain {
            Name = $ComputerName
            DomainName = $DomainName
            Credential = $DomainCreds
            DependsOn = "[WaitForADDomain]DscForestWait"
        }

        xPendingReboot Reboot { 
            Name = "RebootServer"
            DependsOn = "[xComputer]JoinDomain"
        }
    }
}