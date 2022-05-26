param hypervConfiguration object = {
  name: 'hyperv'
  description: 'A configuration for installing Hyper-V.'
  script: 'https://raw.githubusercontent.com/neilpeterson/hyperv-iaas-dsc/hyper-v-lab/config/hyperv-novn.ps1'
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
    parameters: { }
  }
  dependsOn: [
    automationAccount
    dscConfigHyperV
    moduleComputerManagement
    moduleSChannelDsc
    moduleComputerManagement
    moduleNetworking
    moduleStorageDsc
  ]
}

resource diskHyperv 'Microsoft.Compute/disks@2020-09-30' = {
  name: 'disk'
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


resource nicHyperV 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: 'nicHyperV'
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

resource HyperVVM 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: 'hyperv'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D8s_v3'
    }
    osProfile: {
      computerName: 'hyperv'
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
            id: diskHyperv.id
          }
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicHyperV.id
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
}

resource dscHyperV 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  parent: HyperVVM
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
    moduleComputerManagement
    moduleComputerManagement
    dscCompilationBaseOS
    dscConfigBaseOS
  ]
}
