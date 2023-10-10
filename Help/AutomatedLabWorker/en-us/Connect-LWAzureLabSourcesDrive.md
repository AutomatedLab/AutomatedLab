---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version: https://automatedlab.org/en/latest/AutomatedLabWorker/en-us/Connect-LWAzureLabSourcesDrive
schema: 2.0.0
---

# Connect-LWAzureLabSourcesDrive

## SYNOPSIS
Connect the Azure File Share 'LabSources' in a session

## SYNTAX

```
Connect-LWAzureLabSourcesDrive [-Session] <PSSession> [-SuppressErrors] [<CommonParameters>]
```

## DESCRIPTION
Connect the Azure File Share 'LabSources' in a session so that file copies and installations are possible using $LabSources

## EXAMPLES

### Example 1
```powershell
PS C:\> Connect-LWAzureLabSourcesDrive -Session (Get-LabPSSession DC01)
```

Mount the Azure file share inside DC01

## PARAMETERS

### -Session
The session to mount the drive in

```yaml
Type: PSSession
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SuppressErrors
Do not show errors.

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

### None
## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS

