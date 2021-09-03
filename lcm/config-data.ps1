$ConfigData = @{
    AllNodes = @(
        @{
            NodeName = 'localhost'
            PSDSCAllowPlainTextPassword = $true
        }
    )
}

$Params = @{"DomainName"="contoso.com"}
Start-AzAutomationDscCompilationJob -ResourceGroupName full-006 -AutomationAccountName tze5ndjzjpaju -ConfigurationName CreateForest -ConfigurationData $ConfigData -Parameters $Params