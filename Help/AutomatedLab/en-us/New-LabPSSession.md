---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# New-LabPSSession

## SYNOPSIS
Create PowerShell sessions

## SYNTAX

### ByName
```
New-LabPSSession [-ComputerName] <String[]> [-UseLocalCredential] [-DoNotUseCredSsp]
 [-Credential <PSCredential>] [-Retries <Int32>] [-Interval <Int32>] [-UseSSL] [<CommonParameters>]
```

### ByMachine
```
New-LabPSSession -Machine <Machine[]> [-UseLocalCredential] [-DoNotUseCredSsp] [-Credential <PSCredential>]
 [-Retries <Int32>] [-Interval <Int32>] [-UseSSL] [<CommonParameters>]
```

### BySession
```
New-LabPSSession -Session <PSSession> [-UseLocalCredential] [-DoNotUseCredSsp] [-Credential <PSCredential>]
 [-Retries <Int32>] [-Interval <Int32>] [-UseSSL] [<CommonParameters>]
```

## DESCRIPTION
Creates or repurposes sessions to one or more machines with the ability to use SSL

## EXAMPLES

### Example 1
```powershell
PS C:\> New-LabPSSession -ComputerName DC1, FS1 -UseLocalCredential
```

Connects up to two new sessions using a local credential

### Example 2
```powershell
PS C:\> New-LabPSSession -ComputerName CENTOS1,UBU1 -UseSsl
```

Connects up to two new sessions to Linux machines, using SSL and Basic auth

## PARAMETERS

### -ComputerName
The remote computer names

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

### -UseLocalCredential
Indicates if the machine credential should be used

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

### -Credential
The credential used to connect

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

### -Retries
The number of retries to enable a sessions

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

### -Interval
The retry interval in seconds

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

### -UseSSL
Indicates if SSL should be used to connect the sessions

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

### -Machine
The lab VMs

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

### -Session
An existing session.
Used to recreate a broken session

```yaml
Type: PSSession
Parameter Sets: BySession
Aliases:

Required: True
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
