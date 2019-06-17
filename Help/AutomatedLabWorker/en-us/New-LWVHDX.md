---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# New-LWVHDX

## SYNOPSIS
Create a new virtual disk

## SYNTAX

```
New-LWVHDX [-VhdxPath] <String> [-SizeInGB] <Int32> [[-Label] <String>] [-UseLargeFRS] [[-DriveLetter] <Char>]
 [[-AllocationUnitSize] <Int64>] [-SkipInitialize] [<CommonParameters>]
```

## DESCRIPTION
Creates a new Hyper-V VHDX file. Allows you to specify if FRS is used, which drive letter to mount
the VHDX to, the allocation unit size in Byte or if the disk should not be initialized
with the NTFS file system

## EXAMPLES

### Example 1
```powershell
PS C:\> New-LWVHDX -VhdxPath D:\SQLData.vhdx -SizeInGb 350 -Label DATA -DriveLetter X -AllocationUnitSIze 64kb
```

Creates a new disk with an allocation unit size of 64kb, a size of 350GB and the label DATA.

## PARAMETERS

### -AllocationUnitSize
The allocation unit size in byte

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

### -DriveLetter
The intended drive letter

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
The file system label

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

### -SizeInGB
The disk size in GB

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SkipInitialize
Indicates that the disk will not be initialized with a file system

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

### -UseLargeFRS
Indicates that large File Record Segment should be used, which is common in deduplication scenarios

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

### -VhdxPath
The path to the VHDX file

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
