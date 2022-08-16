param adminUserName string
@secure()
param adminPassword string
param vmCount int
param virtualMachineSize string
param virtualMachineNamePrefix string
param location string
param virtualMachineSKU string
param nicNamePrefix string
param virtualNetworkID string
param subnetName string
param storageAccountName string
param logAnalyticsWorkspaceID string
param logAnalyticsWorkspaceName string

resource storageaccount 'Microsoft.Storage/storageAccounts@2021-02-01' existing = {
  name: storageAccountName
}

resource nicFITVM 'Microsoft.Network/networkInterfaces@2020-05-01' = [for i in range(0, vmCount): {
  name: '${nicNamePrefix}-${i}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: '${virtualNetworkID}/subnets/${subnetName}'
          }
        }
      }
    ]
  }
}]

resource virtualMachine 'Microsoft.Compute/virtualMachines@2019-07-01' = [for i in range(0, vmCount): {
  name: '${virtualMachineNamePrefix}-${i}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    osProfile: {
      computerName: '${virtualMachineNamePrefix}-${i}'
      adminUsername: adminUserName
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: virtualMachineSKU
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
  }
  identity: {
    type: 'SystemAssigned'
  }
}]

resource azureMonitoringDependencyAgent 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = [for i in range(0, vmCount): {
  parent: virtualMachine[i]
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
  parent: virtualMachine[i]
  name: 'MMAExtension'
  location: location
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'MicrosoftMonitoringAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      workspaceId: reference(resourceId('Microsoft.OperationalInsights/workspaces/', logAnalyticsWorkspaceName), '2020-08-01').customerId
      azureResourceId: virtualMachine[i].id
      stopOnMultipleConnections: true
    }
    protectedSettings: {
      workspaceKey: listKeys(logAnalyticsWorkspaceID, '2020-08-01').primarySharedKey
    }
  }
}]

resource windowsVMGuestConfigExtension 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = [for i in range(0, vmCount): {
  name: '${virtualMachine[i].name}/AzurePolicyforWindows'
  location: location
  properties: {
    publisher: 'Microsoft.GuestConfiguration'
    type: 'ConfigurationforWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
  }
}]

