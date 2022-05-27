param AzSecPackRole string
param AzSecPackAcct string
param AzSecPackNS string
param AzSecPackCert string
param automationAccountName string
param location string

param baseOSConfiguration object = {
  name: 'base-fit'
  description: 'Configures an S360 compliant VM.'
  script: 'https://raw.githubusercontent.com/neilpeterson/hyperv-iaas-dsc/hyper-v-lab/configs/baseos.ps1'
}

param hypervConfiguration object = {
  name: 'hyperv'
  description: 'A configuration for installing Hyper-V.'
  script: 'https://raw.githubusercontent.com/neilpeterson/hyperv-iaas-dsc/hyper-v-lab/configs/hyperv.ps1'
}

resource automationAccount 'Microsoft.Automation/automationAccounts@2021-06-22' = {
  name: automationAccountName
  location: location
  properties: {
    sku: {
      name: 'Basic'
    }
  }
}

resource moduleComputerManagement 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
  parent: automationAccount
  name: 'ComputerManagementDsc'
  location: location
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/api/v2/package/ComputerManagementDsc/8.5.0'
      version: '8.5.0'
    }
  }
}

resource moduleSChannelDsc 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
  parent: automationAccount
  name: 'SChannelDsc'
  location: location
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/api/v2/package/SChannelDsc/1.3.0'
      version: '1.3.0'
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

resource dscConfigBaseOS 'Microsoft.Automation/automationAccounts/configurations@2019-06-01' = {
  name: '${automationAccountName}/${baseOSConfiguration.name}'
  location: location
  properties: {
    logVerbose: false
    description: baseOSConfiguration.description
    source: {
      type: 'uri'
      value: baseOSConfiguration.script
    }
  }
  dependsOn: [
    automationAccount
  ]
}

resource dscCompilationBaseOS 'Microsoft.Automation/automationAccounts/compilationjobs@2020-01-13-preview' = {
  name: '${automationAccountName}/${baseOSConfiguration.name}'
  location: location
  properties: {
    configuration: {
      name: baseOSConfiguration.name
    }
    parameters: {
      AzSecPackRole: AzSecPackRole
      AzSecPackAcct: AzSecPackAcct
      AzSecPackNS: AzSecPackNS
      AzSecPackCert: AzSecPackCert
    }
  }
  dependsOn: [
    automationAccount
    dscConfigBaseOS
    moduleComputerManagement
    moduleSChannelDsc
  ]
}

resource dscConfigHyperV 'Microsoft.Automation/automationAccounts/configurations@2019-06-01' = {
  name: '${automationAccountName}/${hypervConfiguration.name}'
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
    automationAccount
  ]
}

resource dscCompilationHyperV 'Microsoft.Automation/automationAccounts/compilationjobs@2020-01-13-preview' = {
  name: '${automationAccountName}/${hypervConfiguration.name}'
  location: location
  properties: {
    configuration: {
      name: hypervConfiguration.name
    }
    parameters: {
      AzSecPackRole: AzSecPackRole
      AzSecPackAcct: AzSecPackAcct
      AzSecPackNS: AzSecPackNS
      AzSecPackCert: AzSecPackCert
    }
  }
  dependsOn: [
    automationAccount
    dscConfigHyperV
    moduleComputerManagement
    moduleSChannelDsc
    moduleComputerManagement
    moduleNetworking
    moduleStorageDsc
  ]
}

output autoamtionAccountID string = automationAccount.id
output automationAccountURI string = reference(automationAccount.id).registrationUrl
