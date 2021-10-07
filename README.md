# State configuration ++ playground

Two deployments can be found under the deployments directory:

- **dc-only.bicep** - deploys an Azure Auzotomation account, Automation credentials, a Log Analytics workspace, a set of sample DSC configurations, required PowerShell modules, a domain controller (using DSC), and the Azure Monitor solution for Active Directory health. 
- **main.bicep** - Extends the base deployment by adding a Hyper-V host. The Hyper-V host is populated with three virtual machines, all configured to bootstrap into the Azure Automation State Configugurtaon solution on first boot. This deployment has a dependency on an Azure Managed disc found in my subscription, so, whomp-whomp for you, sorry. I would be happy to help bootstrap the dependant resources in your own environment.

The dc-only.bicep file is also converted to an ARM JSON template .via a GitHub action. This is so that a deploy to Azure button can be used from this repo. Click the button to deploy the solution.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fneilpeterson%2Fhyperv-iaas-dsc%2Fmain%2Fdeploy%2Fdc-only.json)





