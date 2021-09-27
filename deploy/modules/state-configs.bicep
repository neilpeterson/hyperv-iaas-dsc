param automationAccountName string
param location string = resourceGroup().location

param hypervConfiguration object = {
  name: 'hyperv'
  description: 'A configuration for installing Hyper-V.'
  script: 'https://raw.githubusercontent.com/neilpeterson/hyperv-iaas-dsc/main/config/hyperv.ps1'
}

param addcConfiguration object = {
  name: 'addc'
  description: 'A configuration for installing AADC.'
  script: 'https://raw.githubusercontent.com/neilpeterson/hyperv-iaas-dsc/main/config/addc.ps1'
}

param iisConfiguration object = {
  name: 'iis'
  description: 'A configuration for installing IIS.'
  script: 'https://raw.githubusercontent.com/neilpeterson/hyperv-iaas-dsc/main/config/iis.ps1'
}

param rodcConfiguration object = {
  name: 'rodc'
  description: 'A configuration for installing a read only domain controller.'
  script: 'https://raw.githubusercontent.com/neilpeterson/hyperv-iaas-dsc/main/config/rodc.ps1'
}

param memberConfiguration object = {
  name: 'member'
  description: 'A configuration for installing a member server.'
  script: 'https://raw.githubusercontent.com/neilpeterson/hyperv-iaas-dsc/main/config/member.ps1'
}

resource dscConfigADDC 'Microsoft.Automation/automationAccounts/configurations@2019-06-01' = {
  name: '${automationAccountName}/${addcConfiguration.name}'
  location: location
  properties: {
    logVerbose: false
    description: addcConfiguration.description
    source: {
      type: 'uri'
      value: addcConfiguration.script
    }
  }
}

resource dscConfigHyperv 'Microsoft.Automation/automationAccounts/configurations@2019-06-01' = {
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
}

resource dscConfigRODC 'Microsoft.Automation/automationAccounts/configurations@2019-06-01' = {
  name: '${automationAccountName}/${rodcConfiguration.name}'
  location: location
  properties: {
    logVerbose: false
    description: rodcConfiguration.description
    source: {
      type: 'uri'
      value: rodcConfiguration.script
    }
  }
}

resource dscConfigIIS 'Microsoft.Automation/automationAccounts/configurations@2019-06-01' = {
  name: '${automationAccountName}/${iisConfiguration.name}'
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


resource dscConfigMember 'Microsoft.Automation/automationAccounts/configurations@2019-06-01' = {
  name: '${automationAccountName}/${memberConfiguration.name}'
  location: location
  properties: {
    logVerbose: false
    description: memberConfiguration.description
    source: {
      type: 'uri'
      value: memberConfiguration.script
    }
  }
}
