---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version: https://automatedlab.org/en/latest/AutomatedLabWorker/en-us/New-LWHypervVmConnectSettingsFile
schema: 2.0.0
---

# New-LWHypervVmConnectSettingsFile

## SYNOPSIS

Creates a VMConnect config file for the given Hyper-V machine.

## SYNTAX

```
New-LWHypervVmConnectSettingsFile [[-AudioCaptureRedirectionMode] <bool>] [[-EnablePrinterRedirection] <bool>]
 [[-FullScreen] <bool>] [[-SmartCardsRedirection] <bool>] [[-RedirectedPnpDevices] <string>] 
 [[-ClipboardRedirection] <string>] [[-DesktopSize] <string>] [[-VmServerName] <string>] [[-RedirectedUsbDevices] <string>]  [[-SavedConfigExists] <bool>] [[-UseAllMonitors] <bool>] [[-AudioPlaybackRedirectionMode] <string>] [[-PrinterRedirection] <bool>]  [[-RedirectedDrives] <string>] [-VmName] <string> [[-SaveButtonChecked] <bool>] [<CommonParameters>]
```

## DESCRIPTION

Creates a VMConnect config file for the given Hyper-V machine.

## EXAMPLES

### Example 1
```powershell
PS C:\> New-LWHypervVmConnectSettingsFile -VmName Server1
```

Creates a VMConnect default config.

## PARAMETERS

### -AudioCaptureRedirectionMode

Specifies whether the default audio input device is redirected from the client to the remote session.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AudioPlaybackRedirectionMode

No description available.

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

### -ClipboardRedirection

Specifies whether the clipboard is redirected from the client to the remote session.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DesktopSize

Sets the size of the desktop in the remote session. The format of the string should be like '1366, 768'.

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

### -EnablePrinterRedirection

Specifies whether the printer redirection is enabled from the client to the remote session.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FullScreen

Indicates if the remote session should be in full screen.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PrinterRedirection

Specifies whether the printer redirection is enabled from the client to the remote session.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RedirectedDrives

Specifies which drives to be redirection to the remote session.

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

### -RedirectedPnpDevices

Specifies which PnP devices to be redirection to the remote session.

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

### -RedirectedUsbDevices

Specifies which USB devices to be redirection to the remote session.

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

### -SaveButtonChecked

This parameter should not be used.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SavedConfigExists

This parameter should not be used.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SmartCardsRedirection

Specifies wether smart cards are redirection to the remote session.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseAllMonitors

Defines if all monitors should be used for the remote session.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -VmName

Specifies the Hyper-V virtual machine to create the config file for.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -VmServerName

Specifies the Hyper-V host server on which the virtual machine is running on.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: $env:COMPUTERNAME
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
