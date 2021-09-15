configuration hyperv {

    param
    (
        [Parameter(Mandatory)]
        [string]$ComputerName,

        [Parameter(Mandatory)]
        [string]$DomainName
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

        xVMSwitch LabSwitch {
            DependsOn = '[WindowsFeature]Hyper-V'
            Name = 'LabSwitch'
            Ensure = 'Present'
            Type = 'Internal'
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

        $disk = Get-Process

        File vmADDC {
            DestinationPath = "z:\vm1\vhd-dsc-addc.vhdx"
            SourcePath = "f:\vhd-dsc-addc.vhdx"
            Ensure = "Present"
            Type = "File"
        }

        xVMHyperV NewVM {
            Ensure          = 'Present'
            Name            = "testvm2"
            VhdPath         = "z:\vm1\vhd-dsc-addc.vhdx"
            SwitchName      = "LabSwitch"
            State           = "Off"
            Path            = "z:\vm1"
            Generation      = 1
            StartupMemory   = 4294967296
            MinimumMemory   = 4294967296
            MaximumMemory   = 4294967296
            ProcessorCount  = 1
            RestartIfNeeded = $true
            DependsOn = "[File]vmADDC"
        }
    }
} 
