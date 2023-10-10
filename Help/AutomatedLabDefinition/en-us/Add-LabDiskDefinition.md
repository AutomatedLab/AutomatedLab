---
external help file: AutomatedLabDefinition-help.xml
Module Name: AutomatedLabDefinition
online version: https://automatedlab.org/en/latest/AutomatedLabDefinition/en-us/Add-LabDiskDefinition
schema: 2.0.0
---

# Add-LabDiskDefinition

## SYNOPSIS
Add lab disk definition

## SYNTAX

```
Add-LabDiskDefinition [-Name] <String> [-DiskSizeInGb] <Int32> [[-Label] <String>] [[-DriveLetter] <Char>]
 [-UseLargeFRS] [[-AllocationUnitSize] <Int64>] [[-PartitionStyle] <String>] [-SkipInitialize] [-PassThru]
 [<CommonParameters>]
```

## DESCRIPTION
Adds a disk definition the the current lab.
Disk definitions can be used by lab machines

## EXAMPLES

### Example 1
```powershell
PS C:\> Add-LabDiskDefinition -Name SQL_DataDrive -DiskSizeInGb 100 -Label Data -DriveLetter D -AllocationUnitSize 64kb
PS C:\> Add-LabMachineDefinition -Name SQL01 -Disk SQL_DataDrive
```

Creates a new disk definition and attaches the disk to the machine definition SQL01.

## PARAMETERS

### -AllocationUnitSize
The allocation unit size in Byte to use, e.g.
64kb

```yaml
Type: Int64
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DiskSizeInGb
The disk size in GB

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -DriveLetter
The drive letter to assign

```yaml
Type: Char
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Label
The label to assign

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
The disk name

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -PartitionStyle
MBR, GPT

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: MBR, GPT

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
Indicates that the disk object should be passed back to the caller

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

### -SkipInitialize
Indicates that the initialization of the disk with a file system should be skipped

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

### -UseLargeFRS
Indicates that large FRS should be used.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

