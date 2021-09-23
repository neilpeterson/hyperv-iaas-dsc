Azure Bicep template + DSC Configurations to do the following:

- Deploy Azure Automation State Configuration
- Deploy an Azure Automation credential object
- Deploy a log analytic instance and configure some logging
- Import all needed PowerShell DSC modules *
- Deploy a VM which is configured as an ADDC .via state configuration *
- Deploy a VM which is configured as a Hyper-V host .via state configuration *

* There are two templates found in this repository. The first deploys only the solution shared components (Azure Automation account, Log Analytics instance, PowerShell Modules, Credentials, and DSC configurations). The second template deploys and end to end sandboxed experience with virtual machines etc. however has a dependency on a managed disk found in my Azure subscription. 

## Deploy

Click this button to deploy an Azure Automation instance, configuration modules, configuration credentials, and a domain controller and Hyper-V configuration. On the deployment form, create a new resource group, specify an admin username and password. Leave the default values for the remaining parameters.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fneilpeterson%2Fhyperv-iaas-dsc%2Fmaster%2Fdeploy%2Fautomation-only.json)

## Other things

The deploy to Azure button works for native JSON ARM templates, however not Azure Bicep templates. Wanting to provide a portal deployment option, I have added a GitHub Action to decompile the Bicep template to JSON at each commit. This configuration has proven to work great and powers the 'deploy to Azure' button found in this document.

The GitHub action can be seen here - [link](https://github.com/neilpeterson/hyperv-iaas-dsc/blob/master/.github/workflows/bicep-build.yml).