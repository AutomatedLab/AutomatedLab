---
external help file: AutomatedLabUnattended-help.xml
Module Name: AutomatedLabUnattended
online version: https://automatedlab.org/en/latest/AutomatedLabUnattended/en-us/Import-UnattendedFile
schema: 2.0.0
---

# Import-UnattendedFile

## SYNOPSIS
Import a lab unattended file

## SYNTAX

```
Import-UnattendedFile [-Path] <String> [<CommonParameters>]
```

## DESCRIPTION
Import a lab unattended file

## EXAMPLES

### Example 1
```powershell
PS C:\> Import-UnattendedFile -Path ks.cfg
```

Import an unattended file, here: A Kickstart configuration

## PARAMETERS

### -Path
The path to your unattend.xml, Kickstart, CloudInit or YAST config

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

