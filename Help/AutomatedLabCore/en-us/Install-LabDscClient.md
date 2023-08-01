---
external help file: AutomatedLabCore-help.xml
Module Name: AutomatedLabCore
online version: https://automatedlab.org/en/latest/AutomatedLabCore/en-us/Install-LabDscClient
schema: 2.0.0
---

# Install-LabDscClient

## SYNOPSIS
Configure DSC clients

## SYNTAX

### ByName (Default)
```
Install-LabDscClient -ComputerName <String[]> [-PullServer <String[]>] [<CommonParameters>]
```

### All
```
Install-LabDscClient [-All] [-PullServer <String[]>] [<CommonParameters>]
```

## DESCRIPTION
Configures all lab machines' LCM to work with the lab's DSC pull server

## EXAMPLES

### Example 1
```powershell
PS C:\> Install-LabDscClient -All
```

Configures all lab machines' LCM to work with the lab's DSC pull server, except for 'DC', 'RootDC', 'FirstChildDC', 'DSCPullServer'

## PARAMETERS

### -All
Indicates if all lab machines should be selected except for 'DC', 'RootDC', 'FirstChildDC', 'DSCPullServer'

```yaml
Type: SwitchParameter
Parameter Sets: All
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ComputerName
The computer names

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

### -PullServer
The pull server names

```yaml
Type: String[]
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

