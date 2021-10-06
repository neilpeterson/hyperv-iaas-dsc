There are two deployments found in this repository. The first template deploys an Azure Auzotomation account, Automation credentials, a Log Analytics workspace, a set of sample DSC configurations, required PowerShell modules, a domain controller (using DSC), and the Azure Monitor solution for Active Directory health.

Use this button to deploy this template:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fneilpeterson%2Fhyperv-iaas-dsc%2Fmain%2Fdeploy%2Fdc-only.json)

The second template extends the base deployment adding two virtual machines and supporting infrastructure (VNET, NSGs, Bastion). Both virtual machines are auto-enrolled in the automation solution. The first is configured as a domain controller, and the second is a Hyper-V host. The Hyper-V is populated with three virtual machines, all configured to bootstrap into the Azure Automation State Configugurtaon solution on first boot. This deployment has a dependency on an Azure Managed disc found in my subscription.