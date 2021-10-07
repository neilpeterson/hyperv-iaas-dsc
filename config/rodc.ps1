configuration rodc {
    
   param 
   ( 
        [Parameter(Mandatory)]
        [String]$DomainName,

        [Parameter(Mandatory)]
        [string]$DNSAddress
    ) 
    
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DSCResource -ModuleName StorageDsc
    Import-DscResource -ModuleName ActiveDirectoryDsc
    Import-DscResource -ModuleName NetworkingDsc
    Import-DscResource -ModuleName xPendingReboot

    $Admincreds = Get-AutomationPSCredential 'Admincreds'
    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
    
    Node localhost
    {

        # TODO dynamically detect interface
        DnsServerAddress DnsServerAddress { 
            Address = $DNSAddress,'8.8.8.8'
            InterfaceAlias = "Ethernet 2"
            AddressFamily  = 'IPv4'
        }

        WindowsFeature ADDSInstall { 
            Ensure = "Present" 
            Name = "AD-Domain-Services"
        } 

        WindowsFeature ADDSTools {
            Ensure = "Present"
            Name = "RSAT-ADDS-Tools"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }

        WaitForADDomain DscForestWait { 
            DomainName = $DomainName 
            Credential = $DomainCreds
            DependsOn = "[DnsServerAddress]DnsServerAddress"
        }

        # # I am hitting this, but should be using the latest package
        # # https://github.com/dsccommunity/ActiveDirectoryDsc/issues/611
        # ADDomainController RODC {
        #     DomainName = $DomainName
        #     Credential = $DomainCreds
        #     SafemodeAdministratorPassword = $DomainCreds
        #     ReadOnlyReplica = $true
        #     SiteName = "Default-First-Site-Name"
        # } 

        # Need to use script to configure Hyper-V NAT
        Script rodcConfig {
            SetScript = {
                Install-ADDSDomainController -Credential $DomainCreds -SafemodeAdministratorPassword $DomainCreds.Password -DomainName $DomainName -ReadOnlyReplica -SiteName "Default-First-Site-Name" -NoRebootOnCompletion -Force
            }
            TestScript = { 
                $DomainRole = Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty DomainRole
                
                if ($DomainRole -eq 4) {
                    return $true
                } else {
                   return $false
                } 
            }
            GetScript  = { @{} }
        }

        xPendingReboot Reboot { 
            Name = "RebootServer"
            DependsOn = "[Script]rodcConfig"
        }
   }
} 