---
Module Name: AutomatedLab.Recipe
Module Guid: 0c1fa63a-6982-48c3-bc12-c74806861b08
Download Help Link: {{ Update Download Link }}
Help Version: 1.0.0.0
Locale: en-US
---

# AutomatedLab.Recipe Module
## Description
The AutomatedLab.Recipe module was intended to make simple labs even easier. Through a pseudo-DSL
and a handful of cmdlets, you can deploy very simple labs like Domain with PKI on the go.

```powershell
LabRecipe SuperEasy {    
    DeployRole = 'Domain', 'PKI'
} | Invoke-LabRecipe
```