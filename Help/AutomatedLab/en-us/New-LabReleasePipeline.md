---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# New-LabReleasePipeline

## SYNOPSIS
{{ Fill in the Synopsis }}

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
{{ Fill in the Description }}

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -BuildSteps
{{ Fill BuildSteps Description }}

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
{{ Fill CodeUploadMethod Description }}

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
{{ Fill ComputerName Description }}

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
{{ Fill ProjectName Description }}

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
{{ Fill ReleaseSteps Description }}

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
{{ Fill SourcePath Description }}

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
{{ Fill SourceRepository Description }}

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
