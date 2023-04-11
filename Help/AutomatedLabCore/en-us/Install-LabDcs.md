---
external help file: AutomatedLabCore-help.xml
Module Name: AutomatedLabCore
online version: https://automatedlab.org/en/latest/AutomatedLabCore/en-us/Install-LabDcs
schema: 2.0.0
---

# Install-LabDcs

## SYNOPSIS
Install domain controllers

## SYNTAX

```
Install-LabDcs [[-DcPromotionRestartTimeout] <Int32>] [[-AdwsReadyTimeout] <Int32>] [-CreateCheckPoints]
 [-ProgressIndicator <Int32>] [<CommonParameters>]
```

## DESCRIPTION
Installs lab domain controllers after the root and child domains have been set-up and the RootDC and FirstChildDC machines have been installed

## EXAMPLES

### Example 1
```powershell
PS C:\> Install-LabDcs
```

Installs lab domain controllers after the root and child domains have been set-up and the RootDC and FirstChildDC machines have been installed

## PARAMETERS

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
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

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

### -ProgressIndicator
After n seconds, print a .
to the console

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

