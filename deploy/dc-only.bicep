param adminUserName string
@secure()
param adminPassword string
param domainName string
param deployHyperV bool = true

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

// Compile State Hyper-V
module compilehyperv 'modules/state-comp-hyperv.bicep' =  if (deployHyperV) {
  name: 'compile-hyperv'
  params: {
    automationAccountName: automationCentral.outputs.automationAccountName
    dnsServer: addc.outputs.privateIP
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

// Hyper-V VM
module hyperv 'modules/compute-hyperv.bicep' = if (deployHyperV) {
  name: 'hyperv'
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
    compilehyperv
   ]
}
