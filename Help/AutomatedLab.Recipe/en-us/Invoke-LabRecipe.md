---
external help file: AutomatedLab.Recipe-help.xml
Module Name: AutomatedLab.Recipe
online version:
schema: 2.0.0
---

# Invoke-LabRecipe

## SYNOPSIS
Invoke a recipe

## SYNTAX

### ByName
```
Invoke-LabRecipe -Name <String> [-DefaultVirtualizationEngine <String>] [-LabCredential <PSCredential>]
 [-DefaultOperatingSystem <OperatingSystem>] [-DefaultAddressSpace <IPNetwork>] [-DefaultDomainName <String>]
 [-OutFile <String>] [-PassThru] [-NoDeploy] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### ByRecipe
```
Invoke-LabRecipe -Recipe <Object> [-DefaultVirtualizationEngine <String>] [-LabCredential <PSCredential>]
 [-DefaultOperatingSystem <OperatingSystem>] [-DefaultAddressSpace <IPNetwork>] [-DefaultDomainName <String>]
 [-OutFile <String>] [-PassThru] [-NoDeploy] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Invoke a recipe. Can either export the recipe as a normal script file or directly deploy the lab that
the recipe describes.

## EXAMPLES

### Example 1
```powershell
LabRecipe SuperEasy {    
    DeployRole = 'Domain', 'PKI'
} | Invoke-LabRecipe -NoDeploy -OutFile D:\SuperEasy.ps1
```

Instead of invoking the recipe, stores it as D:\SuperEasy.ps1

## PARAMETERS

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DefaultAddressSpace
Override the default address space of the recipe

```yaml
Type: IPNetwork
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DefaultDomainName
Override the default domain name of the recipe

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DefaultOperatingSystem
Override the default OS of the recipe

```yaml
Type: OperatingSystem
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DefaultVirtualizationEngine
Override the default virtualization engine of the recipe

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: HyperV, Azure, VMWare

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LabCredential
Set a different lab credential

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
The name of the recipe to invoke

```yaml
Type: String
Parameter Sets: ByName
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -NoDeploy
Indicates that no deployment should be attempted

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OutFile
The output file path for the lab script, in order to redeploy it later

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
Return the lab script block to persist it or send it somewhere

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Recipe
The recipe object to invoke, from Get-LabRecipe

```yaml
Type: Object
Parameter Sets: ByRecipe
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

### System.Object

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
