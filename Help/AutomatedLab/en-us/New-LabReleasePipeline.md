---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# New-LabReleasePipeline

## SYNOPSIS
Create a new release pipeline

## SYNTAX

### CloneRepo (Default)
```
New-LabReleasePipeline [-ProjectName <String>] -SourceRepository <String> [-CodeUploadMethod <String>]
 [-ComputerName <String>] [-BuildSteps <Hashtable[]>] [-ReleaseSteps <Hashtable[]>] [<CommonParameters>]
```

### LocalSource
```
New-LabReleasePipeline [-ProjectName <String>] [-SourceRepository <String>] -SourcePath <String>
 [-CodeUploadMethod <String>] [-ComputerName <String>] [-BuildSteps <Hashtable[]>]
 [-ReleaseSteps <Hashtable[]>] [<CommonParameters>]
```

## DESCRIPTION
Create a new release pipeline from an existing git repository

## EXAMPLES

### Example 1
```powershell
PS C:\> New-LabReleasePipeline -ProjectName DscWorkshop -SourceRepository https://github.com/automatedlab/dscworkshop -CodeUpload git
```

Create a build and release pipeline without any build and release steps from the git repository dscworkshop.

## PARAMETERS

### -BuildSteps
A collection of build steps. See Get-LabBuildStep

```yaml
Type: Hashtable[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CodeUploadMethod
FileCopy for a local repo, Git for an online repo

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: Git, FileCopy

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ComputerName
The CI/CD server. Defaults to the most recent version

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

### -ProjectName
Name of the new team project. Default AutomatedLab

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

### -ReleaseSteps
Collection of release steps. See Get-LabReleaseStep

```yaml
Type: Hashtable[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SourcePath
The local repository path

```yaml
Type: String
Parameter Sets: LocalSource
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SourceRepository
The remote repository URL

```yaml
Type: String
Parameter Sets: CloneRepo
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: LocalSource
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
