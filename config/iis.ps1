Configuration iis {

    Import-DscResource -ModuleName PsDesiredStateConfiguration
    Import-DscResource -ModuleName ActiveDirectoryDsc
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
            Address = '8.8.8.8'
            InterfaceAlias = "Ethernet 2"
            AddressFamily  = 'IPv4'
        }

        File updateDemo {
            Ensure = "Present"
            Type = "Directory"
            DestinationPath = "C:\update-demo\"
        }

        File updateDemoTwo {
            Ensure = "Present"
            Type = "Directory"
            DestinationPath = "C:\update-demo-two\"
        }
    }
}