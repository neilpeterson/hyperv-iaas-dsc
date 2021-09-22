[CmdletBinding()]
param (
    [Parameter()]
    [string]$automationAccountName = "test-automation-account",

    [Parameter()]
    [string]$resourceGroupName = "test-automation-account"
)

Import-AzAutomationDscConfiguration -AutomationAccountName $automationAccountName -ResourceGroupName $resourceGroupName -SourcePath "../config/addc.ps1" -Force -Published
Import-AzAutomationDscConfiguration -AutomationAccountName $automationAccountName -ResourceGroupName $resourceGroupName -SourcePath "../config/hyperv.ps1" -Force -Published
Import-AzAutomationDscConfiguration -AutomationAccountName $automationAccountName -ResourceGroupName $resourceGroupName -SourcePath "../config/iis.ps1" -Force -Published
Import-AzAutomationDscConfiguration -AutomationAccountName $automationAccountName -ResourceGroupName $resourceGroupName -SourcePath "../config/member.ps1" -Force -Published
Import-AzAutomationDscConfiguration -AutomationAccountName $automationAccountName -ResourceGroupName $resourceGroupName -SourcePath "../config/rodc.ps1" -Force -Published

# # $Params = @{"DomainName"="contoso.com";"ComputerName"="hyperv-vm";"DNSAddress"="10.0.2.4"}
# $Params = @{"DomainName"="contoso.com"}
# Start-AzAutomationDscCompilationJob -ConfigurationName "addc" -Parameters $Params -AutomationAccountName $automationAccountName -ResourceGroupName $resourceGroupName