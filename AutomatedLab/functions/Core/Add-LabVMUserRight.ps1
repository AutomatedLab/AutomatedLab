function Add-LabVMUserRight
{
    param
    (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'ByMachine')]
        [String[]]$ComputerName,
        [string[]]$UserName,
        [validateSet('SeNetworkLogonRight',
                'SeRemoteInteractiveLogonRight',
                'SeBatchLogonRight',
                'SeInteractiveLogonRight',
                'SeServiceLogonRight',
                'SeDenyNetworkLogonRight',
                'SeDenyInteractiveLogonRight',
                'SeDenyBatchLogonRight',
                'SeDenyServiceLogonRight',
                'SeDenyRemoteInteractiveLogonRight',
                'SeTcbPrivilege',
                'SeMachineAccountPrivilege',
                'SeIncreaseQuotaPrivilege',
                'SeBackupPrivilege',
                'SeChangeNotifyPrivilege',
                'SeSystemTimePrivilege',
                'SeCreateTokenPrivilege',
                'SeCreatePagefilePrivilege',
                'SeCreateGlobalPrivilege',
                'SeDebugPrivilege',
                'SeEnableDelegationPrivilege',
                'SeRemoteShutdownPrivilege',
                'SeAuditPrivilege',
                'SeImpersonatePrivilege',
                'SeIncreaseBasePriorityPrivilege',
                'SeLoadDriverPrivilege',
                'SeLockMemoryPrivilege',
                'SeSecurityPrivilege',
                'SeSystemEnvironmentPrivilege',
                'SeManageVolumePrivilege',
                'SeProfileSingleProcessPrivilege',
                'SeSystemProfilePrivilege',
                'SeUndockPrivilege',
                'SeAssignPrimaryTokenPrivilege',
                'SeRestorePrivilege',
                'SeShutdownPrivilege',
                'SeSynchAgentPrivilege',
                'SeTakeOwnershipPrivilege'
        )]
        [Alias('Priveleges')]
        [string[]]$Privilege
    )

    $Job = @()

    foreach ($Computer in $ComputerName)
    {
        $param = @{}
        $param.add('UserName', $UserName)
        $param.add('Right', $Right)
        $param.add('ComputerName', $Computer)

        $Job += Invoke-LabCommand -ComputerName $Computer -ActivityName "Configure user rights '$($Privilege -join ', ')' for user accounts: '$($UserName -join ', ')'" -NoDisplay -AsJob -PassThru -ScriptBlock {
            Add-AccountPrivilege -UserName $UserName -Privilege $Privilege
        } -Variable (Get-Variable UserName, Privilege) -Function (Get-Command Add-AccountPrivilege)
    }
    Wait-LWLabJob -Job $Job -NoDisplay
}
