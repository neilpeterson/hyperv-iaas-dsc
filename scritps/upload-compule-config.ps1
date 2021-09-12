[CmdletBinding()]
param (
    [Parameter()]
    [string]$automationAccountName = "sdmszrkthtqfo",

    [Parameter()]
    [string]$resourceGroupName = "automation-central-001",

    [Parameter()]
    [string]$path = "/Users/neilpeterson/Documents/code/hyperv-iaas-dsc/config/create-forest.ps1"
)

Import-AzAutomationDscConfiguration -AutomationAccountName $automationAccountName -ResourceGroupName $resourceGroupName -SourcePath $path -Force -Published