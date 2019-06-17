---
external help file: AutomatedLab.Recipe-help.xml
Module Name: AutomatedLab.Recipe
online version:
schema: 2.0.0
---

# Get-LabRecipe

## SYNOPSIS
Get a lab recipe to invoke fresh or from the store

## SYNTAX

```
Get-LabRecipe [[-Name] <String[]>] [[-RecipeContent] <ScriptBlock>] [<CommonParameters>]
```

## DESCRIPTION
Get a lab recipe to invoke fresh or from the store

## EXAMPLES

### Example 1
```powershell
LabRecipe MyLab {
    DeployRoles = 'Domain','PKI'
    VmPrefix    = 'MY'
}
```

Get a new recipe that deploys a Domain and a PKI environment with all VMs having MY as their prefix, eg MYDC01

## PARAMETERS

### -Name
Name of the lab

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RecipeContent
Lab script block to enable a DSL. Possible configuration items:
'Description' - Recipe description
'RequiredProductIsos' - ISOs for special roles like CI_CD or SQL
'DeployRole' - A list of simple roles to deploy. Domain, PKI,CI_CD,SQL,Exchange
'DefaultVirtualizationEngine' - HyperV,Azure,VMWare
'DefaultDomainName' - Specify a different default domain
'DefaultAddressSpace' - Specify a different default address space
'DefaultOperatingSystem' - Specify a different default operating system
'VmPrefix' - The VM name prefix to use

```yaml
Type: ScriptBlock
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
