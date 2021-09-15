[CmdletBinding()]
param (
    [Parameter()]
    [string]$automationAccountName = "test-automation",

    [Parameter()]
    [string]$resourceGroupName = "test-automation",

    [Parameter()]
    [string]$path = "../config/addc.ps1"
)

Import-AzAutomationDscConfiguration -AutomationAccountName $automationAccountName -ResourceGroupName $resourceGroupName -SourcePath $path -Force -Published

$Params = @{"DomainName"="contoso.com"}
Start-AzAutomationDscCompilationJob -ConfigurationName "addc" -Parameters $Params -AutomationAccountName $automationAccountName -ResourceGroupName $resourceGroupName