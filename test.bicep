param location string = resourceGroup().location

param windowsConfiguration object = {
  name: 'windowsfeatures'
  description: 'A configuration for installing Hyper-V.'
  script: 'https://raw.githubusercontent.com/neilpeterson/hyperv-iaas-dsc/master/config/hyperv.ps1'
}

var contributorRoleDefinitionId = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
var automationAccountName = uniqueString(resourceGroup().id)

resource automationAccount 'Microsoft.Automation/automationAccounts@2020-01-13-preview' = {
  name: automationAccountName
  location: 'eastus'
  properties: {
    sku: {
      name: 'Basic'
    }
  }
}

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'midentity'
  location: 'eastus'
}

resource role 'Microsoft.Authorization/roleAssignments@2021-04-01-preview' = {
  name: guid('${resourceGroup().id}contributor')
  properties: {
    roleDefinitionId: contributorRoleDefinitionId
    principalId: reference(identity.id, '2018-11-30').principalId
    scope: resourceGroup().id
    principalType: 'ServicePrincipal'
  }
}

resource hypervmodule 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'hypervmodule'
  kind: 'AzurePowerShell'
  location: 'eastus'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identity.id}': {}
    }
  }
  properties: {
    azPowerShellVersion: '5.0'
    // scriptContent: 'New-AzAutomationModule -AutomationAccountName ${automationAccountName} -ResourceGroupName ${resourceGroup().name} -Name "xHyper-V" -ContentLinkUri "https://www.powershellgallery.com/api/v2/package/xHyper-V/3.17.0.0"'
    primaryScriptUri: 'https://raw.githubusercontent.com/neilpeterson/hyperv-iaas-dsc/master/config/module.ps1'
    arguments: '-resourceGroup ${resourceGroup().name}, -automationAccount ${automationAccountName}'
    retentionInterval: 'P1D'
  }
  dependsOn: [
    role
  ]
}

resource config 'Microsoft.Automation/automationAccounts/configurations@2019-06-01' = {
  parent: automationAccount
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
  dependsOn: [
    hypervmodule
  ]
}

resource compilationjob 'Microsoft.Automation/automationAccounts/compilationjobs@2020-01-13-preview' = {
  parent: automationAccount
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
  ]
}

