configuration windowsfeatures {

    Import-DscResource -ModuleName PsDesiredStateConfiguration
    Import-DscResource –ModuleName xHyper-V

    node localhost {

        WindowsFeature WebServer {
            Ensure = "Present"
            Name = "Hyper-V"
            IncludeAllSubFeature = $true
        }

        File VMsDirectory {
            Ensure = 'Present'
            Type = 'Directory'
            DestinationPath = "$($env:SystemDrive)\VMs"
        }     
        
        xVMSwitch LabSwitch {
            DependsOn = '[WindowsFeature]Hyper-V'        
            Name = 'LabSwitch'
            Ensure = 'Present'
            Type = 'Internal'    
        }
    }
}