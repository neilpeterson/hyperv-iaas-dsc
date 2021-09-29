param adminUserName string

@secure()
param adminPassword string

module automationCentral 'modules/automation-central.bicep' = {
  name: 'automationCentral'
  params: {
    adminUserName: adminUserName
    adminPassword: adminPassword
  }
}

module configs 'modules/state-configs.bicep' = {
  name: 'configs'
  params: {
    automationAccountName: automationCentral.outputs.automationAccountName
  }
}
