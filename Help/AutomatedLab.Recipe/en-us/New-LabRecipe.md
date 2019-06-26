---
external help file: AutomatedLab.Recipe-help.xml
Module Name: AutomatedLab.Recipe
online version:
schema: 2.0.0
---

# New-LabRecipe

## SYNOPSIS
Create and store a new lab recipe

## SYNTAX

```
New-LabRecipe [-Name] <String> [[-Description] <String>] [[-VmPrefix] <String>] [-DeployRole] <String[]>
 [[-DefaultVirtualizationEngine] <String>] [[-DefaultDomainName] <String>] [[-DefaultAddressSpace] <IPNetwork>]
 [[-DefaultOperatingSystem] <OperatingSystem>] [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Create and store a new lab recipe that can be called with Get-LabRecipe and Invoke-LabRecipe later on

## EXAMPLES

### Example 1
```powershell
PS C:\> New-LabRecipe -Name Build -Description 'Build environment for tests' -DeployRole Domain
```

This recipe deploys a minuscule environment for automated tests

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
Default address space for a new lab

```yaml
Type: IPNetwork
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DefaultDomainName
Default domain name for a new lab

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DefaultOperatingSystem
Default OS for a new lab

```yaml
Type: OperatingSystem
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DefaultVirtualizationEngine
Default virtualization engine for a new lab

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: HyperV, Azure, VMWare

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DeployRole
Roles to deploy

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:
Accepted values: Domain, PKI, SQL, Exchange, CI_CD, DSCPull

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description
The description to set for a recipe

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Indicates that the target recipe will be overwritten if already present

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

### -Name
Name of the recipe

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
Indicates that the recipe will be returned, so that it can be piped to Invoke-LabRecipe for example

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

### -VmPrefix
The default prefix for new VMs

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
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

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
