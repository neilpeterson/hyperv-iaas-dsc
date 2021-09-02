# Can be used to test configurations locally.
# CreateForest -ConfigurationData .\config.psd1 -Admincreds $creds

@{
    AllNodes = @(
        @{
            NodeName = 'localhost'
            PSDSCAllowPlainTextPassword = $true
        }
    )
}