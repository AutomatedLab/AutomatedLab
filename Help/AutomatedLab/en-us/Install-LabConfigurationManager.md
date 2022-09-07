---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version: https://automatedlab.org/en/latest/AutomatedLab/en-us/Install-LabConfigurationManager
schema: 2.0.0
---

# Install-LabConfigurationManager

## SYNOPSIS
Install Configuration Manager environment

## SYNTAX

```
Install-LabConfigurationManager [<CommonParameters>]
```

## DESCRIPTION
Install Configuration Manager environment. Customize by
configuration the role, using the following parameters:

Version
Branch
Roles
SiteName
SiteCode
SqlServerName
DatabaseName 
WsusContentPath 
AdminUser 

## EXAMPLES

### Example 1
```powershell
PS C:\> Install-LabConfigurationManager
```

Install all VMs with role ConfigurationManager

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS

