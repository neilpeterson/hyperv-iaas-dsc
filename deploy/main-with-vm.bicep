param adminUserName string
@secure()
param adminPassword string
param vmCount int = 2

param automationAccountName string = uniqueString(resourceGroup().id)
param hybridRunbookWorkerGroupName string = uniqueString(resourceGroup().id)
param keyVaultName string = 'a${uniqueString(resourceGroup().id)}b'
param location string = resourceGroup().location
param logAnalyticsWorkspaceName string = uniqueString(subscription().subscriptionId, resourceGroup().id)
param vmSize string = 'Standard_D8s_v3'

param baseOSConfiguration object = {
  name: 'hyperv'
  description: 'Configures an S360 compliant VM.'
  script: 'https://raw.githubusercontent.com/neilpeterson/hyperv-iaas-dsc/remove-hypv-vm/config/hyperv-novn.ps1'
}

param addcVirtualMachine object = {
  name: 'vm-addc'
  nicName: 'nic-addc'
  windowsOSVersion: '2022-datacenter'
  diskName: 'data'
}

param bastionHost object = {
  name: 'AzureBastionHost'
  publicIPAddressName: 'pip-bastion'
  subnetName: 'AzureBastionSubnet'
  nsgName: 'nsg-hub-bastion'
  subnetPrefix: '10.0.1.0/29'
}

param hubNetwork object = {
  name: 'vnet-hub'
  addressPrefix: '10.0.0.0/20'
}

param resourceSubnet object = {
  subnetName: 'ResourceSubnet'
  nsgName: 'nsg-hub-resources'
  subnetPrefix: '10.0.2.0/24'
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: logAnalyticsWorkspaceName
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

resource vmInsightsSolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'VMInsights(${logAnalyticsWorkspaceName})'
  location: location
  properties: {
    workspaceResourceId: logAnalyticsWorkspace.id
  }
  plan: {
    name: 'ADAssessment(${logAnalyticsWorkspaceName})'
    product: 'OMSGallery/VMInsights'
    publisher: 'Microsoft'
    promotionCode: ''
  }
}

resource storageaccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    accessPolicies: []
    tenantId: subscription().tenantId
  }
}

resource automationAccount 'Microsoft.Automation/automationAccounts@2021-06-22' = {
  name: automationAccountName
  location: location
  properties: {
    sku: {
      name: 'Basic'
    }
  }
}

resource vnetHub 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: hubNetwork.name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        hubNetwork.addressPrefix
      ]
    }
    subnets: [
      {
        name: bastionHost.subnetName
        properties: {
          addressPrefix: bastionHost.subnetPrefix
          networkSecurityGroup: {
            id: nsgBastion.id
          }
        }
      }
      {
        name: resourceSubnet.subnetName
        properties: {
          addressPrefix: resourceSubnet.subnetPrefix
          networkSecurityGroup: {
            id: nsgVirtualMachines.id
          }
        }
      }
    ]
  }
}

resource pipBastion 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: 'bastionpip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource nsgBastion 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: 'nsgbastion'
  location: location
  properties: {
    securityRules: [
      {
        name: 'bastion-in-allow'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'Internet'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'bastion-control-in-allow'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'GatewayManager'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      {
        name: 'bastion-in-host'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 130
          direction: 'Inbound'
        }
      }
      {
        name: 'bastion-vnet-out-allow'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRanges: [
            '22'
            '3389'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
      {
        name: 'bastion-azure-out-allow'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '443'
          destinationAddressPrefix: 'AzureCloud'
          access: 'Allow'
          priority: 120
          direction: 'Outbound'
        }
      }
      {
        name: 'bastion-out-host'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 130
          direction: 'Outbound'
        }
      }
      {
        name: 'bastion-out-deny'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2020-06-01' = {
  name: 'bastionhost'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconf'
        properties: {
          subnet: {
            id: '${vnetHub.id}/subnets/${bastionHost.subnetName}'
          }
          publicIPAddress: {
            id: pipBastion.id
          }
        }
      }
    ]
  }
}

resource nsgVirtualMachines 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: 'nsgVirtualMachines'
  location: location
  properties: {
    securityRules: []
  }
}

// resource nsgVirtualMachines 'Microsoft.Network/networkSecurityGroups@2020-08-01' = {
//   name: 'nsgVirtualMachines'
//   location: location
//   properties: {
//     securityRules: [
//       {
//         name: 'bastion-in-vnet'
//         properties: {
//           protocol: 'Tcp'
//           sourcePortRange: '*'
//           sourceAddressPrefix: bastionHost.subnetPrefix
//           destinationPortRanges: [
//             '22'
//             '3389'
//           ]
//           destinationAddressPrefix: '*'
//           access: 'Allow'
//           priority: 100
//           direction: 'Inbound'
//         }
//       }
//       {
//         name: 'DenyAllInBound'
//         properties: {
//           protocol: 'Tcp'
//           sourcePortRange: '*'
//           sourceAddressPrefix: '*'
//           destinationPortRange: '443'
//           destinationAddressPrefix: '*'
//           access: 'Deny'
//           priority: 1000
//           direction: 'Inbound'
//         }
//       }
//     ]
//   }
// }

resource nicADDC 'Microsoft.Network/networkInterfaces@2020-05-01' = [for i in range(0, vmCount): {
  name: '${addcVirtualMachine.nicName}-${i}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: '${vnetHub.id}/subnets/${resourceSubnet.subnetName}'
          }
        }
      }
    ]
  }
}]

resource vmADDC 'Microsoft.Compute/virtualMachines@2019-07-01' = [for i in range(0, vmCount): {
  name: '${addcVirtualMachine.name}-${i}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: '${addcVirtualMachine.name}-${i}'
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
          id: resourceId('Microsoft.Network/networkInterfaces', '${addcVirtualMachine.nicName}-${i}')
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageaccount.properties.primaryEndpoints.blob
      }
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}]

resource azureMonitoringDependencyAgent 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = [for i in range(0, vmCount): {
  parent: vmADDC[i]
  name: 'DependencyAgentWindows'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitoring.DependencyAgent'
    type: 'DependencyAgentWindows'
    typeHandlerVersion: '9.5'
    autoUpgradeMinorVersion: true
  }
}]

resource azureMonitoringAgent 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = [for i in range(0, vmCount): {
  parent: vmADDC[i]
  name: 'MMAExtension'
  location: location
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'MicrosoftMonitoringAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      workspaceId: reference(resourceId('Microsoft.OperationalInsights/workspaces/', logAnalyticsWorkspaceName), '2020-08-01').customerId
      azureResourceId: vmADDC[i].id
      stopOnMultipleConnections: true
    }
    protectedSettings: {
      workspaceKey: listKeys(logAnalyticsWorkspace.id, '2020-08-01').primarySharedKey
    }
  }
}]

resource GenevaMonitoring 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = [for i in range(0, vmCount):  {
  parent: vmADDC[i]
  name: 'GenevaMonitoring'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Geneva'
    type: 'GenevaMonitoring'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
  }
}]

resource ManagementPortJITPolicy 'Microsoft.Security/locations/jitNetworkAccessPolicies@2020-01-01' = [for i in range(0, vmCount): {
  name: '${location}/${addcVirtualMachine.name}-${i}'
  kind: 'Basic'
  properties: {
    virtualMachines: [
      {
        id: vmADDC[i].id
        ports: [
          {
            number: 3389
            protocol: '*'
            allowedSourceAddressPrefixes: [
              bastionHost.subnetPrefix
            ]
            maxRequestAccessDuration: 'PT3H'
          }
          {
            number: 5985
            protocol: '*'
            allowedSourceAddressPrefixes: [
              bastionHost.subnetPrefix
            ]
            maxRequestAccessDuration: 'PT3H'
          }
        ]
      }
    ]
  }
}]

// resource hybridRunbookWorker 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = {
//   parent: vmADDC[0]
//   name: 'hybridRunbookWorker'
//   location: location
//   properties: {
//     publisher: 'Microsoft.Azure.Automation.HybridWorker'
//     type: 'HybridWorkerForWindows'
//     typeHandlerVersion: '0.1'
//     autoUpgradeMinorVersion: true
//     settings: {
//       AutomationAccountURL: reference(automationAccount.id).AutomationHybridServiceUrl
//     }
//   }
// }

// resource hybridRunbookWorkerVM 'Microsoft.Automation/automationAccounts/hybridRunbookWorkerGroups/hybridRunbookWorkers@2021-06-22' = {
//   name: 'hybridRunbookWorkerVM'
//   parent: hybridRunbookWorkerGroup
//   properties: {
//     vmResourceId: vmADDC[0].id
//   }
// }

// resource hybridRunbookWorkerGroup 'Microsoft.Automation/automationAccounts/hybridRunbookWorkerGroups@2021-06-22' = {
//   parent: automationAccount
//   name: hybridRunbookWorkerGroupName
// }
