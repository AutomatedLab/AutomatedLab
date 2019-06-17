---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Get-LabVMDotNetFrameworkVersion

## SYNOPSIS
Get the .NET Framework version of lab VMs

## SYNTAX

```
Get-LabVMDotNetFrameworkVersion [-ComputerName] <String[]> [-NoDisplay] [<CommonParameters>]
```

## DESCRIPTION
Get the .NET Framework version of lab VMs

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LabVMDotNetFrameworkVersion -ComputerName SQL01
```

List the installed .NET versions on SQL01

## PARAMETERS

### -ComputerName
The hosts to get the info from

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoDisplay
Indicates that no console output should be visible

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
