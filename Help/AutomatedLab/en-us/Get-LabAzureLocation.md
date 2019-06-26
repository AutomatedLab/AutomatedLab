---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Get-LabAzureLocation

## SYNOPSIS
Get a lab location

## SYNTAX

```
Get-LabAzureLocation [[-LocationName] <String>] [-List] [<CommonParameters>]
```

## DESCRIPTION
Gets valid Azure locations by response time or name.
Can also list all available Azure locations

## EXAMPLES

### Example 1


```powershell
Get-LabAzureLocation
```

Get the fastest responding Azure location

UK South

### Example 2


```powershell
Get-LabAzureLocation -List
```

Lists all available Azure locations.
Returns 9999 if location is not reachable or not yet implemented in AL

DisplayName         Latency
-----------         -------
UK South                 67
West Europe           73,75
North Europe          94,75
UK West                95,5
East US               95,75
Canada Central        109,5
Central US            128,5
East US 2             167,5
Canada East          181,25
North Central US     197,75
West US              201,75
South Central US      205,5
Southeast Asia       214,25
East Asia            240,25
Brazil South          257,5
Japan East           296,25
Japan West           311,25
Australia East          324
Australia Southeast  332,25
West Central US        9999
West US 2              9999
Central India          9999
West India             9999
South India            9999

## PARAMETERS

### -LocationName
The location display name to return

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

### -List
Indicates whether all locations should be listed

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
