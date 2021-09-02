[DSCLocalConfigurationManager()]
configuration LCMConfig
{
    Node localhost
    {
        Settings
        {
            ActionAfterReboot = 'ContinueConfiguration'            
            RebootNodeIfNeeded = $true
        }
    }
}

# . ./lcm.ps1
# LCMConfig
# Set-DscLocalConfigurationManager -Path "./LCMConfig"