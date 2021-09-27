targetScope = 'subscription'

param adminUserName string
@secure()
param adminPassword string
param resourceGroupNamePrefix string
param deploySharedResources bool = true

resource centralResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = if (deploySharedResources) {
  name: '${resourceGroupNamePrefix}-automation-central'
  location: 'eastus'
}

// Automation Account, Credentials, DSC Modules, Log Analytics
module automationCentral 'modules/automation-central.bicep' = if (deploySharedResources) {
  name: 'automationCentral'
  scope: centralResourceGroup
  params: {
    adminUserName: adminUserName
    adminPassword: adminPassword
  }
}

// ADDC and Hyper-V State Configs
module configs 'modules/state-configs.bicep' = {
  name: 'configs'
  scope: centralResourceGroup
  params: {
    automationAccountName: automationCentral.outputs.automationAccountName
  }
}
