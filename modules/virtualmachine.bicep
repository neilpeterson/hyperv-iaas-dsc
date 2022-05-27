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
param keyVaultName string
param keyVaultResourceGroup string
param keyVaultSubscriptionID string
param AzSecPackCertificateName string
param automationAccountURI string
param automationAccountID string
param logAnalyticsWorkspaceID string
param logAnalyticsWorkspaceName string
param config string
param bastionHostSubnetPrefix string
param resourceSubnetPrefix string

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

resource managementPortJITPolicy 'Microsoft.Security/locations/jitNetworkAccessPolicies@2020-01-01' = [for i in range(0, vmCount): {
  name: '${location}/${virtualMachineNamePrefix}-${i}'
  kind: 'Basic'
  properties: {
    virtualMachines: [
      {
        id: virtualMachine[i].id
        ports: [
          {
            number: 3389
            protocol: '*'
            allowedSourceAddressPrefixes: [
              bastionHostSubnetPrefix
            ]
            maxRequestAccessDuration: 'PT8H'
          }
          {
            number: 5985
            protocol: '*'
            allowedSourceAddressPrefixes: [
              resourceSubnetPrefix
            ]
            maxRequestAccessDuration: 'PT8H'
          }
        ]
      }
    ]
  }
}]

module keyVaultAccess './keyvaultaccess.bicep' = [for i in range(0, vmCount): {
  scope: resourceGroup(keyVaultSubscriptionID , keyVaultResourceGroup)
  name: virtualMachine[i].name
  params: {
    keyVaultName: keyVaultName
    virtualMachineIdentity: reference(virtualMachine[i].id, '2019-07-01', 'full').identity.principalId
  }
}]

resource keyVaultCertificates 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = [for i in range(0, vmCount): {
  name: '${virtualMachine[i].name}/KeyVaultForWindows'
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
          AzSecPackCertificateName
        ]
      }
    }
  }
  dependsOn: [
    keyVaultAccess
  ]
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

resource genevaMonitoring 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = [for i in range(0, vmCount): {
  parent: virtualMachine[i]
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

module DSCConfigBase 'vmconfigs.bicep' = [for i in range(0, vmCount): if (config == 'BaseOS') {
  name: 'DSCConfigs-${i}'
  params: {
    location: location
    automationAccountID: automationAccountID
    automationAccountURI: automationAccountURI
    virtualMachineName: '${virtualMachineNamePrefix}-${i}'
    config: 'BaseOS'
  }
  dependsOn: [
    virtualMachine[i]
  ]
}]

module DSCConfigHyperV 'vmconfigs.bicep' = [for i in range(0, vmCount): if (config == 'HyperV') {
  name: 'DSCConfigsHyperV-${i}'
  params: {
    location: location
    automationAccountID: automationAccountID
    automationAccountURI: automationAccountURI
    virtualMachineName: '${virtualMachineNamePrefix}-0'
    config: 'HyperV'
  }
  dependsOn: [
    virtualMachine[0]
  ]
}]

resource reboot 'Microsoft.Compute/virtualMachines/extensions@2020-06-01'= [for i in range(0, vmCount): {
  name: '${virtualMachine[i].name}/ForceReboot'
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
    keyVaultAccess
    keyVaultCertificates
    azureMonitoringDependencyAgent
    azureMonitoringAgent
    genevaMonitoring
    windowsVMGuestConfigExtension
    DSCConfigBase
    DSCConfigHyperV
  ]
}]

