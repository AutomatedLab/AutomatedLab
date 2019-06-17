---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Get-LabAvailableOperatingSystem

## SYNOPSIS
Show available lab OS

## SYNTAX

### Local (Default)
```
Get-LabAvailableOperatingSystem [[-Path] <String[]>] [-UseOnlyCache] [-NoDisplay] [<CommonParameters>]
```

### Azure
```
Get-LabAvailableOperatingSystem [-UseOnlyCache] [-NoDisplay] [-Azure] -Location <Object> [<CommonParameters>]
```

## DESCRIPTION
Shows all available operating systems that are available for an imported or newly created lab.
Available after either calling New-LabDefinition or Import-Lab or by specifying a path to the ISO folder

## EXAMPLES

### Example 1


```powershell
Get-LabAvailableOperatingSystem -Path D:\LabSources\ISOs
```

List all available OS in the lab sources directory

OperatingSystemName                         Idx Version        PublishedDate       IsoPath                             
-------------------                         --- -------        -------------       -------                             
Windows Server 2012 R2 Standard (Server Core Installation)   1   6.3.9600.17415 21.11.2014 15:34:09 D:\LabSources\ISOs\en_windows_ser...
Windows Server 2012 R2 Standard (Server with a GUI)       2   6.3.9600.17415 21.11.2014 15:45:29 D:\LabSources\ISOs\en_windows_ser...
Windows Server 2012 R2 Datacenter (Server Core Installation) 3   6.3.9600.17415 21.11.2014 15:54:25 D:\LabSources\ISOs\en_windows_ser...
Windows Server 2012 R2 Datacenter (Server with a GUI)     4   6.3.9600.17415 21.11.2014 16:06:15 D:\LabSources\ISOs\en_windows_ser...
Windows Server 2016 Standard      1   10.0.14393.0   12.09.2016 13:04:57 D:\LabSources\ISOs\en_windows_ser...
Windows Server 2016 Standard (Desktop Experience)          2   10.0.14393.0   12.09.2016 13:09:49 D:\LabSources\ISOs\en_windows_ser...
Windows Server 2016 Datacenter    3   10.0.14393.0   12.09.2016 13:12:56 D:\LabSources\ISOs\en_windows_ser...
Windows Server 2016 Datacenter (Desktop Experience)        4   10.0.14393.0   12.09.2016 13:17:32 D:\LabSources\ISOs\en_windows_ser...
Windows Server 2012 R2 Datacenter (Server with a GUI)     1   6.3.9600.17415 21.11.2014 16:06:15 D:\LabSources\ISOs\UpdatedServer2...

## PARAMETERS

### -Path
Lab ISO folder path

```yaml
Type: String[]
Parameter Sets: Local
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Azure
Indicates that we are looking for Azure SKUs and not local ISO files

```yaml
Type: SwitchParameter
Parameter Sets: Azure
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Location
The Azure location, e.g. West Europe

```yaml
Type: Object
Parameter Sets: Azure
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoDisplay
Do not display console messages

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

### -UseOnlyCache
Indicates that only the cache should be used, which speeds up the operation significantly

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
