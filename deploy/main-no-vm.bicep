param adminUserName string
@secure()
param adminPassword string
param domainName string
param automationAccountName string = uniqueString(resourceGroup().id)
param keyVaultName string = 'a${uniqueString(resourceGroup().id)}b'
param location string = resourceGroup().location
param logAnalyticsWorkspaceName string = uniqueString(subscription().subscriptionId, resourceGroup().id)
param vmSize string = 'Standard_D8s_v3'

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

param addcVirtualMachine object = {
  name: 'vm-addc'
  nicName: 'nic-addc'
  windowsOSVersion: '2022-datacenter'
  diskName: 'data'
}

param hypervVirtualMachine object = {
  name: 'vm-hyperv'
  nicName: 'nic-hyperv'
  windowsOSVersion: '2022-datacenter'
  diskName: 'addc-data'
}

param hypervConfiguration object = {
  name: 'hyperv'
  description: 'A configuration for installing Hyper-V.'
  script: 'https://raw.githubusercontent.com/neilpeterson/hyperv-iaas-dsc/remove-hypv-vm/config/hyperv-novn.ps1'
}

param addcConfiguration object = {
  name: 'addc'
  description: 'A configuration for installing AADC.'
  script: 'https://raw.githubusercontent.com/neilpeterson/hyperv-iaas-dsc/main/config/addc.ps1'
}

param iisConfiguration object = {
  name: 'iis'
  description: 'A configuration for installing IIS.'
  script: 'https://raw.githubusercontent.com/neilpeterson/hyperv-iaas-dsc/main/config/iis.ps1'
}

param rodcConfiguration object = {
  name: 'rodc'
  description: 'A configuration for installing a read only domain controller.'
  script: 'https://raw.githubusercontent.com/neilpeterson/hyperv-iaas-dsc/main/config/rodc.ps1'
}

param memberConfiguration object = {
  name: 'member'
  description: 'A configuration for installing a member server.'
  script: 'https://raw.githubusercontent.com/neilpeterson/hyperv-iaas-dsc/main/config/member.ps1'
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'Free'
    }
  }
}

resource dcSolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'ADAssessment(${logAnalyticsWorkspaceName})'
  location: location
  properties: {
    workspaceResourceId: logAnalyticsWorkspace.id
    containedResources: [
      '${logAnalyticsWorkspace.id}/views/ADAssessment(${logAnalyticsWorkspace.name})'
    ]
  }
  plan: {
    name: 'ADAssessment(${logAnalyticsWorkspaceName})'
    product: 'OMSGallery/ADAssessment'
    publisher: 'Microsoft'
    promotionCode: ''
  }
}

resource automationAccount 'Microsoft.Automation/automationAccounts@2020-01-13-preview' = {
  name: automationAccountName
  location: location
  properties: {
    sku: {
      name: 'Basic'
    }
  }
}

resource automationCredentials 'Microsoft.Automation/automationAccounts/credentials@2020-01-13-preview' = {
  parent: automationAccount
  name: 'Admincreds'
  properties: {
    description: 'Admin credentials.'
    password: adminPassword
    userName: adminUserName
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
    accessPolicies: [
      
    ]
    tenantId: subscription().tenantId
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
          sourceAddressPrefix: bastionHost.subnetPrefix
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

resource dscConfigADDC 'Microsoft.Automation/automationAccounts/configurations@2019-06-01' = {
  name: '${automationAccountName}/${addcConfiguration.name}'
  location: location
  properties: {
    logVerbose: false
    description: addcConfiguration.description
    source: {
      type: 'uri'
      value: addcConfiguration.script
    }
  }
  dependsOn: [
    automationAccount
  ]
}

resource dscConfigHyperv 'Microsoft.Automation/automationAccounts/configurations@2019-06-01' = {
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

resource dscConfigRODC 'Microsoft.Automation/automationAccounts/configurations@2019-06-01' = {
  name: '${automationAccountName}/${rodcConfiguration.name}'
  location: location
  properties: {
    logVerbose: false
    description: rodcConfiguration.description
    source: {
      type: 'uri'
      value: rodcConfiguration.script
    }
  }
  dependsOn: [
    automationAccount
  ]
}

resource dscConfigIIS 'Microsoft.Automation/automationAccounts/configurations@2019-06-01' = {
  name: '${automationAccountName}/${iisConfiguration.name}'
  location: location
  properties: {
    logVerbose: false
    description: iisConfiguration.description
    source: {
      type: 'uri'
      value: iisConfiguration.script
    }
  }
  dependsOn: [
    automationAccount
  ]
}

resource dscConfigMember 'Microsoft.Automation/automationAccounts/configurations@2019-06-01' = {
  name: '${automationAccountName}/${memberConfiguration.name}'
  location: location
  properties: {
    logVerbose: false
    description: memberConfiguration.description
    source: {
      type: 'uri'
      value: memberConfiguration.script
    }
  }
  dependsOn: [
    automationAccount
  ]
}

resource dscCompilationADDC 'Microsoft.Automation/automationAccounts/compilationjobs@2020-01-13-preview' = {
  name: '${automationAccountName}/${addcConfiguration.name}'
  location: location
  properties: {
    configuration: {
      name: addcConfiguration.name
    }
    parameters: {
      ConfigurationData: '{"AllNodes":[{"NodeName":"localhost","PSDSCAllowPlainTextPassword":true}]}'
      DomainName: domainName
    }
  }
  dependsOn: [
    automationAccount
    dscConfigADDC
    moduleStorageDsc
    moduleActiveDirectoryDsc
    moduleXPendingReboot
    moduleNetworking
  ]
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
            id: '${vnetHub.id}/subnets/${resourceSubnet.subnetName}'
          }
        }
      }
    ]
  }
}

resource diskADDC 'Microsoft.Compute/disks@2020-09-30' = {
  name: addcVirtualMachine.diskName
  location: location
  sku: {
    name: 'Premium_LRS'
  }
  properties: {
    creationData: {
      createOption: 'Empty'
    }
    diskSizeGB: 256
    diskIOPSReadWrite: 7500
    diskMBpsReadWrite: 250
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
      dataDisks: [
        {
          createOption: 'Attach'
          lun: 1
          managedDisk: {
            id: diskADDC.id
          }
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', addcVirtualMachine.nicName)
        }
      ]
    }
  }
  dependsOn: [
    nicADDC
  ]
}

resource azureMonitoringAgent 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = {
  parent: vmADDC
  name: 'OMSExtension'
  location: location
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'MicrosoftMonitoringAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      workspaceId: reference(resourceId('Microsoft.OperationalInsights/workspaces/', logAnalyticsWorkspaceName), '2020-08-01').customerId
    }
    protectedSettings: {
      workspaceKey: listKeys(logAnalyticsWorkspace.id, '2020-08-01').primarySharedKey
    }
  }
}

resource dscADDC 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  parent: vmADDC
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
          Value: 'addc.localhost'
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
    dscConfigADDC
    moduleStorageDsc
    moduleActiveDirectoryDsc
    moduleXPendingReboot
    moduleNetworking
    dscConfigADDC
    dscCompilationADDC
  ]
}

resource dscCompilationHyperv 'Microsoft.Automation/automationAccounts/compilationjobs@2020-01-13-preview' = {
  name: '${automationAccountName}/${hypervConfiguration.name}'
  location: location
  properties: {
    incrementNodeConfigurationBuild: false
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
    dscConfigADDC
    moduleStorageDsc
    moduleActiveDirectoryDsc
    moduleXPendingReboot
    moduleNetworking
    moduleXHyperv
  ]
}

resource dscCompilationRODC 'Microsoft.Automation/automationAccounts/compilationjobs@2020-01-13-preview' = {
  name: '${automationAccountName}/${rodcConfiguration.name}'
  location: location
  properties: {
    configuration: {
      name: rodcConfiguration.name
    }
    parameters: {
      ConfigurationData: '{"AllNodes":[{"NodeName":"localhost","PSDSCAllowPlainTextPassword":true}]}'
      DomainName: 'contoso.com'
      DNSAddress: nicADDC.properties.ipConfigurations[0].properties.privateIPAddress
    }
  }
  dependsOn: [
    automationAccount
    dscConfigADDC
    moduleStorageDsc
    moduleActiveDirectoryDsc
    moduleXPendingReboot
    moduleNetworking
  ]
}

resource dscCompilationIIS 'Microsoft.Automation/automationAccounts/compilationjobs@2020-01-13-preview' = {
  name: '${automationAccountName}/${iisConfiguration.name}'
  location: location
  properties: {
    incrementNodeConfigurationBuild: false
    configuration: {
      name: iisConfiguration.name
    }
  }
  dependsOn: [
    automationAccount
    dscConfigADDC
    moduleStorageDsc
    moduleActiveDirectoryDsc
    moduleXPendingReboot
    moduleNetworking
  ]
}

resource dscCompilationMember 'Microsoft.Automation/automationAccounts/compilationjobs@2020-01-13-preview' = {
  name: '${automationAccountName}/${memberConfiguration.name}'
  location: location
  properties: {
    incrementNodeConfigurationBuild: false
    configuration: {
      name: memberConfiguration.name
    }
    parameters: {
      ConfigurationData: '{"AllNodes":[{"NodeName":"localhost","PSDSCAllowPlainTextPassword":true}]}'
      DomainName: 'contoso.com'
      DNSAddress: nicADDC.properties.ipConfigurations[0].properties.privateIPAddress
    }
  }
  dependsOn: [
    automationAccount
    dscConfigADDC
    moduleStorageDsc
    moduleActiveDirectoryDsc
    moduleXPendingReboot
    moduleNetworking
  ]
}

resource nicHyperv 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: hypervVirtualMachine.nicName
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

resource diskHyperv 'Microsoft.Compute/disks@2020-09-30' = {
  name: hypervVirtualMachine.diskName
  location: location
  sku: {
    name: 'Premium_LRS'
  }
  properties: {
    creationData: {
      createOption: 'Empty'
    }
    diskSizeGB: 256
    diskIOPSReadWrite: 7500
    diskMBpsReadWrite: 250
  }
}

resource vmHyperv 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: hypervVirtualMachine.name
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: hypervVirtualMachine.name
      adminUsername: adminUserName
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: hypervVirtualMachine.windowsOSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          createOption: 'Attach'
          lun: 1
          managedDisk: {
            id: diskHyperv.id
          }
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', hypervVirtualMachine.nicName)
        }
      ]
    }
  }
  dependsOn: [
    nicHyperv
  ]
}

resource azureMonitoringAgentHyperv 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = {
  parent: vmHyperv
  name: 'OMSExtension'
  location: location
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'MicrosoftMonitoringAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      workspaceId: reference(resourceId('Microsoft.OperationalInsights/workspaces/', logAnalyticsWorkspaceName), '2020-08-01').customerId
    }
    protectedSettings: {
      workspaceKey: listKeys(logAnalyticsWorkspace.id, '2020-08-01').primarySharedKey
    }
  }
}

resource dscHyperv 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  parent: vmHyperv
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
          Value: 'hyperv.localhost'
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
    vmADDC
    dscConfigADDC
    moduleStorageDsc
    moduleActiveDirectoryDsc
    moduleXPendingReboot
    moduleNetworking
    dscConfigADDC
    dscCompilationADDC
  ]
}
