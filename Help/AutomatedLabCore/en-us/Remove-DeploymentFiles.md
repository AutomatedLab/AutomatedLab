---
external help file: AutomatedLabCore-help.xml
Module Name: AutomatedLabCore
online version:
schema: 2.0.0
---

# Remove-LabDeploymentFiles

## SYNOPSIS
Remove deployment data

## SYNTAX

```
Remove-LabDeploymentFiles [<CommonParameters>]
```

## DESCRIPTION
Removes the following files and folders used to deploy the machines from all running lab machines:
C:\unattend.xml
C:\WSManRegKey.reg
C:\DeployDebug
C:\AdditionalDisksOnline.ps1

## EXAMPLES

### Example 1
```powershell
PS C:\> Remove-LabDeploymentFiles
```

Removes the following files and folders used to deploy the machines from all running lab machines:
C:\unattend.xml
C:\WSManRegKey.reg
C:\DeployDebug
C:\AdditionalDisksOnline.ps1

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
