---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Add-LabVMUserRight

## SYNOPSIS
{{ Fill in the Synopsis }}

## SYNTAX

```
Add-LabVMUserRight -ComputerName <String[]> [-UserName <String[]>] [-Privilege <String[]>] [<CommonParameters>]
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

### -ComputerName
{{ Fill ComputerName Description }}

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Privilege
{{ Fill Privilege Description }}

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: Priveleges
Accepted values: SeNetworkLogonRight, SeRemoteInteractiveLogonRight, SeBatchLogonRight, SeInteractiveLogonRight, SeServiceLogonRight, SeDenyNetworkLogonRight, SeDenyInteractiveLogonRight, SeDenyBatchLogonRight, SeDenyServiceLogonRight, SeDenyRemoteInteractiveLogonRight, SeTcbPrivilege, SeMachineAccountPrivilege, SeIncreaseQuotaPrivilege, SeBackupPrivilege, SeChangeNotifyPrivilege, SeSystemTimePrivilege, SeCreateTokenPrivilege, SeCreatePagefilePrivilege, SeCreateGlobalPrivilege, SeDebugPrivilege, SeEnableDelegationPrivilege, SeRemoteShutdownPrivilege, SeAuditPrivilege, SeImpersonatePrivilege, SeIncreaseBasePriorityPrivilege, SeLoadDriverPrivilege, SeLockMemoryPrivilege, SeSecurityPrivilege, SeSystemEnvironmentPrivilege, SeManageVolumePrivilege, SeProfileSingleProcessPrivilege, SeSystemProfilePrivilege, SeUndockPrivilege, SeAssignPrimaryTokenPrivilege, SeRestorePrivilege, SeShutdownPrivilege, SeSynchAgentPrivilege, SeTakeOwnershipPrivilege

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UserName
{{ Fill UserName Description }}

```yaml
Type: String[]
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

### System.String[]

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
