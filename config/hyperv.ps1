configuration windowsfeatures {

    Import-DscResource -ModuleName PsDesiredStateConfiguration

    node localhost {

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