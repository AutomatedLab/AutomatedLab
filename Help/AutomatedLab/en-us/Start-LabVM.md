---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Start-LabVM

## SYNOPSIS
{{ Fill in the Synopsis }}

## SYNTAX

### ByName (Default)
```
Start-LabVM [[-ComputerName] <String[]>] [-Wait] [-DoNotUseCredSsp] [-NoNewline]
 [-DelayBetweenComputers <Int32>] [-TimeoutInMinutes <Int32>] [-StartNextMachines <Int32>]
 [-StartNextDomainControllers <Int32>] [-Domain <String>] [-RootDomainMachines] [-ProgressIndicator <Int32>]
 [-PreDelaySeconds <Int32>] [-PostDelaySeconds <Int32>] [<CommonParameters>]
```

### ByRole
```
Start-LabVM -RoleName <Roles> [-Wait] [-DoNotUseCredSsp] [-NoNewline] [-DelayBetweenComputers <Int32>]
 [-TimeoutInMinutes <Int32>] [-StartNextMachines <Int32>] [-StartNextDomainControllers <Int32>]
 [-Domain <String>] [-RootDomainMachines] [-ProgressIndicator <Int32>] [-PreDelaySeconds <Int32>]
 [-PostDelaySeconds <Int32>] [<CommonParameters>]
```

### All
```
Start-LabVM [-All] [-Wait] [-DoNotUseCredSsp] [-NoNewline] [-DelayBetweenComputers <Int32>]
 [-TimeoutInMinutes <Int32>] [-StartNextMachines <Int32>] [-StartNextDomainControllers <Int32>]
 [-Domain <String>] [-RootDomainMachines] [-ProgressIndicator <Int32>] [-PreDelaySeconds <Int32>]
 [-PostDelaySeconds <Int32>] [<CommonParameters>]
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

Required: False
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
Accept pipeline input: False
Accept wildcard characters: False
```

### -DelayBetweenComputers
{{ Fill DelayBetweenComputers Description }}

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

### -DoNotUseCredSsp
{{ Fill DoNotUseCredSsp Description }}

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

### -Domain
{{ Fill Domain Description }}

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

### -NoNewline
{{ Fill NoNewline Description }}

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

### -PostDelaySeconds
{{ Fill PostDelaySeconds Description }}

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

### -PreDelaySeconds
{{ Fill PreDelaySeconds Description }}

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

### -ProgressIndicator
{{ Fill ProgressIndicator Description }}

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

### -RoleName
{{ Fill RoleName Description }}

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

### -RootDomainMachines
{{ Fill RootDomainMachines Description }}

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

### -StartNextDomainControllers
{{ Fill StartNextDomainControllers Description }}

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

### -StartNextMachines
{{ Fill StartNextMachines Description }}

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

### -TimeoutInMinutes
{{ Fill TimeoutInMinutes Description }}

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

### -Wait
{{ Fill Wait Description }}

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
