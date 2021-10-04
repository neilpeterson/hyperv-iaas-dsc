Configuration iis {

    Import-DscResource -ModuleName PsDesiredStateConfiguration
    Import-DscResource -ModuleName NetworkingDsc

    node localhost {
        
        WindowsFeature IIS {
            Ensure = 'Present'
            Name   = 'Web-Server'
        }

        # TODO dynamically detect interface
        DnsServerAddress DnsServerAddress { 
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