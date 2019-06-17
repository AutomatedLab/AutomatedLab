---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Unblock-LabSources

## SYNOPSIS
Unblock lab sources

## SYNTAX

```
Unblock-LabSources [[-Path] <String>]
```

## DESCRIPTION
Unblocks all lab sources in order to be able to properly execute all scripts and downloaded files

## EXAMPLES

### Example 1
```powershell
PS C:\> Unblock-LabSources
```

Strips the Zone Identifier from all files inside $LabSources

## PARAMETERS

### -Path
Unblock the lab sources directory

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

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
