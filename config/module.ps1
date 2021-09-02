param (
    [string]]
    $resourceGroup,

    [string]]
    $automationAccount
)

$moduleName = "xHyper-V"
$url = "https://www.powershellgallery.com/api/v2/package/xHyper-V/3.17.0.0"

New-AzAutomationModule -AutomationAccountName $automationAccount -ResourceGroupName $resourceGroup -Name $moduleName -ContentLinkUri $url

do {
    $module = Get-AzAutomationModule -AutomationAccountName $automationAccount -ResourceGroupName $resourceGroup -Name $moduleName
} until ($module.ProvisioningState -eq "Succeeded")

