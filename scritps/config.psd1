# Can be used to test configurations locally.
# ADDC -ConfigurationData .\config.psd1 -Admincreds $creds

@{
    AllNodes = @(
        @{
            NodeName = 'localhost'
            PSDSCAllowPlainTextPassword = $true
        }
    )
}

$ConfigData = @{
    @{
        AllNodes = @(
            @{
                NodeName = 'localhost'
                PSDSCAllowPlainTextPassword = $true
            }
        )
    }
}