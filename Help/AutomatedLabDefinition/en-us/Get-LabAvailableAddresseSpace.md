---
external help file: AutomatedLabDefinition-help.xml
Module Name: AutomatedLabDefinition
online version: https://automatedlab.org/en/latest/AutomatedLabDefinition/en-us/Get-LabAvailableAddresseSpace
schema: 2.0.0
---

# Get-LabAvailableAddresseSpace

## SYNOPSIS
Get available address space

## SYNTAX

```
Get-LabAvailableAddresseSpace [<CommonParameters>]
```

## DESCRIPTION
Gets the available address space for the lab by examining the config setting AutomatedLab.DefaultAddressSpace (Get-PSFConfig -FullName AutomatedLab.DefaultAddressSpace) and then incrementing the network until a suitable network address space for the lab has been found.

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LabAvailableAddressSpace
```

On a fresh Hyper-V without any deployed virtual switches, should return 192.168.10.0/24, or the value of Get-PSFConfig -FullName AutomatedLab.DefaultAddressSpace

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

