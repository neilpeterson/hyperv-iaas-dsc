param adminUserName string

@secure()
param adminPassword string

param domainName string

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

// ADDC Compile State
module compileaddc 'modules/state-comp-addc.bicep' = {
  name: 'compile-addc'
  params: {
    automationAccountName: automationCentral.outputs.automationAccountName
    domainName: domainName
   }
   dependsOn: [
     configs
   ]
}

// Networking and Bastion
module network 'modules/network-bastion.bicep' = {
  name: 'network'
}


// Active Directory Domain Controller VM
module addc 'modules/compute-addc.bicep' = {
  name: 'addc'
  params: {
      adminUserName: adminUserName
      adminPassword: adminPassword
      subnetId: network.outputs.resourceSubnetId
      autoamtionAccountURL: automationCentral.outputs.autoamtionAccountURL
      automationAccountKey: automationCentral.outputs.automationAccountKey
      workspaceId: automationCentral.outputs.workspaceId
      workspaceKey: automationCentral.outputs.workspaceKey
   }
   dependsOn: [
    configs
    compileaddc
   ]
}
