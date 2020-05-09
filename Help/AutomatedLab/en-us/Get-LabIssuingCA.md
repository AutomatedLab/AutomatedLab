---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Get-LabIssuingCA

## SYNOPSIS
Get the issuing CA

## SYNTAX

```
Get-LabIssuingCA [[-DomainName] <String>] [<CommonParameters>]
```

## DESCRIPTION
Gets the issuing certificate authority for the current lab and if specified the selected domain FQDN

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LabIssuingCA -DomainName contoso.com
```

Return the issuing CA for contoso

## PARAMETERS

### -DomainName
The domain name the issuing CA should be retrieved from

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### AutomatedLab.Machine
## NOTES

## RELATED LINKS
