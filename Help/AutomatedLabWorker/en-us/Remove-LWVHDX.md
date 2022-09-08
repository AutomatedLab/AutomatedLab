---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version: https://automatedlab.org/en/latest/AutomatedLabWorker/en-us/Remove-LWVHDX
schema: 2.0.0
---

# Remove-LWVHDX

## SYNOPSIS
Remove a VHDX file

## SYNTAX

```
Remove-LWVHDX [-VhdxPath] <String> [<CommonParameters>]
```

## DESCRIPTION
Remove a VHDX file

## EXAMPLES

### Example 1
```powershell
PS C:\> Remove-LWVHDX -VhdxPath D:\Some.vhdx
```

Remove the file Some.vhdx

## PARAMETERS

### -VhdxPath
The path to the VHDX file

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS

