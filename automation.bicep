var automationAccountName = uniqueString(resourceGroup().id)
param location string = resourceGroup().location

resource automationAccount 'Microsoft.Automation/automationAccounts@2020-01-13-preview' = {
  name: automationAccountName
  location: location
  properties: {
    sku: {
      name: 'Basic'
    }
  }
}

resource adModule 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
  name: 'StorageDsc'
  parent: automationAccount
  location: location
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/api/v2/package/StorageDsc/5.0.1'
      version: '5.0.1'
    }
  }
}

resource xActiveDirectory 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
  name: 'xActiveDirectory'
  parent: automationAccount
  location: location
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/api/v2/package/xActiveDirectory/3.0.0.0'
      version: '3.0.0.0'
    }
  }
}

resource xNetworking 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
  name: 'xNetworking'
  parent: automationAccount
  location: location
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/api/v2/package/xNetworking/5.7.0.0'
      version: '5.7.0.0'
    }
  }
}

resource xPendingReboot 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
  name: 'xPendingReboot'
  parent: automationAccount
  location: location
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/api/v2/package/xPendingReboot/0.4.0.0'
      version: '0.4.0.0'
    }
  }
}

resource xHyperV 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
  name: 'xHyper-V'
  parent: automationAccount
  location: location
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/api/v2/package/xHyper-V/3.17.0.0'
      version: '3.17.0.0'
    }
  }
}
