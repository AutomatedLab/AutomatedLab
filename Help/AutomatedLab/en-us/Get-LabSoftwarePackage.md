---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Get-LabSoftwarePackage

## SYNOPSIS
Get a software package

## SYNTAX

```
Get-LabSoftwarePackage [-Path] <String> [[-CommandLine] <String>] [[-Timeout] <Int32>] [<CommonParameters>]
```

## DESCRIPTION
Gets a Software Package object to be used in AutomatedLab.
The function takes in a scriptblock meant as a custom progress checking script which is currently not implemented.

## EXAMPLES

### Example 1
```powershell
$packs = @()
$packs += Get-LabSoftwarePackage -Path $labSources\SoftwarePackages\Notepad++.exe -CommandLine /S
$packs += Get-LabSoftwarePackage -Path $labSources\SoftwarePackages\winrar.exe -CommandLine /S

Install-LabSoftwarePackages -Machine (Get-LabVM -All) -SoftwarePackage $packs
```

Prepare a list of packages to install on all machines, utilizing the built-in variable labSources

## PARAMETERS

### -Path
The full file path to the software package to execute

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

### -CommandLine
The command line for the software package

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

### -Timeout
A timeout in minutes for the package installation

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
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
