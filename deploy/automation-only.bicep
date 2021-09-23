param adminUserName string

@secure()
param adminPassword string

param location string = resourceGroup().location
param logAnalyticsWorkspaceName string = uniqueString(subscription().subscriptionId, resourceGroup().id)
param automationAccountName string = uniqueString(resourceGroup().id)

param hypervConfiguration object = {
  name: 'hyperv'
  description: 'A configuration for installing Hyper-V.'
  script: 'https://raw.githubusercontent.com/neilpeterson/hyperv-iaas-dsc/master/config/hyperv.ps1'
}

param addcConfiguration object = {
  name: 'ADDC'
  description: 'A configuration for installing AADC.'
  script: 'https://raw.githubusercontent.com/neilpeterson/hyperv-iaas-dsc/master/config/addc.ps1'
}

param iisConfiguration object = {
  name: 'IIS'
  description: 'A configuration for installing IIS.'
  script: 'https://raw.githubusercontent.com/neilpeterson/hyperv-iaas-dsc/master/config/iis.ps1'
}

resource logAnalyticsWrokspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'Free'
    }
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
  location: 'eastus'
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/api/v2/package/ActiveDirectoryDsc/6.0.1'
      version: '6.0.1'
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

resource moduleXNetworking 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
  parent: automationAccount
  name: 'xNetworking'
  location: location
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/api/v2/package/xNetworking/5.7.0.0'
      version: '5.7.0.0'
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

resource dscConfigADDC 'Microsoft.Automation/automationAccounts/configurations@2019-06-01' = {
  name: addcConfiguration.name
  parent: automationAccount
  location: location
  properties: {
    logVerbose: false
    description: addcConfiguration.description
    source: {
      type: 'uri'
      value: addcConfiguration.script
    }
  }
  dependsOn: [
    moduleStorageDsc
    moduleXActiveDirectory
    moduleXNetworking
    moduleXPendingReboot
  ]
}

resource dscConfigHyperv 'Microsoft.Automation/automationAccounts/configurations@2019-06-01' = {
  parent: automationAccount
  name: hypervConfiguration.name
  location: location
  properties: {
    logVerbose: false
    description: hypervConfiguration.description
    source: {
      type: 'uri'
      value: hypervConfiguration.script
    }
  }
  dependsOn: [
    moduleXActiveDirectory
    moduleXComputerManagement
    moduleXHyperv
    moduleXPendingReboot
  ]
}

resource dscConfigIIS 'Microsoft.Automation/automationAccounts/configurations@2019-06-01' = {
  parent: automationAccount
  name: iisConfiguration.name
  location: location
  properties: {
    logVerbose: false
    description: iisConfiguration.description
    source: {
      type: 'uri'
      value: iisConfiguration.script
    }
  }
}
