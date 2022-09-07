---
external help file: AutomatedLabTest-help.xml
Module Name: AutomatedLabTest
online version: https://automatedlab.org/en/latest/AutomatedLabTest/en-us/Invoke-LabPester
schema: 2.0.0
---

# Invoke-LabPester

## SYNOPSIS
Invoke all role-specific pester tests for a lab

## SYNTAX

### ByLab (Default)
```
Invoke-LabPester -Lab <Lab> [-Show <Object>] [-PassThru] [-OutputFile <String>] [<CommonParameters>]
```

### ByName
```
Invoke-LabPester -LabName <String> [-Show <Object>] [-PassThru] [-OutputFile <String>] [<CommonParameters>]
```

## DESCRIPTION
Invoke all role-specific pester tests for a lab

## EXAMPLES

### Example 1
```powershell
PS C:\> Invoke-LabPester -LabName MyLab -Show Detailed
```

Give detailed feedback for all roles deployed in MyLab

## PARAMETERS

### -Lab
Lab data

```yaml
Type: Lab
Parameter Sets: ByLab
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -LabName
Name of lab

```yaml
Type: String
Parameter Sets: ByName
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -OutputFile
Result file for CI

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
Indicates that results should be returned

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

### -Show
Level of verbosity

```yaml
Type: Object
Parameter Sets: (All)
Aliases:
Accepted values: None, Normal, Detailed, Diagnostic

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### AutomatedLab.Lab
### System.String
## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS

