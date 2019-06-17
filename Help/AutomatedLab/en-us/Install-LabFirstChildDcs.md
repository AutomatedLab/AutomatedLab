---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Install-LabFirstChildDcs

## SYNOPSIS
Install the first child domain's domain controllers

## SYNTAX

```
Install-LabFirstChildDcs [[-DcPromotionRestartTimeout] <Int32>] [[-AdwsReadyTimeout] <Int32>]
 [-CreateCheckPoints] [-ProgressIndicator <Int32>] [<CommonParameters>]
```

## DESCRIPTION
Installs all lab machines with the role FirstChildDc after all RootDCs have been installed.
This will set-up all child domains for a given lab

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -DcPromotionRestartTimeout
The DC promo restart timeout, i.e.
how long we should wait for the restart after the DC promo to complete

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AdwsReadyTimeout
The timeout to wait for the Active Directory Web Services

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CreateCheckPoints
Indicates if checkpoints should be created after DC promo

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

### -ProgressIndicator
After n seconds, print a . to the console

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
