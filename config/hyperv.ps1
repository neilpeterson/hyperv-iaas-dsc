configuration Hypervisor { 

    Node localhost {
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

        WindowsFeature Hyper-V-PowerShell { 
            Ensure = "Present" 
            Name = "Hyper-V-PowerShell"
            IncludeAllSubFeature = $true		
        }
    }

} 