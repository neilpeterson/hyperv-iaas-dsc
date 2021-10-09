
param adminUserName string

@secure()
param adminPassword string

param automationAccountName string = uniqueString(resourceGroup().id)
param keyVaultName string = 'a${uniqueString(resourceGroup().id)}b'
param location string = resourceGroup().location
param logAnalyticsWorkspaceName string = uniqueString(subscription().subscriptionId, resourceGroup().id)

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'Free'
    }
  }
}

resource dcSolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'ADAssessment(${logAnalyticsWorkspaceName})'
  location: location
  properties: {
    workspaceResourceId: logAnalyticsWorkspace.id
    containedResources: [
      '${logAnalyticsWorkspace.id}/views/ADAssessment(${logAnalyticsWorkspace.name})'
    ]
  }
  plan: {
    name: 'ADAssessment(${logAnalyticsWorkspaceName})'
    product: 'OMSGallery/ADAssessment'
    publisher: 'Microsoft'
    promotionCode: ''
  }
}

resource automationAccount 'Microsoft.Automation/automationAccounts@2020-01-13-preview' = {
  name: automationAccountName
  location: location
  properties: {
    sku: {
      name: 'Basic'
    }
  }
}

resource automationCredentials 'Microsoft.Automation/automationAccounts/credentials@2020-01-13-preview' = {
  parent: automationAccount
  name: 'Admincreds'
  properties: {
    description: 'Admin credentials.'
    password: adminPassword
    userName: adminUserName
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    accessPolicies: [
      
    ]
    tenantId: subscription().tenantId
  }
}

resource moduleStorageDsc 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
  parent: automationAccount
  name: 'StorageDsc'
  location: location
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/api/v2/package/StorageDsc/5.0.1'
      version: '5.0.1'
    }
  }
}

resource moduleActiveDirectoryDsc 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
  parent: automationAccount
  name: 'ActiveDirectoryDsc'
  location: location
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/api/v2/package/ActiveDirectoryDsc/6.2.0-preview0001'
      version: '6.2.0'
    }
  }
}

resource moduleXActiveDirectory 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
  parent: automationAccount
  name: 'xActiveDirectory'
  location: location
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/api/v2/package/xActiveDirectory/3.0.0.0'
      version: '3.0.0.0'
    }
  }
}

resource moduleNetworking 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
  parent: automationAccount
  name: 'NetworkingDsc'
  location: location
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/api/v2/package/NetworkingDsc/8.2.0'
      version: '8.2.0'
    }
  }
}

resource moduleXPendingReboot 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
  parent: automationAccount
  name: 'xPendingReboot'
  location: location
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/api/v2/package/xPendingReboot/0.4.0.0'
      version: '0.4.0.0'
    }
  }
}

resource moduleXHyperv 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
  parent: automationAccount
  name: 'xHyper-V'
  location: location
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/api/v2/package/xHyper-V/3.17.0.0'
      version: '3.17.0.0'
    }
  }
}

resource moduleXComputerManagement 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
  parent: automationAccount
  name: 'xComputerManagement'
  location: location
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/api/v2/package/xComputerManagement/4.1.0'
      version: '3.0.0.0'
    }
  }
}

output automationAccountKey string = listKeys(automationAccount.id, '2019-06-01').Keys[0].value
output automationAccountName string = automationAccountName
output autoamtionAccountURL string = automationAccount.properties.registrationUrl
output workspaceId string = reference(resourceId('Microsoft.OperationalInsights/workspaces/', logAnalyticsWorkspaceName), '2020-08-01').customerId
output workspaceKey string = listKeys(logAnalyticsWorkspace.id, '2020-08-01').primarySharedKey
