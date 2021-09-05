configuration hyperv {

    param
    (
        [Parameter(Mandatory)]
        [string]$ComputerName,

        [Parameter(Mandatory)]
        [string]$DomainName,

        [Parameter(Mandatory)]
        [string]$DNSAddress,

        [Int]$RetryCount=30,
        [Int]$RetryIntervalSec=60
    )

    Import-DscResource -ModuleName PsDesiredStateConfiguration
    Import-DscResource -ModuleName xActiveDirectory
    Import-DscResource -ModuleName xComputerManagement
    Import-DscResource -ModuleName xHyper-V
    Import-DscResource -ModuleName xNetworking
    Import-DscResource -ModuleName xPendingReboot

    $Admincreds = Get-AutomationPSCredential 'Admincreds'
    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)

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

        xVMSwitch LabSwitch {
            DependsOn = '[WindowsFeature]Hyper-V'
            Name = 'LabSwitch'
            Ensure = 'Present'
            Type = 'Internal'
        }

        # TODO can I plumb through IP from ARM?
        xDnsServerAddress DnsServerAddress { 
            Address        = $DNSAddress
            # InterfaceAlias = $Interface.Name
            InterfaceAlias = "Ethernet 2"
            AddressFamily  = 'IPv4'
        }

        xWaitForADDomain DscForestWait 
        { 
            DomainName = $DomainName 
            DomainUserCredential= $DomainCreds
            RetryCount = $RetryCount 
            RetryIntervalSec = $RetryIntervalSec
            DependsOn = "[xDnsServerAddress]DnsServerAddress"
        }
         
        xComputer JoinDomain
        {
            Name          = $ComputerName
            DomainName    = $DomainName
            Credential    = $DomainCreds
            DependsOn = "[xWaitForADDomain]DscForestWait"
        }

        xPendingReboot Reboot2
        { 
            Name = "RebootServer"
            DependsOn = "[xComputer]JoinDomain"
        }
    }
} 
