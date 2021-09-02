$ConfigData = @{
    AllNodes = @(
        @{
            NodeName = 'localhost'
            PSDSCAllowPlainTextPassword = $true
        }
    )
}

Start-AzAutomationDscCompilationJob -ResourceGroupName thursday-004 -AutomationAccountName s5yyl7qmr6zak -ConfigurationName CreateForest -ConfigurationData $ConfigData