---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Install-LabSqlServers

## SYNOPSIS
Install SQL servers

## SYNTAX

```
Install-LabSqlServers [[-InstallationTimeout] <Int32>] [-CreateCheckPoints] [-ProgressIndicator <Int32>]
 [<CommonParameters>]
```

## DESCRIPTION
Installs all SQL servers in the current lab with the configured installation properties of each server.
The valid properties include:
Features
InstanceName
Collation
SQLSvcAccount     
SQLSvcPassword    
AgtSvcAccount     
AgtSvcPassword    
RsSvcAccount
AgtSvcStartupType
BrowserSvcStartupType
RsSvcStartupType
AsSysAdminAccounts
AsSvcAccount
IsSvcAccount
SQLSysAdminAccounts
SQLServer2008

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -InstallationTimeout
The timeout in minutes we should wait for the installation to finish

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CreateCheckPoints
Indicates if a checkpoint should be created after installing SQL

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
After n seconds, print a . to the console

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

## OUTPUTS

## NOTES

## RELATED LINKS
