Generally speaking AutomatedLab takes care of everything for you when deploying your labs on Azure. Since additional authentication is required it is possible that you need to login to your Azure account before using AutomatedLab.  
AutomatedLab works with Azure Resource Manager, so you can either execute the cmdlet `Connect-AzAccount` before deploying your lab or save your Azure Resource Manager profile.

If you choose to login to your Azure account before a lab deployment your profile is being saved for you to be able to import the lab at a later stage. Since it is possible that your profile expires you might see an error message indicating your profile expiration. In that case, simply login to your Azure account again.

```powershell
New-LabDefinition -Name 'MyLab' -DefaultVirtualizationEngine Azure

# Optional to set e.g. your preferred location
Add-LabAzureSubscription -DefaultLocation 'West Europe'
```

This will enable AutomatedLab to create a lab sources resource group for you as well as a separate resource group for each lab you deploy. Your lab resource group will contain the entire lab deployment and will be removed when you call `Remove-Lab`.