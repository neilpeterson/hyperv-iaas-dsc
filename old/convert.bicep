@description('Specifies the name of the key vault.')
param keyVaultName string

@description('Specifies the Azure location where the key vault should be created.')
param location string = resourceGroup().location

@description('Specifies whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the key vault.')
@allowed([
  true
  false
])
param enabledForDeployment bool = false

@description('Specifies whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys.')
@allowed([
  true
  false
])
param enabledForDiskEncryption bool = false

@description('Specifies whether Azure Resource Manager is permitted to retrieve secrets from the key vault.')
@allowed([
  true
  false
])
param enabledForTemplateDeployment bool = false

@description('Specifies the Azure Active Directory tenant ID that should be used for authenticating requests to the key vault. Get it by using Get-AzSubscription cmdlet.')
param tenantId string = subscription().tenantId

@description('Specifies the object ID of a user, service principal or security group in the Azure Active Directory tenant for the vault. The object ID must be unique for the list of access policies. Get it by using Get-AzADUser or Get-AzADServicePrincipal cmdlets.')
param objectId string

@description('Specifies the permissions to keys in the vault. Valid values are: all, encrypt, decrypt, wrapKey, unwrapKey, sign, verify, get, list, create, update, import, delete, backup, restore, recover, and purge.')
param keysPermissions array = [
  'list'
]

@description('Specifies the permissions to secrets in the vault. Valid values are: all, get, list, set, delete, backup, restore, recover, and purge.')
param secretsPermissions array = [
  'list'
]

@description('Specifies whether the key vault is a standard vault or a premium vault.')
@allowed([
  'Standard'
  'Premium'
])
param skuName string = 'Standard'

@description('Specifies the name of the user-assigned managed identity.')
param identityName string

@description('Specifies the permissions to certificates in the vault. Valid values are: all, get, list, update, create, import, delete, recover, backup, restore, manage contacts, manage certificate authorities, get certificate authorities, list certificate authorities, set certificate authorities, delete certificate authorities.')
param certificatesPermissions array = [
  'get'
  'list'
  'update'
  'create'
]
param certificateName string = 'DeploymentScripts2019'
param subjectName string = 'CN=contoso.com'
param utcValue string = utcNow()

var bootstrapRoleAssignmentId_var = guid('${resourceGroup().id}contributor')
var contributorRoleDefinitionId = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'

resource identityName_resource 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: identityName
  location: resourceGroup().location
}

resource bootstrapRoleAssignmentId 'Microsoft.Authorization/roleAssignments@2018-09-01-preview' = {
  name: bootstrapRoleAssignmentId_var
  properties: {
    roleDefinitionId: contributorRoleDefinitionId
    principalId: reference(identityName_resource.id, '2018-11-30').principalId
    scope: resourceGroup().id
    principalType: 'ServicePrincipal'
  }
}

resource keyVaultName_resource 'Microsoft.KeyVault/vaults@2018-02-14' = {
  name: keyVaultName
  location: location
  properties: {
    enabledForDeployment: enabledForDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enabledForTemplateDeployment: enabledForTemplateDeployment
    tenantId: tenantId
    accessPolicies: [
      {
        objectId: objectId
        tenantId: tenantId
        permissions: {
          keys: keysPermissions
          secrets: secretsPermissions
          certificates: certificatesPermissions
        }
      }
      {
        objectId: reference(identityName_resource.id, '2018-11-30').principalId
        tenantId: tenantId
        permissions: {
          keys: keysPermissions
          secrets: secretsPermissions
          certificates: certificatesPermissions
        }
      }
    ]
    sku: {
      name: skuName
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

resource createAddCertificate 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'createAddCertificate'
  location: resourceGroup().location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identityName_resource.id}': {}
    }
  }
  kind: 'AzurePowerShell'
  properties: {
    forceUpdateTag: utcValue
    azPowerShellVersion: '5.0'
    timeout: 'PT30M'
    arguments: ' -vaultName ${keyVaultName} -certificateName ${certificateName} -subjectName ${subjectName}'
    scriptContent: '\n            param(\n              [string] [Parameter(Mandatory=$true)] $vaultName,\n              [string] [Parameter(Mandatory=$true)] $certificateName,\n              [string] [Parameter(Mandatory=$true)] $subjectName\n            )\n  \n            $ErrorActionPreference = \'Stop\'\n            $DeploymentScriptOutputs = @{}\n  \n            $existingCert = Get-AzKeyVaultCertificate -VaultName $vaultName -Name $certificateName\n  \n            if ($existingCert -and $existingCert.Certificate.Subject -eq $subjectName) {\n  \n              Write-Host \'Certificate $certificateName in vault $vaultName is already present.\'\n  \n              $DeploymentScriptOutputs[\'certThumbprint\'] = $existingCert.Thumbprint\n              $existingCert | Out-String\n            }\n            else {\n              $policy = New-AzKeyVaultCertificatePolicy -SubjectName $subjectName -IssuerName Self -ValidityInMonths 12 -Verbose\n  \n              # private key is added as a secret that can be retrieved in the ARM template\n              Add-AzKeyVaultCertificate -VaultName $vaultName -Name $certificateName -CertificatePolicy $policy -Verbose\n  \n              $newCert = Get-AzKeyVaultCertificate -VaultName $vaultName -Name $certificateName\n  \n              # it takes a few seconds for KeyVault to finish\n              $tries = 0\n              do {\n                Write-Host \'Waiting for certificate creation completion...\'\n                Start-Sleep -Seconds 10\n                $operation = Get-AzKeyVaultCertificateOperation -VaultName $vaultName -Name $certificateName\n                $tries++\n  \n                if ($operation.Status -eq \'failed\')\n                {\n                  throw \'Creating certificate $certificateName in vault $vaultName failed with error $($operation.ErrorMessage)\'\n                }\n  \n                if ($tries -gt 120)\n                {\n                  throw \'Timed out waiting for creation of certificate $certificateName in vault $vaultName\'\n                }\n              } while ($operation.Status -ne \'completed\')\n  \n              $DeploymentScriptOutputs[\'certThumbprint\'] = $newCert.Thumbprint\n              $newCert | Out-String\n            }\n          '
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
  }
  dependsOn: [
    keyVaultName_resource
    bootstrapRoleAssignmentId
  ]
}