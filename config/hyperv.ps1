configuration hyperv {

    param
    (
        [Parameter(Mandatory)]
        [string]$DomainName,

        [Parameter(Mandatory)]
        [string]$DNSAddress
    )

    Import-DscResource -ModuleName PsDesiredStateConfiguration
    Import-DscResource -ModuleName ActiveDirectoryDsc
    Import-DscResource -ModuleName xComputerManagement
    Import-DscResource -ModuleName xHyper-V
    Import-DscResource -ModuleName NetworkingDsc
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

        # TODO dynamically detect interface
        DnsServerAddress DnsServerAddress { 
            Address = $DNSAddress,'8.8.8.8'
            InterfaceAlias = "Ethernet"
            AddressFamily  = 'IPv4'
        }

        WaitForADDomain DscForestWait { 
            DomainName = $DomainName 
            Credential = $DomainCreds
            DependsOn = "[DnsServerAddress]DnsServerAddress"
        }
         
        xComputer JoinDomain {
            Name = $ComputerName
            DomainName = $DomainName
            Credential = $DomainCreds
            DependsOn = "[WaitForADDomain]DscForestWait"
        }

        xPendingReboot Reboot { 
            Name = "RebootServer"
            DependsOn = "[xComputer]JoinDomain"
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
            # State = "Running"
            Path = "z:\rodc"
            Generation = 2
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
            # State = "Running"
            Path = "z:\iis"
            Generation = 2
            StartupMemory = 4294967296
            MinimumMemory = 4294967296
            MaximumMemory = 4294967296
            ProcessorCount = 1
            RestartIfNeeded = $true
            DependsOn = "[Script]stageVHDIIS"
        }

        Script stageVHDMember {
            SetScript = {
                $a = (Get-Volume -FileSystemLabel dsc-vhd).DriveLetter
                $path = "{0}:\vhd-dsc-member.vhdx" -f $a
                New-Item -Path "z:\" -Name "member" -ItemType "directory"
                Copy-Item -Path $path -Destination z:\member\vhd-dsc-member.vhdx
            }
            TestScript = { Test-path Z:\member\vhd-dsc-member.vhdx }
            GetScript  = { @{} }
        }

        xVMHyperV Member {
            Ensure = 'Present'
            Name = "member"
            VhdPath = "z:\member\vhd-dsc-member.vhdx"
            SwitchName = "NATSwitch"
            # State = "Running"
            Path = "z:\member"
            Generation = 2
            StartupMemory = 4294967296
            MinimumMemory = 4294967296
            MaximumMemory = 4294967296
            ProcessorCount = 1
            RestartIfNeeded = $true
            DependsOn = "[Script]stageVHDMember"
        }
    }
} 
