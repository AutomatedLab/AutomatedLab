---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Get-LabVM

## SYNOPSIS
{{ Fill in the Synopsis }}

## SYNTAX

### ByName (Default)
```
Get-LabVM [[-ComputerName] <String[]>] [-IncludeLinux] [-IsRunning] [<CommonParameters>]
```

### ByRole
```
Get-LabVM -Role <Roles> [-IncludeLinux] [-IsRunning] [<CommonParameters>]
```

### All
```
Get-LabVM [-All] [-IncludeLinux] [-IsRunning] [<CommonParameters>]
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

### -All
{{ Fill All Description }}

```yaml
Type: SwitchParameter
Parameter Sets: All
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ComputerName
{{ Fill ComputerName Description }}

```yaml
Type: String[]
Parameter Sets: ByName
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -IncludeLinux
{{ Fill IncludeLinux Description }}

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

### -IsRunning
{{ Fill IsRunning Description }}

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

### -Role
{{ Fill Role Description }}

```yaml
Type: Roles
Parameter Sets: ByRole
Aliases:
Accepted values: RootDC, FirstChildDC, DC, ADDS, FileServer, WebServer, DHCP, Routing, CaRoot, CaSubordinate, SQLServer2008, SQLServer2008R2, SQLServer2012, SQLServer2014, SQLServer2016, VisualStudio2013, VisualStudio2015, SharePoint2013, SharePoint2016, Orchestrator2012, SQLServer2017, SQLServer, DSCPullServer, Office2013, Office2016, ADFS, ADFSWAP, ADFSProxy, FailoverStorage, FailoverNode, Tfs2015, Tfs2017, TfsBuildWorker, Tfs2018, HyperV, AzDevOps

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String[]

## OUTPUTS

### AutomatedLab.Machine

## NOTES

## RELATED LINKS
