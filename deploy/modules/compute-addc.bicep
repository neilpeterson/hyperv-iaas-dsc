
@secure()
param adminPassword string
param adminUserName string
param automationAccountKey string
param autoamtionAccountURL string
param location string = resourceGroup().location
param subnetId string
param vmSize string = 'Standard_D8s_v3'

param addcVirtualMachine object = {
  name: 'vm-addc'
  nicName: 'nic-addc'
  windowsOSVersion: '2022-datacenter'
  diskName: 'data'
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
            id: subnetId
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
        registrationKeyPrivate: automationAccountKey
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
          Value: autoamtionAccountURL
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
}

output privateIP string = nicADDC.properties.ipConfigurations[0].properties.privateIPAddress
