configuration hypervisor { 

    Import-DscResource -ModuleName PsDesiredStateConfiguration

    node localhost {

        WindowsFeature hypervisor { 
            Ensure = "Present" 
            Name = "Hyper-V"	
        }
    }
} 