@secure()
param adminPassword string
param adminUserName string
param automationAccountKey string
param autoamtionAccountURL string
param location string = resourceGroup().location
param sharedManagedDisk string = '/subscriptions/3762d87c-ddb8-425f-b2fc-29e5e859edaf/resourcegroups/vhd-storage/providers/Microsoft.Compute/disks/dsc-vhd'
param subnetId string
param vmSize string = 'Standard_D8s_v3'
param workspaceId string
@secure()
param workspaceKey string

param hypervVirtualMachine object = {
  name: 'vm-hyperv'
  nicName: 'nic-hyperv'
  windowsOSVersion: '2022-datacenter'
  diskName: 'addc-data'
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
            id: subnetId
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

resource azureMonitoringAgent 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = {
  parent: vmHyperv
  name: 'OMSExtension'
  location: location
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'MicrosoftMonitoringAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      workspaceId: workspaceId
    }
    protectedSettings: {
      workspaceKey: workspaceKey
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
}
