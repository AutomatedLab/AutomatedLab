---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Set-LabInstallationCredential

## SYNOPSIS
Set the installation credential

## SYNTAX

### All (Default)
```
Set-LabInstallationCredential -Username <String> -Password <String> [<CommonParameters>]
```

### Prompt
```
Set-LabInstallationCredential [-Username <String>] [-Password <String>] [-Prompt] [<CommonParameters>]
```

## DESCRIPTION
Sets the installation credential for all lab machines

## EXAMPLES

### Example 1
```powershell
PS C:\> Set-LabInstallationCredential -Username Install -Password 'Somepass1!'
```

Sets the default installation credential

## PARAMETERS

### -Username
The installation user name

```yaml
Type: String
Parameter Sets: All
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: Prompt
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Password
The installation user's password

```yaml
Type: String
Parameter Sets: All
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: Prompt
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Prompt
Indicates that a prompt should be displayed for the username and password

```yaml
Type: SwitchParameter
Parameter Sets: Prompt
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
