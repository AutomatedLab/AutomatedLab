---
external help file: AutomatedLabDefinition-help.xml
Module Name: AutomatedLabDefinition
online version:
schema: 2.0.0
---

# Get-LabMachineDefinition

## SYNOPSIS
Returns all machine definitions in the lab

## SYNTAX

### ByName (Default)
```
Get-LabMachineDefinition [[-ComputerName] <String[]>] [<CommonParameters>]
```

### ByRole
```
Get-LabMachineDefinition -Role <Roles> [<CommonParameters>]
```

### All
```
Get-LabMachineDefinition [-All] [<CommonParameters>]
```

## DESCRIPTION
Returns all machine definitions in the lab

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LabMachineDefinition -Role WebServer
```

Get all WebServer machine definitions

## PARAMETERS

### -ComputerName
The machine definitions to return

```yaml
Type: String[]
Parameter Sets: ByName
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Role
The roles to filter the machine definitions on

```yaml
Type: Roles
Parameter Sets: ByRole
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -All
Indicates that all definitions should be returned

```yaml
Type: SwitchParameter
Parameter Sets: All
Aliases:

Required: True
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
