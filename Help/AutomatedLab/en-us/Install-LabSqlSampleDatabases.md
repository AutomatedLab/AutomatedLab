---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Install-LabSqlSampleDatabases

## SYNOPSIS
Install sample databases for the selected SQL version

## SYNTAX

```
Install-LabSqlSampleDatabases [-Machine] <Machine> [<CommonParameters>]
```

## DESCRIPTION
Install sample databases for the selected SQL version. Attempts to download the fitting
version from either CodePlex (up to SQL 2012) or GitHub (2014+)

Downloads will be stored in $LabSources\SoftwarePackages\SqlSampleDbs and not downloaded a second time.

## EXAMPLES

### Example 1
```powershell
PS C:\> Install-LabSqlSampleDatabases -Machine SQL01
```

Install the Northwind Trades DB for some old edition of SQL Server

## PARAMETERS

### -Machine
The machine to deploy the sample databases to

```yaml
Type: Machine
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
