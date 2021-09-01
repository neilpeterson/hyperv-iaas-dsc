param adminUserName string
param vmSize string = 'Standard_D8s_v3'

@secure()
param adminPassword string

// @secure()
// param pass string

param hubNetwork object = {
  name: 'vnet-hub'
  addressPrefix: '10.0.0.0/20'
}

param resourceSubnet object = {
  subnetName: 'ResourceSubnet'
  nsgName: 'nsg-hub-resources'
  subnetPrefix: '10.0.2.0/24'
}

param bastionHost object = {
  name: 'AzureBastionHost'
  publicIPAddressName: 'pip-bastion'
  subnetName: 'AzureBastionSubnet'
  nsgName: 'nsg-hub-bastion'
  subnetPrefix: '10.0.1.0/29'
}

param windowsConfiguration object = {
  name: 'windowsfeatures'
  description: 'A configuration for installing Hyper-V.'
  script: 'https://raw.githubusercontent.com/neilpeterson/hyperv-iaas-dsc/master/config/hyperv.ps1'
}

param location string = resourceGroup().location

var nicNameWindows = 'nic-windows'
var vmNameWindows = 'vm-windows'
var windowsOSVersion = '2022-datacenter'
var logAnalyticsWorkspaceName = uniqueString(subscription().subscriptionId, resourceGroup().id)
var automationAccountName_var = uniqueString(resourceGroup().id)

resource logAnalyticsWrokspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'Free'
    }
  }
}

resource automationAccountName 'Microsoft.Automation/automationAccounts@2020-01-13-preview' = {
  name: automationAccountName_var
  location: location
  properties: {
    sku: {
      name: 'Basic'
    }
  }
}

resource hypervmodule 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
  name: 'hyper-v-module'
  parent: automationAccountName
  location: location
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/api/v2/package/xhyper-v/3.18.0-preview0001'
    }
  }
}

resource config 'Microsoft.Automation/automationAccounts/configurations@2019-06-01' = {
  parent: automationAccountName
  name: '${windowsConfiguration.name}'
  location: location
  properties: {
    logVerbose: false
    description: windowsConfiguration.description
    source: {
      type: 'uri'
      value: windowsConfiguration.script
    }
  }
}

resource compilationjob 'Microsoft.Automation/automationAccounts/compilationjobs@2020-01-13-preview' = {
  parent: automationAccountName
  name: '${windowsConfiguration.name}'
  location: location
  properties: {
    configuration: {
      name: windowsConfiguration.name
    }
    parameters: { 
      // Compilation parameters
    }
  }
  dependsOn: [
    config
    hypervmodule
  ]
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
        }
      }
      {
        name: resourceSubnet.subnetName
        properties: {
          addressPrefix: resourceSubnet.subnetPrefix
        }
      }
    ]
  }
}

resource diahVnetHub 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'diahVnetHub'
  scope: vnetHub
  properties: {
    workspaceId: logAnalyticsWrokspace.id
    logs: [
      {
        category: 'VMProtectionAlerts'
        enabled: true
      }
    ]
  }
}

resource bastionPip 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
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

resource bastionHostResource 'Microsoft.Network/bastionHosts@2020-06-01' = {
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
            id: bastionPip.id
          }
        }
      }
    ]
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2020-08-01' = {
  name: 'nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'DenyAllInBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'HTTP'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '80'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource nicNameWindowsResource 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: nicNameWindows
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
}

resource vmNameWindowsResource 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: vmNameWindows
  location: location
  dependsOn:[
    nicNameWindowsResource
  ]
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmNameWindows
      adminUsername: adminUserName
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: windowsOSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', nicNameWindows)
        }
      ]
    }
  }
}

// resource windowsVMName_Microsoft_Powershell_DSC 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
//   name: '${vmNameWindows}/Microsoft.Powershell.DSC'
//   location: location
//   dependsOn: [
//     vmNameWindowsResource
//   ]
//   properties: {
//     publisher: 'Microsoft.Powershell'
//     type: 'DSC'
//     typeHandlerVersion: '2.76'
//     protectedSettings: {
//       Items: {
//         registrationKeyPrivate: listKeys(automationAccountName.id, '2019-06-01').Keys[0].value
//       }
//     }
//     settings: {
//       Properties: [
//         {
//           Name: 'RegistrationKey'
//           Value: {
//             UserName: 'PLACEHOLDER_DONOTUSE'
//             Password: 'PrivateSettingsRef:registrationKeyPrivate'
//           }
//           TypeName: 'System.Management.Automation.PSCredential'
//         }
//         {
//           Name: 'RegistrationUrl'
//           Value: automationAccountName.properties.registrationUrl
//           TypeName: 'System.String'
//         }
//         {
//           Name: 'NodeConfigurationName'
//           Value: '${windowsConfiguration.name}.localhost'
//           TypeName: 'System.String'
//         }
//         {
//           Name: 'ConfigurationMode'
//           Value: 'ApplyAndMonitor'
//           TypeName: 'System.String'
//         }
//         {
//           Name: 'ConfigurationModeFrequencyMins'
//           Value: 15
//           TypeName: 'System.Int32'
//         }
//         {
//           Name: 'RefreshFrequencyMins'
//           Value: 30
//           TypeName: 'System.Int32'
//         }
//         {
//           Name: 'RebootNodeIfNeeded'
//           Value: true
//           TypeName: 'System.Boolean'
//         }
//         {
//           Name: 'ActionAfterReboot'
//           Value: 'ContinueConfiguration'
//           TypeName: 'System.String'
//         }
//         {
//           Name: 'AllowModuleOverwrite'
//           Value: false
//           TypeName: 'System.Boolean'
//         }
//       ]
//     }
//   }
// }
