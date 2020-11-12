---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Remove-Lab

## SYNOPSIS
Remove the lab

## SYNTAX

### Path (Default)
```
Remove-Lab [-WhatIf] [-Confirm] [<CommonParameters>]
```

### ByPath
```
Remove-Lab -Path <String> [-WhatIf] [-Confirm] [<CommonParameters>]
```

### ByName
```
Remove-Lab [-Name] <String> [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Fully removes the current lab, the lab stored at a specific location or a named lab.
For Azure-based labs, the lab resource group is removed completely, regardless of additional machines deployed to the resource group

## EXAMPLES

### Example 1
```powershell
PS C:\> Remove-Lab -Name MyOldLab
```

Removes the lab with the name MyOldLab

## PARAMETERS

### -WhatIf
Indicates if a trial run should be executed

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

### -Confirm
Indicates that all actions need confirmation

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

### -Path
The path to the lab

```yaml
Type: String
Parameter Sets: ByPath
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
The name of the lab

```yaml
Type: String
Parameter Sets: ByName
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
