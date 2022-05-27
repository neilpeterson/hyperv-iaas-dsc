param keyVaultName string
param virtualMachineIdentity string

resource keyVault 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = {
  name: keyVaultName
}

resource keyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2021-11-01-preview' = {
  name: 'add'
  parent: keyVault
  properties: {
    accessPolicies: [
      {
        objectId: virtualMachineIdentity
        tenantId: subscription().tenantId
        permissions: {
          secrets: [
            'list'
            'get'
          ]
        }
      }
    ]
  }
}
