param adminUserName string
@secure()
param adminPassword string
param location string = resourceGroup().location
param randomString string =  uniqueString(subscription().subscriptionId, resourceGroup().id)

param azureSecPack object = {
  role: 'MTPFITADDomainSvc'
  account: 'RoverAzSecPackGenevaLogAccnt1'
  nameSpace: 'MTPFITADDomainSvc'
  certificate: '67cf050d3732fb104a46a9b3b5a56521f837f39f'
}

param baseVirtualMachine object = {
  name: 'fit-lab-vm'
  nicName: 'fit-lab-vm'
  windowsOSVersion: '2022-datacenter'
  Size: 'Standard_D3_v2'
  Count: 1
}

param hyperVirtualMachine object = {
  name: 'fit-lab-hv'
  nicName: 'fit-lab-host'
  windowsOSVersion: '2022-datacenter'
  Size: 'Standard_D8s_v3'
  Count: 1
}

param hubNetwork object = {
  name: 'vnet-hub'
  addressPrefix: '10.0.0.0/20'
}

param bastionHost object = {
  name: 'AzureBastionHost'
  publicIPAddressName: 'pip-bastion'
  NSGName: 'nsg-hub-bastion'
  subnetPrefix: '10.0.1.0/29'
}

param resourceSubnet object = {
  subnetName: 'ResourceSubnet'
  NSGName: 'nsg-hub-resources'
  subnetPrefix: '10.0.2.0/24'
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: randomString
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      legacy: 0
      searchVersion: 1
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

resource storageaccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: randomString
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

module azureAutomaton './modules//automation.bicep' = {
  name: 'AzureAutomaton'
  params: {
    AzSecPackRole: azureSecPack.role
    AzSecPackAcct: azureSecPack.account
    AzSecPackNS: azureSecPack.namespace
    AzSecPackCert: azureSecPack.certificate
    automationAccountName: randomString
    location: location
  }
}

module networking './modules//networking.bicep' = {
  name: 'Networking'
  params: {
    hubNetworkName: hubNetwork.name
    hubAddressPrefix: hubNetwork.addressPrefix
    bastionName: bastionHost.Name
    bastionSubnetPrefix: bastionHost.subnetPrefix
    bastionPIPName: bastionHost.PublicIPAddressName
    bastionNSGName: bastionHost.NSGName
    resourceSubnetName: resourceSubnet.subnetName
    resourceSubnetPrefix: resourceSubnet.subnetPrefix
    resourceNSGName: resourceSubnet.NSGName
    location: location
  }
}

module baseVirtualMachines 'modules/virtualmachine.bicep' = {
  name: 'VirtualMAchines'
  params: {
    adminPassword: adminPassword
    adminUserName: adminUserName
    AzSecPackCertificateName: 'https://US01-PROD-MTPAUTOMATION.vault.azure.net/secrets/AzSecPack'
    keyVaultName: 'US01-PROD-MTPAUTOMATION'
    keyVaultResourceGroup: 'US01-PRDMTPAA-RG'
    keyVaultSubscriptionID: '7aab1e63-3115-4365-89bc-bf1172dc93c9'
    location: location
    logAnalyticsWorkspaceID: logAnalyticsWorkspace.id
    logAnalyticsWorkspaceName: logAnalyticsWorkspace.name
    nicNamePrefix: baseVirtualMachine.nicName
    storageAccountName: storageaccount.name
    subnetName: resourceSubnet.subnetName
    virtualMachineNamePrefix: baseVirtualMachine.name
    virtualMachineSize: baseVirtualMachine.size
    virtualMachineSKU: baseVirtualMachine.windowsOSVersion
    virtualNetworkID: networking.outputs.networkID
    vmCount: baseVirtualMachine.count
    automationAccountID: azureAutomaton.outputs.autoamtionAccountID
    automationAccountURI: azureAutomaton.outputs.automationAccountURI
    config: 'BaseOS'
    bastionHostSubnetPrefix: bastionHost.subnetPrefix
    resourceSubnetPrefix: resourceSubnet.subnetPrefix
  }
  dependsOn: [
    hypervVirtualMachines
  ]
}

module hypervVirtualMachines 'modules/virtualmachine.bicep' = {
  name: 'VirtualMachinesHyperV'
  params: {
    adminPassword: adminPassword
    adminUserName: adminUserName
    AzSecPackCertificateName: 'https://US01-PROD-MTPAUTOMATION.vault.azure.net/secrets/AzSecPack'
    keyVaultName: 'US01-PROD-MTPAUTOMATION'
    keyVaultResourceGroup: 'US01-PRDMTPAA-RG'
    keyVaultSubscriptionID: '7aab1e63-3115-4365-89bc-bf1172dc93c9'
    location: location
    logAnalyticsWorkspaceID: logAnalyticsWorkspace.id
    logAnalyticsWorkspaceName: logAnalyticsWorkspace.name
    nicNamePrefix: hyperVirtualMachine.nicName
    storageAccountName: storageaccount.name
    subnetName: resourceSubnet.subnetName
    virtualMachineNamePrefix: hyperVirtualMachine.name
    virtualMachineSize: hyperVirtualMachine.Size
    virtualMachineSKU: hyperVirtualMachine.windowsOSVersion
    virtualNetworkID: networking.outputs.networkID
    vmCount: hyperVirtualMachine.count
    automationAccountID: azureAutomaton.outputs.autoamtionAccountID
    automationAccountURI: azureAutomaton.outputs.automationAccountURI
    config: 'HyperV'
    bastionHostSubnetPrefix: bastionHost.subnetPrefix
    resourceSubnetPrefix: resourceSubnet.subnetPrefix
  }
}

