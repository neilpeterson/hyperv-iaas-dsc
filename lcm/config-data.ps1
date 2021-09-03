$ConfigData = @{
    AllNodes = @(
        @{
            NodeName = 'localhost'
            PSDSCAllowPlainTextPassword = $true
        }
    )
}

$Params = @{"DomainName"="contoso.com"}
Start-AzAutomationDscCompilationJob -ResourceGroupName thursday-201 -AutomationAccountName qbkeilvmf4lzg -ConfigurationName CreateForest -ConfigurationData $ConfigData -Parameters $Params