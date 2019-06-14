---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# Remove-LWVMWareVM

## SYNOPSIS
Remove a VMWare virtual machine

## SYNTAX

```
Remove-LWVMWareVM [-ComputerName] <String> [-AsJob] [-PassThru] [<CommonParameters>]
```

## DESCRIPTION
Remove a VMWare virtual machine

## EXAMPLES

### Example 1
```powershell
PS C:\> Remove-LWVMWareVM -ComputerName SomeHost -AsJob -PassThru
```

Removes the VMWare machine SomeHost in a background job and returns
the job object

## PARAMETERS

### -AsJob
Indicates that the cmdlet should run in the background

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

### -ComputerName
The VM to remove

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
Indicates that objects should be returned

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
