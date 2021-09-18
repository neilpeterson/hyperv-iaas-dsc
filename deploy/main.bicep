// Build test

param adminUserName string

@secure()
param adminPassword string

param vmSize string = 'Standard_D8s_v3'
param location string = resourceGroup().location
param logAnalyticsWorkspaceName string = uniqueString(subscription().subscriptionId, resourceGroup().id)
param automationAccountName string = uniqueString(resourceGroup().id)
param sharedManagedDisk string = '/subscriptions/3762d87c-ddb8-425f-b2fc-29e5e859edaf/resourceGroups/AUTOMATION-CENTRAL-001/providers/Microsoft.Compute/disks/vhd-dsc-bootstrap'

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

param hypervConfiguration object = {
  name: 'hyperv'
  description: 'A configuration for installing Hyper-V.'
  script: 'https://raw.githubusercontent.com/neilpeterson/hyperv-iaas-dsc/master/config/hyperv.ps1'
}

param addcConfiguration object = {
  name: 'addc'
  description: 'A configuration for installing AADC.'
  script: 'https://raw.githubusercontent.com/neilpeterson/hyperv-iaas-dsc/master/config/addc.ps1'
}

param iisConfiguration object = {
  name: 'iis'
  description: 'A configuration for installing IIS.'
  script: 'https://raw.githubusercontent.com/neilpeterson/hyperv-iaas-dsc/master/config/iis.ps1'
}

param rodcConfiguration object = {
  name: 'rodc'
  description: 'A configuration for installing a read only domain controller.'
  script: 'https://raw.githubusercontent.com/neilpeterson/hyperv-iaas-dsc/master/config/rodc.ps1'
}

param dhcpConfiguration object = {
  name: 'dhcp'
  description: 'A configuration for installing a DHCP server.'
  script: 'https://raw.githubusercontent.com/neilpeterson/hyperv-iaas-dsc/master/config/dhcp.ps1'
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

resource logAnalyticsWrokspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'Free'
    }
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
  location: 'eastus'
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/api/v2/package/ActiveDirectoryDsc/6.0.1'
      version: '6.0.1'
    }
  }
}

resource moduleXActiveDirectory 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
  parent: automationAccount
  name: 'xActiveDirectory'
  location: location
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/api/v2/package/xActiveDirectory/3.0.0.0'
      version: '3.0.0.0'
    }
  }
}

resource moduleXNetworking 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
  parent: automationAccount
  name: 'xNetworking'
  location: location
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/api/v2/package/xNetworking/5.7.0.0'
      version: '5.7.0.0'
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

resource moduleXDhcpServer 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
  parent: automationAccount
  name: 'xDhcpServer'
  location: location
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/api/v2/package/xDhcpServer/3.0.0'
      version: '3.0.0'
    }
  }
}

resource dscConfigADDC 'Microsoft.Automation/automationAccounts/configurations@2019-06-01' = {
  name: addcConfiguration.name
  parent: automationAccount
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
    moduleStorageDsc
    moduleXActiveDirectory
    moduleXNetworking
    moduleXPendingReboot
  ]
}

resource dscCompilationADDC 'Microsoft.Automation/automationAccounts/compilationjobs@2020-01-13-preview' = {
  // compilation job is not idempotent? - https://github.com/Azure/azure-powershell/issues/8921
  // https://stackoverflow.com/questions/54508062/how-to-i-prevent-microsoft-automation-automationaccounts-compilationjobs-to-alwa
  parent: automationAccount
  name: addcConfiguration.name
  location: location
  properties: {
    configuration: {
      name: addcConfiguration.name
    }
    parameters: {
      ConfigurationData: '{"AllNodes":[{"NodeName":"localhost","PSDSCAllowPlainTextPassword":true}]}'
      DomainName: 'contoso.com'
    }
  }
  dependsOn: [
    dscConfigADDC
    automationCredentials
  ]
}

resource dscConfigRODC 'Microsoft.Automation/automationAccounts/configurations@2019-06-01' = {
  name: rodcConfiguration.name
  parent: automationAccount
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
    moduleStorageDsc
    moduleActiveDirectoryDsc
    moduleXNetworking
    moduleXPendingReboot
  ]
}

resource dscCompilationRODC 'Microsoft.Automation/automationAccounts/compilationjobs@2020-01-13-preview' = {
  // compilation job is not idempotent? - https://github.com/Azure/azure-powershell/issues/8921
  // https://stackoverflow.com/questions/54508062/how-to-i-prevent-microsoft-automation-automationaccounts-compilationjobs-to-alwa
  parent: automationAccount
  name: rodcConfiguration.name
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
    dscConfigRODC
    automationCredentials
  ]
}

resource dscConfigHyperv 'Microsoft.Automation/automationAccounts/configurations@2019-06-01' = {
  parent: automationAccount
  name: hypervConfiguration.name
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
    moduleXActiveDirectory
    moduleXComputerManagement
    moduleXHyperv
    moduleXPendingReboot
  ]
}

resource dscCompilationHyperv 'Microsoft.Automation/automationAccounts/compilationjobs@2020-01-13-preview' = {
  // compilation job is not idempotent? - https://github.com/Azure/azure-powershell/issues/8921
  parent: automationAccount
  name: '${hypervConfiguration.name}'
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
      ComputerName: hypervVirtualMachine.name
    }
  }
  dependsOn: [
    dscConfigHyperv
    automationCredentials
  ]
}

resource dscConfigIIS 'Microsoft.Automation/automationAccounts/configurations@2019-06-01' = {
  parent: automationAccount
  name: iisConfiguration.name
  location: location
  properties: {
    logVerbose: false
    description: iisConfiguration.description
    source: {
      type: 'uri'
      value: iisConfiguration.script
    }
  }
}

resource dscCompilationIIS 'Microsoft.Automation/automationAccounts/compilationjobs@2020-01-13-preview' = {
  // compilation job is not idempotent? - https://github.com/Azure/azure-powershell/issues/8921
  parent: automationAccount
  name: iisConfiguration.name
  location: location
  properties: {
    incrementNodeConfigurationBuild: false
    configuration: {
      name: iisConfiguration.name
    }
  }
  dependsOn: [
    dscConfigIIS
  ]
}

resource dscConfigDHCP 'Microsoft.Automation/automationAccounts/configurations@2019-06-01' = {
  parent: automationAccount
  name: dhcpConfiguration.name
  location: location
  properties: {
    logVerbose: false
    description: dhcpConfiguration.description
    source: {
      type: 'uri'
      value: dhcpConfiguration.script
    }
  }
}

resource dscCompilationDHCP 'Microsoft.Automation/automationAccounts/compilationjobs@2020-01-13-preview' = {
  // compilation job is not idempotent? - https://github.com/Azure/azure-powershell/issues/8921
  parent: automationAccount
  name: dhcpConfiguration.name
  location: location
  properties: {
    incrementNodeConfigurationBuild: false
    configuration: {
      name: dhcpConfiguration.name
    }
    parameters: {
      ConfigurationData: '{"AllNodes":[{"NodeName":"localhost","PSDSCAllowPlainTextPassword":true}]}'
      DomainName: 'contoso.com'
      DNSAddress: nicADDC.properties.ipConfigurations[0].properties.privateIPAddress
    }
  }
  dependsOn: [
    dscConfigDHCP
    moduleXDhcpServer
    moduleXPendingReboot
    moduleXComputerManagement
    moduleActiveDirectoryDsc
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

resource vnetHubDiagnostics 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
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
      // logicalSectorSize: 4096
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
          Value: '${addcConfiguration.name}.localhost'
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
    dscCompilationADDC
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
      // logicalSectorSize: 4096
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
        {
          createOption: 'Attach'
          lun: 2
          managedDisk: {
            id: sharedManagedDisk
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
          Value: '${hypervConfiguration.name}.localhost'
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
    moduleXHyperv
    moduleXActiveDirectory
    moduleXPendingReboot
    dscADDC
  ]
}
