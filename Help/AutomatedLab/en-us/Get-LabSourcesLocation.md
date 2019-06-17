---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Get-LabSourcesLocation

## SYNOPSIS
Get lab source location

## SYNTAX

```
Get-LabSourcesLocation [-Local]
```

## DESCRIPTION
Gets the lab sources location by either returning it directly if defined or by scanning all local disks for a folder called LabSources

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LabSourcesLocation -Local
```

Returns the local lab sources, e.g. D:\LabSources

## PARAMETERS

### -Local
Indicates that the local lab sources should be used instead of automatically determining the location

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

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
