configuration windowsfeatures {

    Import-DscResource -ModuleName PsDesiredStateConfiguration
    Import-DscResource -ModuleName xHyper-V
    Import-DscResource -ModuleName ComputerManagementDsc

    node localhost {

        LocalConfigurationManager {
            ActionAfterReboot = 'ContinueConfiguration'            
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $true
        }

        WindowsFeature Hyper-V {
            Ensure = "Present"
            Name = "Hyper-V"
            IncludeAllSubFeature = $true
        }

        WindowsFeature Hyper-V-Tools {
            Ensure = "Present"
            Name = "Hyper-V-Tools"
            IncludeAllSubFeature = $true
        }

        WindowsFeature Hyper-V-PowerShell {
            Ensure = "Present"
            Name = "Hyper-V-PowerShell"
            IncludeAllSubFeature = $true
        }

        PendingReboot reboot {
            DependsOn = '[WindowsFeature]Hyper-V'
            name = 'reboot'
        }

        xVMSwitch LabSwitch {
            DependsOn = '[PendingReboot]reboot'
            Name = 'LabSwitch'
            Ensure = 'Present'
            Type = 'Internal'
        }
    }
} 
