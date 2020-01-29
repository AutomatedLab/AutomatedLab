---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Import-Lab

## SYNOPSIS

Import a lab

## SYNTAX

### ByName (Default)
```
Import-Lab [-Name] <String> [-PassThru] [-NoValidation] [-NoDisplay] [<CommonParameters>]
```

### ByPath
```
Import-Lab -Path <String> [-PassThru] [-NoValidation] [-NoDisplay] [<CommonParameters>]
```

### ByValue
```
Import-Lab [-LabBytes] <Byte[]> [-PassThru] [-NoValidation] [-NoDisplay] [<CommonParameters>]
```

## DESCRIPTION
Imports an installed lab environment

## EXAMPLES

### Example 1


```powershell
Import-Lab -Name MyLab -NoValidation
```

Import the lab "MyLab" from XML, skipping the validation

## PARAMETERS

### -Path
The parent path of your exported lab XML files

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

### -PassThru
Return the imported lab

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

### -NoValidation
Skip all validation steps

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

### -Name
Which lab should be imported from ProgramData\AutomatedLab\Labs

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

### -LabBytes
The raw byte content of a lab to import.

```yaml
Type: Byte[]
Parameter Sets: ByValue
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
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
aa

## RELATED LINKS
