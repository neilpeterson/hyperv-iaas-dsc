$ConfigData = @{
    AllNodes = @(
        @{
            NodeName = 'localhost'
            PSDSCAllowPlainTextPassword = $true
        }
    )
}

$Params = @{"DomainName"="contoso.com"}
Start-AzAutomationDscCompilationJob -ResourceGroupName fri-003 -AutomationAccountName jb5qo3vxrth4w -ConfigurationName ADDC -ConfigurationData $ConfigData -Parameters $Params