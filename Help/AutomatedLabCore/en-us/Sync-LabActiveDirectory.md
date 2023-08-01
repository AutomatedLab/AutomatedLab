---
external help file: AutomatedLabCore-help.xml
Module Name: AutomatedLabCore
online version: https://automatedlab.org/en/latest/AutomatedLabCore/en-us/Sync-LabActiveDirectory
schema: 2.0.0
---

# Sync-LabActiveDirectory

## SYNOPSIS
Start AD replication

## SYNTAX

```
Sync-LabActiveDirectory [-ComputerName] <String[]> [[-ProgressIndicator] <Int32>] [-AsJob] [-Passthru]
 [<CommonParameters>]
```

## DESCRIPTION
Initiates the Active Directory synchronisation in the lab environment by calling repadmin on the selected machines

## EXAMPLES

### Example 1
```powershell
PS C:\> Sync-LabActiveDirectory -ComputerName (Get-LabVm -Role ADDS)
```

Call repadmin on all domain controllers in the lab

## PARAMETERS

### -AsJob
Indicates that the cmdlet should run in the background

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

### -ComputerName
The machines repadmin should be executed on

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

### -Passthru
Indicates that the resulting job objects should be passed back to the caller

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

### -ProgressIndicator
Every n seconds, print a .
to the console

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
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

