configuration windowsfeatures {

    Import-DscResource -ModuleName PsDesiredStateConfiguration
    Import-DscResource -module xHyper-V

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

        xVMSwitch LabSwitch {
            DependsOn = '[WindowsFeature]Hyper-V'
            Name = 'LabSwitch'
                 Ensure = 'Present'
            Type = 'Internal'
        }
    }
}