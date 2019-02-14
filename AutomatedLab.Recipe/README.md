# AutomatedLab.Recipe

AutomatedLab.Recipe is a small module that helps you get started with AutomatedLab with very simple recipes that use standard building blocks.

## Listing templates

AutomatedLab comes with a few predefined templates that you can get with ```Get-LabRecipe```. You can filter on a name as well to retrieve a single recipe, such as ```Get-LabRecipe -Name DomainAndPki```

## Creating new templates

In order to create new templates, you can either use ```New-LabRecipe``` or our (very basic) DSL:

### New-LabRecipe

```powershell
# Create a recipe
New-LabRecipe -Name dsc -Description 'Deploy pull server' -VmPrefix DDD -DeployRole DSCPull

# PassThru returns the recipe directly
New-LabRecipe -Name dsc -Description 'Deploy pull server' -VmPrefix DDD -DeployRole DSCPull -PassThru
```  

All recipes are stored in ```$HOME\automatedlab\recipes``` in separate JSON files.

### DSL

```powershell
# Just calling LabRecipe returns the recipe
LabRecipe DomainAndExchange {
    DeployRole = 'Domain','Exchange'
    VmPrefix = 'DE'
}

# Either pipe the result to Save-LabRecipe
LabRecipe DomainAndExchange {
    DeployRole = 'Domain','Exchange'
    VmPrefix = 'DE'
} | Save-LabRecipe

# Or directly invoke it with Invoke-LabRecipe
LabRecipe DomainAndExchange {
    DeployRole = 'Domain','Exchange'
    VmPrefix = 'DE'
} | Invoke-LabRecipe
```

## Invoking recipes

To invoke a stored or generated recipe, the ```Invoke-LabRecipe``` cmdlet can be used.

```powershell
# Either stored
Get-LabRecipe -Name DscWithSqlReporting | Invoke-LabRecipe

# Or inline
LabRecipe DomainAndExchange {
    DeployRole = 'Domain','Exchange'
    VmPrefix = 'DE'
} | Invoke-LabRecipe

# PassThru returns the resulting script, NoDeploy skips the deployment
# OutFile will store the lab script
$scriptBlock = Invoke-LabRecipe -Name Dsc -OutFile .\DscLab.ps1 -NoDeploy -PassThru
& $scriptBlock
```
