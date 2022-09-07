---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version: https://automatedlab.org/en/latest/AutomatedLab/en-us/New-LabCimSession
schema: 2.0.0
---

# New-LabCimSession

## SYNOPSIS
Create new lab CIM sessions

## SYNTAX

### ByName
```
New-LabCimSession [-ComputerName] <String[]> [-UseLocalCredential] [-DoNotUseCredSsp]
 [-Credential <PSCredential>] [-Retries <Int32>] [-Interval <Int32>] [-UseSSL] [<CommonParameters>]
```

### ByMachine
```
New-LabCimSession -Machine <Machine[]> [-UseLocalCredential] [-DoNotUseCredSsp] [-Credential <PSCredential>]
 [-Retries <Int32>] [-Interval <Int32>] [-UseSSL] [<CommonParameters>]
```

### BySession
```
New-LabCimSession -Session <CimSession> [-UseLocalCredential] [-DoNotUseCredSsp] [-Credential <PSCredential>]
 [-Retries <Int32>] [-Interval <Int32>] [-UseSSL] [<CommonParameters>]
```

## DESCRIPTION
Create new lab CIM sessions

## EXAMPLES

### Example 1
```powershell
PS C:\> New-LabCimSession -ComputerName Host1, Host2 -UseLocalCredential
```

Create new CIM sessions to Host1 and Host2 using a local (instead of default) credential

## PARAMETERS

### -ComputerName
The hosts to connect to via CIM

```yaml
Type: String[]
Parameter Sets: ByName
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential
An optional credential

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DoNotUseCredSsp
Indicates that CredSSP should not be used (and Negotiate instead)

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

### -Interval
Retry interval in seconds

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

### -Machine
Machine objects to connect to via CIM

```yaml
Type: Machine[]
Parameter Sets: ByMachine
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Retries
Number of retries

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

### -Session
Recreate a CIM session

```yaml
Type: CimSession
Parameter Sets: BySession
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseLocalCredential
Indicates that local user (Set-LabInstallationCredential) should be used

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

### -UseSSL
Indicates that SSL should be used, e.g.
to connect to a Linux host in the lab which uses omi-psrp

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

### None
## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS

