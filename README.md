Azure Bicep template + DSC Configurations to do the following:

- Deploy Azure Automation State Configuration
- Deploy an Azure Automation credential object
- Import all needed PowerShell DSC modules
- Deploy a VM which is configured as an ADDC .via state configuration
- Deploy a VM which is configured as a Hyper-V host .via state configuration
- Deploy a log analytic instance and configure some logging

## Deploy

Click this button to deploy the solution. On the deployment form, create a new resource group, specify an admin username and password. Leave the default values for the remaining parameters.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fneilpeterson%2Fhyperv-iaas-dsc%2Fmaster%2Fdeploy%2Fmain.json)

Once completed, find that the two virtual machines have been onboarded into Azure Automation State Configuration and that they are both compliant.

![Screen shot of Azure Automation State Configuration as seen in the Azure portal.](./documentation/dsc-results.png)

## Other things

The deploy to Azure button works for native JSON ARM templates, however not Azure Bicep templates. Wanting to provide a portal deployment option, I have added a GitHub Action to decompile the Bicep template to JSON at each commit. This configuration has proven to work great and powers the 'deploy to Azure' button found in this document.

The GitHub action can be seen here - [link](https://github.com/neilpeterson/hyperv-iaas-dsc/blob/master/.github/workflows/bicep-build.yml).