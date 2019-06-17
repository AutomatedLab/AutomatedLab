---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# New-LabVM

## SYNOPSIS
Create a new virtual machine

## SYNTAX

### ByName
```
New-LabVM -Name <String[]> [-CreateCheckPoints] [-ProgressIndicator <Int32>] [<CommonParameters>]
```

### All
```
New-LabVM [-All] [-CreateCheckPoints] [-ProgressIndicator <Int32>] [<CommonParameters>]
```

## DESCRIPTION
Creates new virtual machines for the machine definitions present in the lab

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -Name
The names of the machines to create

```yaml
Type: String[]
Parameter Sets: ByName
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CreateCheckPoints
Indicates if a checkpoint should be created after machine creation

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

### -All
Indicates that all lab machines should be created

```yaml
Type: SwitchParameter
Parameter Sets: All
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressIndicator
Every n seconds, print a . to the console

```yaml
Type: Int32
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

## OUTPUTS

## NOTES

## RELATED LINKS
