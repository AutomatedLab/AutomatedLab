---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# New-LWReferenceVHDX

## SYNOPSIS
Create a reference disk from an OS image

## SYNTAX

```
New-LWReferenceVHDX [-IsoOsPath] <String> [-ReferenceVhdxPath] <String> [-OsName] <String>
 [-ImageName] <String> [-SizeInGB] <Int32> [-PartitionStyle] <String> [<CommonParameters>]
```

## DESCRIPTION
Create a reference disk from an OS image to speed up lab deployments.

## EXAMPLES

### Example 1
```powershell
Stop-ShellHWDetectionService

New-LWReferenceVHDX -IsoOsPath $labSources\ISOs\2019.iso `
    -ReferenceVhdxPath D:\LabVms\10.0.18362.145.vhdx `
    -OsName 'Windows Server 2019 Datacenter' `
    -ImageName 'Windows Server 2019 Datacenter' `
    -SizeInGb 350 `
    -PartitionStyle GPT
```

Initializes a new reference disk for Windows Server 2019 with a GPT layout.

## PARAMETERS

### -ImageName
The name of the OS image

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IsoOsPath
The path to the operating system ISO

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OsName
The name of the operating system

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PartitionStyle
The intendend partition style

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: MBR, GPT

Required: True
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ReferenceVhdxPath
The path where the reference should be created

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SizeInGB
The size of the disk in GB

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
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
