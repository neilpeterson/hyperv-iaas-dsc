$ConfigData = @{
    AllNodes = @(
        @{
            NodeName = 'localhost'
            PSDSCAllowPlainTextPassword = $true
        }
    )
}

$Params = @{"DomainName"="contoso.com"}
Start-AzAutomationDscCompilationJob -ResourceGroupName fri-001 -AutomationAccountName pw64ngfvyrjqi -ConfigurationName CreateForest -ConfigurationData $ConfigData -Parameters $Params