---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version: https://automatedlab.org/en/latest/AutomatedLab/en-us/Install-LabSoftwarePackages
schema: 2.0.0
---

# Install-LabSoftwarePackages

## SYNOPSIS
Install multiple packages

## SYNTAX

```
Install-LabSoftwarePackages [-Machine] <Machine[]> [-SoftwarePackage] <SoftwarePackage[]>
 [-WaitForInstallation] [-PassThru] [<CommonParameters>]
```

## DESCRIPTION
Installs one or more software packages on lab machines by calling Install-LabSoftwarePackage

## EXAMPLES

### Example 1
```powershell
$packs = @()
$packs += Get-LabSoftwarePackage -Path $labSources\SoftwarePackages\Notepad++.exe -CommandLine /S
$packs += Get-LabSoftwarePackage -Path $labSources\SoftwarePackages\winrar.exe -CommandLine /S

Install-LabSoftwarePackages -Machine (Get-LabVM -All) -SoftwarePackage $packs
```

Install a list of packages on a list of machines

## PARAMETERS

### -Machine
The target machines

```yaml
Type: Machine[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -PassThru
Indicates if the resulting jobs should be passed back to the caller

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

### -SoftwarePackage
The software packages to install

```yaml
Type: SoftwarePackage[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -WaitForInstallation
Indicates if the script should be waiting for the installation of all packages on all machines

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

