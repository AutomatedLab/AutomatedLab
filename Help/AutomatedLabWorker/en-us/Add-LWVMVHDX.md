---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# Add-LWVMVHDX

## SYNOPSIS
Attach a VHDX file to a VM

## SYNTAX

```
Add-LWVMVHDX [-VMName] <String> [-VhdxPath] <String> [<CommonParameters>]
```

## DESCRIPTION
Attach a VHDX file to a VM

## EXAMPLES

### Example 1
```powershell
PS C:\> Add-LWVMVHDX -VMName Client01 -VhdxPath D:\SomeFile.vhdx
```

Attaches SomeFile.vhdx to Client01

## PARAMETERS

### -VMName
The virtual machine

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

### -VhdxPath
The VHDX path

```yaml
Type: String
Parameter Sets: (All)
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

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
