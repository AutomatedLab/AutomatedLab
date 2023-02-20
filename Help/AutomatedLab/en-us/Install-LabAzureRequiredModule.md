---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version: https://automatedlab.org/en/latest/AutomatedLab/en-us/Install-LabAzureRequiredModule
schema: 2.0.0
---

# Install-LabAzureRequiredModule

## SYNOPSIS
Install required Azure modules for AutomatedLab

## SYNTAX

```
Install-LabAzureRequiredModule [[-Repository] <String>] [[-Scope] <String>] [-AzureStack] [<CommonParameters>]
```

## DESCRIPTION
Install required Azure modules for AutomatedLab.
Check versions using Get-LabConfigurationItem -Name RequiredAzModules or
Get-LabConfigurationItem -Name RequiredAzStackModules if you use Azure Stack.

## EXAMPLES

### Example 1
```powershell
PS C:\> Install-LabAzureRequiredModule
```

Download and install required Az modules from PSGallery

## PARAMETERS

### -AzureStack
Indicates that the endpoint is running Azure Stack Hub with its considerably older API versions.

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

### -Repository
The gallery to use

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

### -Scope
The scope to use, default PS5.1 AllUsers, PS6+ CurrentUser

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: CurrentUser, AllUsers

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

