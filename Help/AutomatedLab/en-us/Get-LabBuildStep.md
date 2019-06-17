---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Get-LabBuildStep

## SYNOPSIS
Get a list of possible build steps for a TFS/Azure DevOps build pipeline

## SYNTAX

```
Get-LabBuildStep [[-ComputerName] <String>]
```

## DESCRIPTION
Get a list of possible build steps for a TFS/Azure DevOps build pipeline

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LabBuildStep
```

Searches for the lab's Azure DevOps server and lists all possible steps
for a new build pipeline definition, e.g. Copy File, Run Script

## PARAMETERS

### -ComputerName
The name of the CI/CD server

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

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
