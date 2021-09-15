[CmdletBinding()]
param (
    [Parameter()]
    [string]$automationAccountName = "test-automation-account",

    [Parameter()]
    [string]$resourceGroupName = "test-automation-account",

    [Parameter()]
    [string]$path = "../config/hyperv.ps1"
)

Import-AzAutomationDscConfiguration -AutomationAccountName $automationAccountName -ResourceGroupName $resourceGroupName -SourcePath $path -Force -Published

$Params = @{"DomainName"="contoso.com";"ComputerName"="hyperv-vm"}
Start-AzAutomationDscCompilationJob -ConfigurationName "hyperv" -Parameters $Params -AutomationAccountName $automationAccountName -ResourceGroupName $resourceGroupName