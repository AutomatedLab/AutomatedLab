---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# New-LabSourcesFolder

## SYNOPSIS
Create and populate a new labsources folder

## SYNTAX

```
New-LabSourcesFolder [[-DriveLetter] <String>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Create and populate a new labsources folder. The labsources folder contains a bunch
of useful or necessary components. When the cmdlet is executed for the first time, the
lab sources content will be pulled from the master branch of the GitHub repository AutomatedLab.

This cmdlet can be used to update sample scripts. Be aware that it will overwrite your changes to any files.

The local lab sources can optionally be synced with Azure, all Lab cmdlets are aware of that and select the
correct location for you, if you use the variable $LabSources

Folder content:
DscConfigurations - Lab DSC configurations that have been applied to machines
GitRepositories - Cloned repositories that have been pushed to your lab CI/CD release pipeline
ISOs - Essential. Should contain OS ISOs you deploy your VMs from, can optionally contain product ISOs like SQL
OSUpdates - Intended for OS updates, not automatically used
PostInstallationActivities - Used in many samples, this folder contains some tasks like setting up a DSC Pull Server or creating thousands of users.
Sample Scripts - Contains a wide range of sample scripts for you to play with
SoftwarePackages - Intended for installers and the like
Tools - Intended for little tools that e.g. get copied to each machine, if enabled

## EXAMPLES

### Example 1
```powershell
PS C:\> New-LabSourcesFolder -Drive D -Force
```

Download lab sources content to D:\LabSources and overwrite any existing files

## PARAMETERS

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DriveLetter
The drive to store LabSources on

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

### -Force
Indicates that content will be replaced

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

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

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
