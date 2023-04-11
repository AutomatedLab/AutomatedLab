---
external help file: AutomatedLabCore-help.xml
Module Name: AutomatedLabCore
online version: https://automatedlab.org/en/latest/AutomatedLabCore/en-us/Install-LabDscPullServer
schema: 2.0.0
---

# Install-LabDscPullServer

## SYNOPSIS
Install a DSC pull server

## SYNTAX

```
Install-LabDscPullServer [[-InstallationTimeout] <Int32>] [<CommonParameters>]
```

## DESCRIPTION
Configures the labs DSC pull servers with SSL

## EXAMPLES

### Example 1
```powershell
PS C:\> Install-LabDscPullServer
```

Configures the labs DSC pull servers with or without SSL and SQL

## PARAMETERS

### -InstallationTimeout
The timeout in minutes how long we should wait for the installation

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

