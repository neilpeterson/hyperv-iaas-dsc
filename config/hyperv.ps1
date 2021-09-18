configuration hyperv {

    param
    (
        [Parameter(Mandatory)]
        [string]$ComputerName,

        [Parameter(Mandatory)]
        [string]$DomainName,

        [Parameter(Mandatory)]
        [string]$DNSAddress
    )

    Import-DscResource -ModuleName PsDesiredStateConfiguration
    Import-DscResource -ModuleName xActiveDirectory
    Import-DscResource -ModuleName xComputerManagement
    Import-DscResource -ModuleName xHyper-V
    Import-DscResource -ModuleName xNetworking
    Import-DscResource -ModuleName xPendingReboot
    Import-DSCResource -ModuleName StorageDsc

    $Admincreds = Get-AutomationPSCredential 'Admincreds'
    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)

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

        LocalConfigurationManager {
            ActionAfterReboot = 'ContinueConfiguration'            
            ConfigurationMode = 'ApplyAndAutoCorrect'
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

        xDnsServerAddress DnsServerAddress { 
            Address = $DNSAddress,'8.8.8.8'
            # InterfaceAlias = $Interface.Name
            InterfaceAlias = "Ethernet 2"
            AddressFamily  = 'IPv4'
        }

        xWaitForADDomain DscForestWait { 
            DomainName = $DomainName 
            DomainUserCredential= $DomainCreds
            RetryCount = 30
            RetryIntervalSec = 60
            # DependsOn = "[xDnsServerAddress]DnsServerAddress"
        }
         
        xComputer JoinDomain {
            Name = $ComputerName
            DomainName = $DomainName
            Credential = $DomainCreds
            DependsOn = "[xWaitForADDomain]DscForestWait"
        }

        xPendingReboot Reboot { 
            Name = "RebootServer"
            DependsOn = "[xComputer]JoinDomain"
        }

        # Need to use script resource for dynamically determining source path
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

        # Need to use script resource for dynamically determining source path
        Script stageVHDRODC {
            SetScript = {
                $a = (Get-Volume -FileSystemLabel dsc-vhd).DriveLetter
                $path = "{0}:\vhd-dsc-rodc.vhdx" -f $a
                New-Item -Path "z:\" -Name "rodc" -ItemType "directory"
                Copy-Item -Path $path -Destination z:\rodc\vhd-dsc-rodc.vhdx
            }
            TestScript = { Test-path Z:\rodc\vhd-dsc-rodc.vhdx }
            GetScript  = { @{} }
        }

        xVMHyperV RODC {
            Ensure = 'Present'
            Name = "rodc"
            VhdPath = "z:\rodc\vhd-dsc-rodc.vhdx"
            SwitchName = "NATSwitch"
            State = "Off"
            Path = "z:\rodc"
            Generation = 1
            StartupMemory = 4294967296
            MinimumMemory = 4294967296
            MaximumMemory = 4294967296
            ProcessorCount = 1
            RestartIfNeeded = $true
            DependsOn = "[Script]stageVHDRODC"
        }

        Script stageVHDIIS {
            SetScript = {
                $a = (Get-Volume -FileSystemLabel dsc-vhd).DriveLetter
                $path = "{0}:\vhd-dsc-iis.vhdx" -f $a
                New-Item -Path "z:\" -Name "iis" -ItemType "directory"
                Copy-Item -Path $path -Destination z:\iis\vhd-dsc-iis.vhdx
            }
            TestScript = { Test-path Z:\iis\vhd-dsc-iis.vhdx }
            GetScript  = { @{} }
        }

        xVMHyperV IIS {
            Ensure = 'Present'
            Name = "iis"
            VhdPath = "z:\iis\vhd-dsc-iis.vhdx"
            SwitchName = "NATSwitch"
            State = "Off"
            Path = "z:\iis"
            Generation = 1
            StartupMemory = 4294967296
            MinimumMemory = 4294967296
            MaximumMemory = 4294967296
            ProcessorCount = 1
            RestartIfNeeded = $true
            DependsOn = "[Script]stageVHDIIS"
        }

        Script stageVHDDHCP {
            SetScript = {
                $a = (Get-Volume -FileSystemLabel dsc-vhd).DriveLetter
                $path = "{0}:\vhd-dsc-dhcp.vhdx" -f $a
                New-Item -Path "z:\" -Name "dhcp" -ItemType "directory"
                Copy-Item -Path $path -Destination z:\dhcp\vhd-dsc-dhcp.vhdx
            }
            TestScript = { Test-path Z:\dhcp\vhd-dsc-dhcp.vhdx }
            GetScript  = { @{} }
        }

        xVMHyperV DHCP {
            Ensure = 'Present'
            Name = "dhcp"
            VhdPath = "z:\dhcp\vhd-dsc-dhcp.vhdx"
            SwitchName = "NATSwitch"
            State = "Off"
            Path = "z:\dhcp"
            Generation = 1
            StartupMemory = 4294967296
            MinimumMemory = 4294967296
            MaximumMemory = 4294967296
            ProcessorCount = 1
            RestartIfNeeded = $true
            DependsOn = "[Script]stageVHDDHCP"
        }
    }
} 
