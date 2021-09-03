resource scriptRoleAssignment 'Microsoft.Authorization/roleAssignments@2021-04-01-preview' = {
  name: guid('${resourceGroup().id}contributor')
  properties: {
    roleDefinitionId: contributorRoleDefinitionId
    principalId: reference(scriptIdentity.id, '2018-11-30').principalId
    scope: resourceGroup().id
    principalType: 'ServicePrincipal'
  }
}

resource hypervModule 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'hypervmodule'
  kind: 'AzurePowerShell'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${scriptIdentity.id}': {}
    }
  }
  properties: {
    azPowerShellVersion: '5.0'
    primaryScriptUri: 'https://raw.githubusercontent.com/neilpeterson/hyperv-iaas-dsc/master/config/module.ps1'
    arguments: '-resourceGroup ${resourceGroup().name} -automationAccount ${automationAccountName}'
    retentionInterval: 'P1D'
  }
  dependsOn: [
    scriptRoleAssignment
  ]
}
