---
external help file: AutomatedLabDefinition-help.xml
Module Name: AutomatedLabDefinition
online version: https://automatedlab.org/en/latest/AutomatedLabDefinition/en-us/Set-LabDefinition
schema: 2.0.0
---

# Set-LabDefinition

## SYNOPSIS
Helper cmdlet to update the lab definition

## SYNTAX

```
Set-LabDefinition [[-Lab] <Lab>] [[-Machines] <Machine[]>] [[-Disks] <Disk[]>] [<CommonParameters>]
```

## DESCRIPTION
Helper cmdlet to update the lab definition

## EXAMPLES

### Example 1
```powershell
PS C:\> Set-LabDefinition -Lab (Get-LabDefinition) -Machines $machines -Disks $disks
```

Update the existing lab definition with a current list of machines and disks

## PARAMETERS

### -Disks
A list of disk definitions

```yaml
Type: Disk[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Lab
The lab definition

```yaml
Type: Lab
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Machines
A list of machine definitions

```yaml
Type: Machine[]
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

