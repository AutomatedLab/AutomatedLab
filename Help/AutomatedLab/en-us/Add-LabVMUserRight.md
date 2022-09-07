---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version: https://automatedlab.org/en/latest/AutomatedLab/en-us/Add-LabVMUserRight
schema: 2.0.0
---

# Add-LabVMUserRight

## SYNOPSIS
Adds user rights on lab machines

## SYNTAX

```
Add-LabVMUserRight -ComputerName <String[]> [-UserName <String[]>] [-Privilege <String[]>] [<CommonParameters>]
```

## DESCRIPTION
Adds user rights on a lab machine from the following rights: 'SeNetworkLogonRight',                  'SeRemoteInteractiveLogonRight',                  'SeBatchLogonRight',                  'SeInteractiveLogonRight',                  'SeServiceLogonRight',                  'SeDenyNetworkLogonRight',                  'SeDenyInteractiveLogonRight',                  'SeDenyBatchLogonRight',                  'SeDenyServiceLogonRight',                  'SeDenyRemoteInteractiveLogonRight',                  'SeTcbPrivilege',                  'SeMachineAccountPrivilege',                  'SeIncreaseQuotaPrivilege',                  'SeBackupPrivilege',                  'SeChangeNotifyPrivilege',                  'SeSystemTimePrivilege',                  'SeCreateTokenPrivilege',                  'SeCreatePagefilePrivilege',                  'SeCreateGlobalPrivilege',                  'SeDebugPrivilege',                  'SeEnableDelegationPrivilege',                  'SeRemoteShutdownPrivilege',                  'SeAuditPrivilege',                  'SeImpersonatePrivilege',                  'SeIncreaseBasePriorityPrivilege',                  'SeLoadDriverPrivilege',                  'SeLockMemoryPrivilege',                  'SeSecurityPrivilege',                  'SeSystemEnvironmentPrivilege',                  'SeManageVolumePrivilege',                  'SeProfileSingleProcessPrivilege',                  'SeSystemProfilePrivilege',                  'SeUndockPrivilege',                  'SeAssignPrimaryTokenPrivilege',                  'SeRestorePrivilege',                  'SeShutdownPrivilege',                  'SeSynchAgentPrivilege',                  'SeTakeOwnershipPrivilege'

## EXAMPLES

### Example 1
```powershell
Add-LabVMUserRight -UserName 'domain\myServiceUser' -ComputerName FS1 -Priveleges SeInteractiveLogonRight,SeServiceLogonRight
```

Assigns SeInteractiveLogonRight,SeServiceLogonRight to domain\myServiceUser on FS1

## PARAMETERS

### -ComputerName
The computer name the rights are being granted on

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
A list of privileges to assign, e.g.
SEDebug

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
The user name to be granted rights

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

## OUTPUTS

## NOTES

## RELATED LINKS

