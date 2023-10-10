---
external help file: AutomatedLabCore-help.xml
Module Name: AutomatedLabCore
online version: https://automatedlab.org/en/latest/AutomatedLabCore/en-us/Start-LabVM
schema: 2.0.0
---

# Start-LabVM

## SYNOPSIS
Start a machine

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
Starts one or more lab machines

## EXAMPLES

### Example 1
```powershell
PS C:\> Start-LabVm -All -Wait
```

Start all VMs in a lab and wait for them to respond to WSMAN requests

## PARAMETERS

### -All
Start all machines

```yaml
Type: SwitchParameter
Parameter Sets: All
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ComputerName
The machines to start

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

### -DelayBetweenComputers
The delay in minutes between the computer startups

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

### -Domain
Starts all machines of a specific domain

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

### -DoNotUseCredSsp
Indicates that CredSSP should not be used

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

### -NoNewline
Indicates that no new lines should be present in the output

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

### -PostDelaySeconds
The post-start delay

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
The pre-start delay

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
Every n seconds, print a .
to the console

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
The roles to start. See `[enum]::GetValues([AutomatedLab.Roles])`
or <https://automatedlab.org/en/latest/Wiki/Roles/roles/> for more information.

```yaml
Type: Roles
Parameter Sets: ByRole
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RootDomainMachines
Start all machines of the root domain

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

### -StartNextDomainControllers
Start the next n domain controllers

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
Start the next n machines

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
The startup timeout in minutes

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
Indicates that we should wait for the startup procedure to finish

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

