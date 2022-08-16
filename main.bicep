param adminUserName string
@secure()
param adminPassword string
param virtualMachineCount int
param location string = resourceGroup().location
param randomString string =  uniqueString(subscription().subscriptionId, resourceGroup().id)

param baseVirtualMachine object = {
  name: 'fit-lab-vm'
  nicName: 'fit-lab-vm'
  windowsOSVersion: '2022-datacenter'
  Size: 'Standard_D3_v2'
}

param hubNetwork object = {
  name: 'vnet-hub'
  addressPrefix: '10.0.0.0/20'
}

param bastionHost object = {
  name: 'AzureBastionHost'
  publicIPAddressName: 'pip-bastion'
  NSGName: 'nsg-hub-bastion'
  subnetPrefix: '10.0.1.0/26'
}

param resourceSubnet object = {
  subnetName: 'ResourceSubnet'
  NSGName: 'nsg-hub-resources'
  subnetPrefix: '10.0.2.0/24'
}

module diagnostics './modules/diagnostics.bicep' = {
  name: 'diagnostics'
  params: {
    location: location
    logAnalyticsName: randomString
    storageAccountName: randomString
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
    location: location
    logAnalyticsWorkspaceID: diagnostics.outputs.logAnalyticsWoekspaceId
    logAnalyticsWorkspaceName: diagnostics.outputs.logAnalyticsWoekspaceName
    nicNamePrefix: baseVirtualMachine.nicName
    storageAccountName: diagnostics.outputs.storageAccountName
    subnetName: resourceSubnet.subnetName
    virtualMachineNamePrefix: baseVirtualMachine.name
    virtualMachineSize: baseVirtualMachine.size
    virtualMachineSKU: baseVirtualMachine.windowsOSVersion
    virtualNetworkID: networking.outputs.networkID
    vmCount: virtualMachineCount
  }
}

