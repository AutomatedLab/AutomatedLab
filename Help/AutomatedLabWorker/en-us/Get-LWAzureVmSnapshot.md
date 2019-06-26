---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# Get-LWAzureVmSnapshot

## SYNOPSIS
List an Azure snapshot

## SYNTAX

```
Get-LWAzureVmSnapshot [[-ComputerName] <String[]>] [[-SnapshotName] <String>] [<CommonParameters>]
```

## DESCRIPTION
List an Azure snapshot

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LWAzureVmSnapshot -ComputerName DC01,FS01 -SnapshotName EndOfTheWorld
```

Returns details about the snapshot EndOfTheWorld for DC01 and FS01

## PARAMETERS

### -ComputerName
The host names

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: VMName

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SnapshotName
The snapshot name

```yaml
Type: String
Parameter Sets: (All)
Aliases: Name

Required: False
Position: 1
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
