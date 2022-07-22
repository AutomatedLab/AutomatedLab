---
Module Name: AutomatedLab.Recipe
Module Guid: 0c1fa63a-6982-48c3-bc12-c74806861b08
Download Help Link: {{ Update Download Link }}
Help Version: 1.0.0.0
Locale: en-US
---

# AutomatedLab.Recipe Module
## Description
The AutomatedLab.Recipe module was intended to make simple labs even easier. Through a pseudo-DSL and a handful of cmdlets, you can deploy very simple labs like Domain with PKI on the go.
```powershell
LabRecipe SuperEasy {    
    DeployRole = 'Domain', 'PKI'
} | Invoke-LabRecipe
```

## AutomatedLab.Recipe Cmdlets
### [Export-LabSnippet](Export-LabSnippet.md)
Export a snippet

### [Get-LabRecipe](Get-LabRecipe.md)
Get a lab recipe to invoke fresh or from the store

### [Get-LabSnippet](Get-LabSnippet.md)
Get a (filtered) list of lab code snippets

### [Invoke-LabRecipe](Invoke-LabRecipe.md)
Invoke a recipe

### [Invoke-LabSnippet](Invoke-LabSnippet.md)
Invoke one or more lab snippets

### [New-LabRecipe](New-LabRecipe.md)
Create and store a new lab recipe

### [New-LabSnippet](New-LabSnippet.md)
Create a new snippet, sample or custom role

### [Remove-LabRecipe](Remove-LabRecipe.md)
Remove a stored recipe

### [Remove-LabSnippet](Remove-LabSnippet.md)
Remove one or more snippets

### [Save-LabRecipe](Save-LabRecipe.md)
Save a lab recipe to disk

### [Set-LabSnippet](Set-LabSnippet.md)
Update a snippet

### [Update-LabSnippet](Update-LabSnippet.md)
Update the list of lab snippets

