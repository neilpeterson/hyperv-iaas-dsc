targetScope = 'subscription'

param adminUserName string
@secure()
param adminPassword string
param domainName string = 'contoso.com'
param resourceGroupNamePrefix string

resource centralResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${resourceGroupNamePrefix}-automation-central'
  location: 'eastus'
}

resource mocFactoryResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${resourceGroupNamePrefix}-moc-factory'
  location: 'eastus'
}

// Automation Account, Credentials, DSC Modules, Log Analytics
module automationCentral 'modules/automation-central.bicep' = {
  name: 'automationCentral'
  scope: centralResourceGroup
  params: {
    adminUserName: adminUserName
    adminPassword: adminPassword
  }
}

// Networking and Bastion
module network 'modules/network-bastion.bicep' = {
  name: 'network'
  scope: mocFactoryResourceGroup
}

// ADDC and Hyper-V State Configs
module configs 'modules/state-configs.bicep' = {
  name: 'configs'
  scope: centralResourceGroup
  params: {
    automationAccountName: automationCentral.outputs.automationAccountName
  }
}

// ADDC Compile State
module compileaddc 'modules/state-comp-addc.bicep' = {
  name: 'compile-addc'
  scope: centralResourceGroup
  params: {
    automationAccountName: automationCentral.outputs.automationAccountName
    domainName: domainName
   }
   dependsOn: [
     configs
   ]
}


// Active Directory Domain Controller VM
module addc 'modules/compute-addc.bicep' = {
  name: 'addc'
  scope: mocFactoryResourceGroup
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

// Compile State Hyper-V
module compilehyperv 'modules/state-comp-hyperv.bicep' = {
  name: 'compile-hyperv'
  scope: centralResourceGroup
  params: {
    automationAccountName: automationCentral.outputs.automationAccountName
    dnsServer: addc.outputs.privateIP
   }
   dependsOn: [
     configs
   ]
}

// Hyper-V VM
module hyperv 'modules/compute-hyperv.bicep' = {
  name: 'hyperv'
  scope: mocFactoryResourceGroup
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
