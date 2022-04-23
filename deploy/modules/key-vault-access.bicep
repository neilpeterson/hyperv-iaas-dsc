param KeyVaultName string
param VirtualMachineIdentity string

resource keyVault 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = {
  name: KeyVaultName
}

resource KeyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2021-11-01-preview' = {
  name: 'add'
  parent: keyVault
  properties: {
    accessPolicies: [
      {
        objectId: VirtualMachineIdentity
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
