configuration Hypervisor { 

    Import-DscResource -ModuleName PsDesiredStateConfiguration

    node localhost {

        WindowsFeature Hyper-V { 
            Ensure = "Present" 
            Name = "DNS"
            IncludeAllSubFeature = $true		
        }
    }
} 