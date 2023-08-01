---
external help file: AutomatedLabCore-help.xml
Module Name: AutomatedLabCore
online version: https://automatedlab.org/en/latest/AutomatedLabCore/en-us/Clear-Lab
schema: 2.0.0
---

# Clear-Lab

## SYNOPSIS
Clear lab data

## SYNTAX

```
Clear-Lab [<CommonParameters>]
```

## DESCRIPTION
Clears the variable $script:data to effectively clear the lab definition

## EXAMPLES

### Example 1
```powershell
PS C:\> Clear-Lab
```

Clear current lab, so that Get-Lab and Get-LabDefinition will not return

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

