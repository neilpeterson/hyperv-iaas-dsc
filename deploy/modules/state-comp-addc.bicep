param automationAccountName string
param domainName string
param location string = resourceGroup().location

param addcConfiguration object = {
  name: 'addc'
  description: 'A configuration for installing AADC.'
  script: 'https://raw.githubusercontent.com/neilpeterson/hyperv-iaas-dsc/main/config/addc.ps1'
}

resource dscCompilationADDC 'Microsoft.Automation/automationAccounts/compilationjobs@2020-01-13-preview' = {
  name: '${automationAccountName}/${addcConfiguration.name}'
  location: location
  properties: {
    configuration: {
      name: addcConfiguration.name
    }
    parameters: {
      ConfigurationData: '{"AllNodes":[{"NodeName":"localhost","PSDSCAllowPlainTextPassword":true}]}'
      DomainName: domainName
    }
  }
}
