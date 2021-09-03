$ConfigData = @{
    AllNodes = @(
        @{
            NodeName = 'localhost'
            PSDSCAllowPlainTextPassword = $true
        }
    )
}

$Params = @{"DomainName"="contoso.com"}
Start-AzAutomationDscCompilationJob -ResourceGroupName thursday-200 -AutomationAccountName iu5oklznix3pe -ConfigurationName CreateForest -ConfigurationData $ConfigData