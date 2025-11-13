function Remove-LabDeploymentFiles
{

    Invoke-LabCommand -ComputerName (Get-LabVM) -ActivityName 'Remove deployment files (files used during deployment)' -AsJob -NoDisplay -ScriptBlock {
        $paths = 'C:\Unattend.xml', $ExecutionContext.InvokeCommand.ExpandString($AL_DeployDebugFolder)
        $paths | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    } -Variable (Get-Variable -Scope Global -Name AL_DeployDebugFolder)
}
