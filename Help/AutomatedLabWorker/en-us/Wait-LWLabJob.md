---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# Wait-LWLabJob

## SYNOPSIS
Wait for a job

## SYNTAX

### ByJob
```
Wait-LWLabJob -Job <Job[]> [-ProgressIndicator <Int32>] [-Timeout <Int32>] [-NoNewLine] [-NoDisplay]
 [-PassThru] [<CommonParameters>]
```

### ByName
```
Wait-LWLabJob -Name <String[]> [-ProgressIndicator <Int32>] [-Timeout <Int32>] [-NoNewLine] [-NoDisplay]
 [-PassThru] [<CommonParameters>]
```

## DESCRIPTION
Wait for one or more jobs to finish, with the added ability of writing a progress indicator. By default
returns nothing and just blocks execution.

## EXAMPLES

### Example 1
```powershell
PS C:\> Wait-LWLabJob -Job (Uninstall-LWHypervWindowsFeature (Get-LabVm) -AsJob)
```

Wait for the removal jobs to finish

## PARAMETERS

### -Job
The job objects to wait for

```yaml
Type: Job[]
Parameter Sets: ByJob
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
The job names to wait for

```yaml
Type: String[]
Parameter Sets: ByName
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoDisplay
Indicates that no console messages should be displayed

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

### -NoNewLine
Indicates that no line break should be emitted after the console output

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

### -PassThru
Indicates that the job objects will be returned

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

### -ProgressIndicator
Interval in seconds that a . should be written to the console

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Timeout
Timeout in seconds to wait for a job to finish

```yaml
Type: Int32
Parameter Sets: (All)
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
