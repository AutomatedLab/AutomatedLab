---
external help file: AutomatedLabTest-help.xml
Module Name: automatedlabtest
online version:
schema: 2.0.0
---

# Test-LabDeployment

## SYNOPSIS
Test a lab deployment

## SYNTAX

### Path
```
Test-LabDeployment [-Path <String[]>] [-LogDirectory <String>] [-Replace <Hashtable>] [<CommonParameters>]
```

### All
```
Test-LabDeployment [-SampleScriptsPath <String>] [-Filter <String>] [-All] [-LogDirectory <String>]
 [-Replace <Hashtable>] [<CommonParameters>]
```

## DESCRIPTION
Test a lab deployment. Optionally replace values in the scripts like image versions or Azure
resource group names.

## EXAMPLES

### Example 1
```powershell
$result = Test-LabDeployment -Path "$labSources\Sample Scripts\Workshop Labs\PowerShell Lab - Azure.ps1" -Replace @{
    '<SOME UNIQUE DATA>' = "somelab$(Get-Random)"
    "(\`$azureDefaultLocation = ')(\w| )+(')" = '$1North Europe$3'
    '(Add-LabAzureSubscription -DefaultLocationName \$azureDefaultLocation)' = '$1 -SubscriptionName AL'
}
```

Test an Azure based lab, replacing the place holders with your own subscription data

### Example 2
```powershell
$result = Test-LabDeployment -Path "$labSources\Sample Scripts\HyperV\Single 2012R2 Server.ps1"
```

Test a single script

### Example 3
```powershell
$result = Test-LabDeployment -SampleScriptsPath "$labSources\Sample Scripts\HyperV" -All
```

Test all scripts in the HyperV folder

## PARAMETERS

### -All
Test all scripts in a folder

```yaml
Type: SwitchParameter
Parameter Sets: All
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Filter
Filter scripts

```yaml
Type: String
Parameter Sets: All
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogDirectory
Log folder for test results

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Path
Path to the lab script(s)

```yaml
Type: String[]
Parameter Sets: Path
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Replace
Replace hashtable keys with hashtable values in each script

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SampleScriptsPath
Path to the sample scripts

```yaml
Type: String
Parameter Sets: All
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

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
