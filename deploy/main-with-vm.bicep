param adminUserName string
@secure()
param adminPassword string
param vmCount int = 2

param automationAccountName string = uniqueString(resourceGroup().id)
param location string = resourceGroup().location
param logAnalyticsWorkspaceName string = uniqueString(subscription().subscriptionId, resourceGroup().id)
param vmSize string = 'Standard_D3_v2'
param avalilabilitySetName string = uniqueString(resourceGroup().id)

param AzSecPackRole string = 'MTPFITADDomainSvc'
param AzSecPackAcct string = 'RoverAzSecPackGenevaLogAccnt1'
param AzSecPackNS string = 'MTPFITADDomainSvc'
param AzSecPackCert string = '67cf050d3732fb104a46a9b3b5a56521f837f39f'

param baseOSConfiguration object = {
  name: 'base-fit'
  description: 'Configures an S360 compliant VM.'
  script: 'https://raw.githubusercontent.com/neilpeterson/hyperv-iaas-dsc/hyper-v-lab/config/base-fit.ps1'
}

param hypervConfiguration object = {
  name: 'hyperv'
  description: 'A configuration for installing Hyper-V.'
  script: 'https://raw.githubusercontent.com/neilpeterson/hyperv-iaas-dsc/hyper-v-lab/config/hyperv.ps1'
}

param AzSecPackCertificate string = 'https://US01-PROD-MTPAUTOMATION.vault.azure.net/secrets/AzSecPack'

param addcVirtualMachine object = {
  name: 'fit-lab-vm'
  nicName: 'fit-lab-vm'
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

resource automationAccount 'Microsoft.Automation/automationAccounts@2021-06-22' = {
  name: automationAccountName
  location: location
  properties: {
    sku: {
      name: 'Basic'
    }
  }
}

resource moduleComputerManagement 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
  parent: automationAccount
  name: 'ComputerManagementDsc'
  location: location
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/api/v2/package/ComputerManagementDsc/8.5.0'
      version: '8.5.0'
    }
  }
}

resource moduleSChannelDsc 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
  parent: automationAccount
  name: 'SChannelDsc'
  location: location
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/api/v2/package/SChannelDsc/1.3.0'
      version: '1.3.0'
    }
  }
}

resource moduleActiveDirectoryDsc 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
  parent: automationAccount
  name: 'ActiveDirectoryDsc'
  location: location
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/api/v2/package/ActiveDirectoryDsc/6.2.0-preview0001'
      version: '6.2.0'
    }
  }
}

resource moduleNetworking 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
  parent: automationAccount
  name: 'NetworkingDsc'
  location: location
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/api/v2/package/NetworkingDsc/8.2.0'
      version: '8.2.0'
    }
  }
}

resource moduleXHyperv 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
  parent: automationAccount
  name: 'xHyper-V'
  location: location
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/api/v2/package/xHyper-V/3.17.0.0'
      version: '3.17.0.0'
    }
  }
}

resource moduleXPendingReboot 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
  parent: automationAccount
  name: 'xPendingReboot'
  location: location
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/api/v2/package/xPendingReboot/0.4.0.0'
      version: '0.4.0.0'
    }
  }
}

resource moduleXComputerManagement 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
  parent: automationAccount
  name: 'xComputerManagement'
  location: location
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/api/v2/package/xComputerManagement/4.1.0'
      version: '3.0.0.0'
    }
  }
}

resource moduleStorageDsc 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
  parent: automationAccount
  name: 'StorageDsc'
  location: location
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/api/v2/package/StorageDsc/5.0.1'
      version: '5.0.1'
    }
  }
}

resource dscConfigBaseOS 'Microsoft.Automation/automationAccounts/configurations@2019-06-01' = {
  name: '${automationAccountName}/${baseOSConfiguration.name}'
  location: location
  properties: {
    logVerbose: false
    description: baseOSConfiguration.description
    source: {
      type: 'uri'
      value: baseOSConfiguration.script
    }
  }
  dependsOn: [
    automationAccount
  ]
}

resource dscCompilationBaseOS 'Microsoft.Automation/automationAccounts/compilationjobs@2020-01-13-preview' = {
  name: '${automationAccountName}/${baseOSConfiguration.name}'
  location: location
  properties: {
    configuration: {
      name: baseOSConfiguration.name
    }
    parameters: {
      AzSecPackRole: AzSecPackRole
      AzSecPackAcct: AzSecPackAcct
      AzSecPackNS: AzSecPackNS
      AzSecPackCert: AzSecPackCert
    }
  }
  dependsOn: [
    automationAccount
    dscConfigBaseOS
    moduleComputerManagement
    moduleSChannelDsc
  ]
}

resource dscConfigHyperV 'Microsoft.Automation/automationAccounts/configurations@2019-06-01' = {
  name: '${automationAccountName}/${hypervConfiguration.name}'
  location: location
  properties: {
    logVerbose: false
    description: hypervConfiguration.description
    source: {
      type: 'uri'
      value: hypervConfiguration.script
    }
  }
  dependsOn: [
    automationAccount
  ]
}


resource dscCompilationHyperV 'Microsoft.Automation/automationAccounts/compilationjobs@2020-01-13-preview' = {
  name: '${automationAccountName}/${hypervConfiguration.name}'
  location: location
  properties: {
    configuration: {
      name: hypervConfiguration.name
    }
    parameters: {
      ConfigurationData: '{"AllNodes":[{"NodeName":"localhost","PSDSCAllowPlainTextPassword":true}]}'
      DomainName: 'contoso.com'
      DNSAddress: nicADDC.properties.ipConfigurations[0].properties.privateIPAddress
    }
  }
  dependsOn: [
    automationAccount
    dscConfigBaseOS
    moduleComputerManagement
    moduleSChannelDsc
    moduleActiveDirectoryDsc
    moduleComputerManagement
    moduleNetworking
    moduleStorageDsc
    moduleXComputerManagement
    moduleXHyperv
    moduleXPendingReboot
  ]
}

resource AvailabilitySet 'Microsoft.Compute/availabilitySets@2020-12-01' = {
  name: avalilabilitySetName
  location: location
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 2
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

resource nicFITVM 'Microsoft.Network/networkInterfaces@2020-05-01' = [for i in range(0, vmCount): {
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

resource FITVM 'Microsoft.Compute/virtualMachines@2019-07-01' = [for i in range(0, vmCount): {
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
          id: nicFITVM[i].id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageaccount.properties.primaryEndpoints.blob
      }
    }
    availabilitySet: {
      id: AvailabilitySet.id
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}]

module KeyVaultAccess './modules/key-vault-access.bicep' = [for i in range(0, vmCount): {
  scope: resourceGroup('7aab1e63-3115-4365-89bc-bf1172dc93c9','US01-PRDMTPAA-RG')
  name: FITVM[i].name
  params: {
    KeyVaultName: 'US01-PROD-MTPAUTOMATION'
    VirtualMachineIdentity: reference(FITVM[i].id, '2019-07-01', 'full').identity.principalId
  }
}]

resource KeyVaultCertificates 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = [for i in range(0, vmCount): {
  name: '${FITVM[i].name}/KeyVaultForWindows'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.KeyVault'
    type: 'KeyVaultForWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      secretsManagementSettings: {
        pollingIntervalInS: '3600'
        certificateStoreName: 'MY'
        certificateStoreLocation: 'LocalMachine'
        observedCertificates: [
          AzSecPackCertificate
        ]
      }
    }
  }
  dependsOn: [
    KeyVaultAccess
  ]
}]

resource dscBaseOS 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = [for i in range(0, vmCount): {
  parent: FITVM[i]
  name: 'Microsoft.Powershell.DSC'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.76'
    protectedSettings: {
      Items: {
        registrationKeyPrivate: listKeys(automationAccount.id, '2019-06-01').Keys[0].value
      }
    }
    settings: {
      Properties: [
        {
          Name: 'RegistrationKey'
          Value: {
            UserName: 'PLACEHOLDER_DONOTUSE'
            Password: 'PrivateSettingsRef:registrationKeyPrivate'
          }
          TypeName: 'System.Management.Automation.PSCredential'
        }
        {
          Name: 'RegistrationUrl'
          Value: automationAccount.properties.registrationUrl
          TypeName: 'System.String'
        }
        {
          Name: 'NodeConfigurationName'
          Value: 'fit.localhost'
          TypeName: 'System.String'
        }
        {
          Name: 'ConfigurationMode'
          Value: 'ApplyAndAutoCorrect'
          TypeName: 'System.String'
        }
        {
          Name: 'ConfigurationModeFrequencyMins'
          Value: 15
          TypeName: 'System.Int32'
        }
        {
          Name: 'RefreshFrequencyMins'
          Value: 30
          TypeName: 'System.Int32'
        }
        {
          Name: 'RebootNodeIfNeeded'
          Value: true
          TypeName: 'System.Boolean'
        }
        {
          Name: 'ActionAfterReboot'
          Value: 'ContinueConfiguration'
          TypeName: 'System.String'
        }
        {
          Name: 'AllowModuleOverwrite'
          Value: false
          TypeName: 'System.Boolean'
        }
      ]
    }
  }
  dependsOn: [
    moduleComputerManagement
    moduleComputerManagement
    FITVM[i]
    dscCompilationBaseOS
    dscConfigBaseOS
  ]
}]

resource azureMonitoringDependencyAgent 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = [for i in range(0, vmCount): {
  parent: FITVM[i]
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
  parent: FITVM[i]
  name: 'MMAExtension'
  location: location
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'MicrosoftMonitoringAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      workspaceId: reference(resourceId('Microsoft.OperationalInsights/workspaces/', logAnalyticsWorkspaceName), '2020-08-01').customerId
      azureResourceId: FITVM[i].id
      stopOnMultipleConnections: true
    }
    protectedSettings: {
      workspaceKey: listKeys(logAnalyticsWorkspace.id, '2020-08-01').primarySharedKey
    }
  }
}]

resource GenevaMonitoring 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = [for i in range(0, vmCount):  {
  parent: FITVM[i]
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

// resource ManagementPortJITPolicy 'Microsoft.Security/locations/jitNetworkAccessPolicies@2020-01-01' = [for i in range(0, vmCount): {
//   name: '${location}/${addcVirtualMachine.name}-${i}'
//   kind: 'Basic'
//   properties: {
//     virtualMachines: [
//       {
//         id: FITVM[i].id
//         ports: [
//           {
//             number: 3389
//             protocol: '*'
//             allowedSourceAddressPrefixes: [
//               bastionHost.subnetPrefix
//             ]
//             maxRequestAccessDuration: 'PT8H'
//           }
//           {
//             number: 5985
//             protocol: '*'
//             allowedSourceAddressPrefixes: [
//               resourceSubnet.subnetPrefix
//             ]
//             maxRequestAccessDuration: 'PT8H'
//           }
//         ]
//       }
//     ]
//   }
// }]

resource windowsVMGuestConfigExtension 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = [for i in range(0, vmCount): {
  name: '${FITVM[i].name}/AzurePolicyforWindows'
  location: location
  properties: {
    publisher: 'Microsoft.GuestConfiguration'
    type: 'ConfigurationforWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
  }
}]

resource Reboot 'Microsoft.Compute/virtualMachines/extensions@2020-06-01'= [for i in range(0, vmCount): {
  name: '${FITVM[i].name}/LCMBootStrap'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.7'
    autoUpgradeMinorVersion: true
    protectedSettings: {
      commandToExecute: 'powershell.exe -c Restart-Computer -Force'
    }
  }
  dependsOn: [
    KeyVaultAccess
    KeyVaultCertificates
    dscBaseOS
    azureMonitoringDependencyAgent
    azureMonitoringAgent
    GenevaMonitoring
    windowsVMGuestConfigExtension
  ]
}]
