param automationAccountName string
param dnsServer string
param location string = resourceGroup().location

param hypervConfiguration object = {
  name: 'hyperv'
  description: 'A configuration for installing Hyper-V.'
  script: 'https://raw.githubusercontent.com/neilpeterson/hyperv-iaas-dsc/main/config/hyperv.ps1'
}

param rodcConfiguration object = {
  name: 'rodc'
  description: 'A configuration for installing a read only domain controller.'
  script: 'https://raw.githubusercontent.com/neilpeterson/hyperv-iaas-dsc/main/config/rodc.ps1'
}

param iisConfiguration object = {
  name: 'iis'
  description: 'A configuration for installing IIS.'
  script: 'https://raw.githubusercontent.com/neilpeterson/hyperv-iaas-dsc/main/config/iis.ps1'
}

param memberConfiguration object = {
  name: 'member'
  description: 'A configuration for installing a member server.'
  script: 'https://raw.githubusercontent.com/neilpeterson/hyperv-iaas-dsc/main/config/member.ps1'
}

resource dscCompilationHyperv 'Microsoft.Automation/automationAccounts/compilationjobs@2020-01-13-preview' = {
  name: '${automationAccountName}/${hypervConfiguration.name}'
  location: location
  properties: {
    incrementNodeConfigurationBuild: false
    configuration: {
      name: hypervConfiguration.name
    }
    parameters: {
      ConfigurationData: '{"AllNodes":[{"NodeName":"localhost","PSDSCAllowPlainTextPassword":true}]}'
      DomainName: 'contoso.com'
      DNSAddress: dnsServer
    }
  }
}

resource dscCompilationRODC 'Microsoft.Automation/automationAccounts/compilationjobs@2020-01-13-preview' = {
  name: '${automationAccountName}/${rodcConfiguration.name}'
  location: location
  properties: {
    configuration: {
      name: rodcConfiguration.name
    }
    parameters: {
      ConfigurationData: '{"AllNodes":[{"NodeName":"localhost","PSDSCAllowPlainTextPassword":true}]}'
      DomainName: 'contoso.com'
      DNSAddress: dnsServer
    }
  }
  dependsOn: [
    dscCompilationHyperv
  ]
}

resource dscCompilationIIS 'Microsoft.Automation/automationAccounts/compilationjobs@2020-01-13-preview' = {
  name: '${automationAccountName}/${iisConfiguration.name}'
  location: location
  properties: {
    incrementNodeConfigurationBuild: false
    configuration: {
      name: iisConfiguration.name
    }
    parameters: {
      ConfigurationData: '{"AllNodes":[{"NodeName":"localhost","PSDSCAllowPlainTextPassword":true}]}'
      DomainName: 'contoso.com'
      DNSAddress: dnsServer
    }
  }
  dependsOn: [
    dscCompilationRODC
  ]
}

resource dscCompilationMember 'Microsoft.Automation/automationAccounts/compilationjobs@2020-01-13-preview' = {
  name: '${automationAccountName}/${memberConfiguration.name}'
  location: location
  properties: {
    incrementNodeConfigurationBuild: false
    configuration: {
      name: memberConfiguration.name
    }
    parameters: {
      ConfigurationData: '{"AllNodes":[{"NodeName":"localhost","PSDSCAllowPlainTextPassword":true}]}'
      DomainName: 'contoso.com'
      DNSAddress: dnsServer
    }
  }
  dependsOn: [
    dscCompilationIIS
  ]
}
