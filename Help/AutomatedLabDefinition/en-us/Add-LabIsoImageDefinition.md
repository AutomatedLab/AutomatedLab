---
external help file: AutomatedLabDefinition-help.xml
Module Name: AutomatedLabDefinition
online version:
schema: 2.0.0
---

# Add-LabIsoImageDefinition

## SYNOPSIS
Adds a definition of an ISO file using a logical name and a path of the ISO file

## SYNTAX

```
Add-LabIsoImageDefinition [[-Name] <String>] [[-Path] <String>] [-IsOperatingSystem] [-NoDisplay]
 [<CommonParameters>]
```

## DESCRIPTION
When AutomatedLab is to install roles like SQL Server, Exchange, Visual Studio, Office etc, it must know where to find the ISO file for these products.
AutomatedLab does this by associating a logical name with a definition of an ISO file by path.
This way, when AutomatedLab needs an ISO file, it looks for this "mapping".

All operating system ISO files are detected automatically UNLESS the ISO files are not placed within the LabSources folder structure.
If so, you must specify manually using Add-LabIsoImageDefinition, where the ISO file is located.

## EXAMPLES

### Example 1
```powershell
Add-LabIsoImageDefinition -Path E:\ISOs\MyWin2016ServerFile.iso
```

Adds a definition of ISO file to be used when installing Server 2016.

### Example 2


```powershell
Add-LabIsoImageDefinition -Name SQLServer2014 -Path E:\ISOs\MySqlSrv2014File.iso
```

Adds a definition of ISO file to be used when installing SQL Server 2014.

## PARAMETERS

### -Name
Logical name for reference. Names are case sensitive.

In order to deploy certain roles like SQL, TFS, ... use the role name for the ISO, e.g. SQLServer2016

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Path
Path of ISO file

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IsOperatingSystem
Indicates that the ISO is an OS installation disk

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

### -NoDisplay
Indicates that no output should be visible

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

## RELATED LINKS
