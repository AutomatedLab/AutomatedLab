---
external help file: PSFileTransfer-help.xml
Module Name: PSFileTransfer
online version:
schema: 2.0.0
---

# Copy-LabFileItem

## SYNOPSIS
Copy files to lab machines

## SYNTAX

```
Copy-LabFileItem [-Path] <String[]> [-ComputerName] <String[]> [[-DestinationFolderPath] <String>] [-Recurse]
 [[-FallbackToPSSession] <Boolean>] [[-UseAzureLabSourcesOnAzureVm] <Boolean>] [-PassThru] [<CommonParameters>]
```

## DESCRIPTION
Copy one or more paths to one or more lab machines. Optionally able to copy from the Azure lab sources
for an Azure lab instead of sending local data to Azure machines.

## EXAMPLES

### Example 1
```powershell
PS C:\> Copy-LabFileItem -Path $Labsources\Tools\git.exe -ComputerName (Get-LabVm) -DestinationFolderPath C:\Windows
```

Copies git.exe to the C:\Windows folder on all lab machines.

## PARAMETERS

### -ComputerName
The name of the lab machine to copy to

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DestinationFolderPath
The destination folder path where the data should be copied to

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

### -FallbackToPSSession
Indicates that the fallback to a PSSession should be used if SMB is not possible

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
Indicates that the copied objects will be returned

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

### -Path
The paths to copy

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Recurse
Indicates that the content should be copied recursively

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

### -UseAzureLabSourcesOnAzureVm
Indicates that the Azure File Share for lab sources should be used in case
the path is part of $labsources

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
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
