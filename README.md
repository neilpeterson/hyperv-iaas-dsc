There are two templates found in this repository. The first deploys only the solution shared components (Azure Automation account, Log Analytics instance, PowerShell Modules, Credentials, and DSC configurations). The second template deploys an end-to-end sandboxed experience with virtual machines etc. however has a dependency on a managed disk found in my Azure subscription.

Click this button to deploy an Azure Automation instance, Log Analytics instance, and sample DSC configurations.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fneilpeterson%2Fhyperv-iaas-dsc%2Fmain%2Fdeploy%2Fautomation-only.json)