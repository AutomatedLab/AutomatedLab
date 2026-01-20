function Remove-LabDeploymentFiles
{
    [CmdletBinding()]
    param ( )

    Invoke-LabCommand -ComputerName (Get-LabVM) -ActivityName 'Remove deployment files (files used during deployment)' -AsJob -NoDisplay -ScriptBlock {
        $paths = 'C:\Unattend.xml', 'C:\AdditionalDisksOnline.ps1', 'WinRmCustomization.ps1', 'WSManRegKey', $ExecutionContext.InvokeCommand.ExpandString($AL_DeployDebugFolder)
        $paths | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    } -Variable (Get-Variable -Scope Global -Name AL_DeployDebugFolder)
}
