---
external help file: PSLog-help.xml
Module Name: PSLog
online version:
schema: 2.0.0
---

# Start-Log

## SYNOPSIS
{{ Fill in the Synopsis }}

## SYNTAX

### UserDefined
```
Start-Log [-LogPath] <DirectoryInfo> [-LogName] <String> [-Level] <SourceLevels> [-Silent] [<CommonParameters>]
```

### UseDefaults
```
Start-Log [-Silent] [-UseDefaults] [<CommonParameters>]
```

## DESCRIPTION
{{ Fill in the Description }}

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -Level
{{ Fill Level Description }}

```yaml
Type: SourceLevels
Parameter Sets: UserDefined
Aliases:
Accepted values: Off, Critical, Error, Warning, Information, Verbose, ActivityTracing, All

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogName
{{ Fill LogName Description }}

```yaml
Type: String
Parameter Sets: UserDefined
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogPath
{{ Fill LogPath Description }}

```yaml
Type: DirectoryInfo
Parameter Sets: UserDefined
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Silent
{{ Fill Silent Description }}

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

### -UseDefaults
{{ Fill UseDefaults Description }}

```yaml
Type: SwitchParameter
Parameter Sets: UseDefaults
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

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
