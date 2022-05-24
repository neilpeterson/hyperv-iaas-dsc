param adminUserName string
@secure()
param adminPassword string

param location string = resourceGroup().location
param vmSize string = 'Standard_B2ms'

param bastionHostSubnetPrefix string = '10.0.1.0/29'
param virtualNetworkID string = '/subscriptions/7d87d11e-2aaa-4d69-85bf-a1c11503f96d/resourceGroups/tip-net-test-poc/providers/Microsoft.Network/virtualNetworks/vnet-hub'
param AutomationAccountURL string = 'https://ea8bee4c-19af-486a-b937-490c67b0df49.agentsvc.cus.azure-automation.net/accounts/ea8bee4c-19af-486a-b937-490c67b0df49'

param addcVirtualMachine object = {
  name: 'vm-addc'
  nicName: 'nic-addc'
  windowsOSVersion: '2022-datacenter'
  diskName: 'data'
}

resource nsgVirtualMachines 'Microsoft.Network/networkSecurityGroups@2020-08-01' = {
  name: 'nsgVirtualMachines'
  location: location
  properties: {
    securityRules: [
      {
        name: 'bastion-in-vnet'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: bastionHostSubnetPrefix
          destinationPortRanges: [
            '22'
            '3389'
          ]
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource nicADDC 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: addcVirtualMachine.nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: '${virtualNetworkID}/subnets/ResourceSubnet'
          }
        }
      }
    ]
  }
}

resource vmADDC 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: addcVirtualMachine.name
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: addcVirtualMachine.name
      adminUsername: adminUserName
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: addcVirtualMachine.windowsOSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
      dataDisks: []
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', addcVirtualMachine.nicName)
        }
      ]
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource HBWExt 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  parent: vmADDC
  name: 'HybridWorkerExtension'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Automation.HybridWorker'
    type: 'HybridWorkerForWindows'
    typeHandlerVersion: '0.1'
    settings: {
      Properties: [
        {
          Name: 'AutomationAccountURL'
          Value: AutomationAccountURL
          TypeName: 'System.String'
        }
        {
          Name: 'HybridWorkerGroup'
          Value: 'tip-net-test-poc'
          TypeName: 'System.String'
        }
      ]
    }
  }
}
