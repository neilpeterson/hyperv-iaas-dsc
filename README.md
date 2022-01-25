# State configuration ++ playground

The `main-no-vm.bicep' template deploys an Azure Auzotomation account, Automation credentials, a Log Analytics workspace, a set of sample DSC configurations, required PowerShell modules, a domain controller (using DSC), a domain-joined Hyper-V host (using DSC), and the Azure Monitor solution for Active Directory health.

The Bicep template is also converted to an ARM JSON template .via a GitHub action. This is so that a deploy to Azure button can be used from this repo. Click the button to deploy the solution. For now, deploy to the **east us** or **east us2** region.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fneilpeterson%2Fhyperv-iaas-dsc%2Fmain%2Fdeploy%2Fmain-no-vm.json)

Once deployed, both the domain controller and the Hyper-V host can be accessed .via Bastion.

