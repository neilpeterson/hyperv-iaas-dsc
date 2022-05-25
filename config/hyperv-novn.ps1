configuration hyperv {

    Import-DscResource -ModuleName PsDesiredStateConfiguration
    Import-DscResource -ModuleName ComputerManagementDsc
    Import-DSCResource -ModuleName StorageDsc
    Import-DscResource -ModuleName SChannelDsc

    node localhost {

        WaitForDisk Disk2 {
            DiskId = 2
            RetryIntervalSec = 60
            RetryCount = 60
        }
        
        Disk ZVolume {
            DiskId = 2
            DriveLetter = 'Z'
            FSLabel = 'Virtual Machines'
            FSFormat = 'NTFS'
            DependsOn = '[WaitForDisk]Disk2'
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
       
        # Need to use script to configure Hyper-V NAT
        Script natConfig {
            SetScript = {
                New-VMSwitch -Name "NATSwitch" -SwitchType Internal
                $interface = Get-NetAdapter | where-object {$_.Name -like "*NATSwitch*"}
                New-NetIPAddress -IPAddress 192.168.0.1 -PrefixLength 24 -InterfaceIndex $interface.ifIndex
                New-NetNat -Name "InternalNATnet" -InternalIPInterfaceAddressPrefix 192.168.0.0/24
            }
            TestScript = { 
                if (Get-VMSwitch -Name "NATSwitch" -ErrorAction SilentlyContinue) {
                    return $true
                } else {
                   return $false
                } 
            }
            GetScript  = { @{} }
        }
    }
}