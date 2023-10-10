---
external help file: AutomatedLabDefinition-help.xml
Module Name: AutomatedLabDefinition
online version: https://automatedlab.org/en/latest/AutomatedLabDefinition/en-us/Add-LabAzureAppServicePlanDefinition
schema: 2.0.0
---

# Add-LabAzureAppServicePlanDefinition

## SYNOPSIS

## SYNTAX

```
Add-LabAzureAppServicePlanDefinition [-Name] <String> [[-ResourceGroup] <String>] [[-Location] <String>]
 [[-Tier] <String>] [[-WorkerSize] <String>] [[-NumberofWorkers] <Int32>] [-PassThru] [<CommonParameters>]
```

## DESCRIPTION
{{ Fill in the Description }}

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -Location
{{ Fill Location Description }}

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

### -Name
{{ Fill Name Description }}

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

### -NumberofWorkers
{{ Fill NumberofWorkers Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
{{ Fill PassThru Description }}

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

### -ResourceGroup
{{ Fill ResourceGroup Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Tier
{{ Fill Tier Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: Basic, Free, Premium, Shared, Standard

Required: False
Position: 3
Default value: Free
Accept pipeline input: False
Accept wildcard characters: False
```

### -WorkerSize
{{ Fill WorkerSize Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: ExtraLarge, Large, Medium, Small

Required: False
Position: 4
Default value: Small
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### AutomatedLab.Azure.AzureRmService
## NOTES

## RELATED LINKS

