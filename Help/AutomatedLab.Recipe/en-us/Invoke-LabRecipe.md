---
external help file: AutomatedLab.Recipe-help.xml
Module Name: AutomatedLab.Recipe
online version:
schema: 2.0.0
---

# Invoke-LabRecipe

## SYNOPSIS
{{ Fill in the Synopsis }}

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
{{ Fill in the Description }}

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

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
{{ Fill DefaultAddressSpace Description }}

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
{{ Fill DefaultDomainName Description }}

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
{{ Fill DefaultOperatingSystem Description }}

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
{{ Fill DefaultVirtualizationEngine Description }}

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
{{ Fill LabCredential Description }}

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
{{ Fill Name Description }}

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
{{ Fill NoDeploy Description }}

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
{{ Fill OutFile Description }}

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
{{ Fill PassThru Description }}

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
{{ Fill Recipe Description }}

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
