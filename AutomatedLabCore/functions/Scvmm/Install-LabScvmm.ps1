function Install-LabScvmm
{
    [CmdletBinding()]
    param ( )

    # Prerequisites, all
    $all = Get-LabVM -Role SCVMM | Where-Object SkipDeployment -eq $false
    Invoke-LabCommand -ComputerName $all -ScriptBlock {
        New-Item -ItemType Directory -Path $ExecutionContext.InvokeCommand.ExpandString($AL_DeployDebugFolder) -ErrorAction SilentlyContinue -Force
    } -Variable (Get-Variable -Scope Global -Name AL_DeployDebugFolder)

    $server = $all | Where-Object { -not $_.Roles.Properties.ContainsKey('SkipServer') }
    $consoles = $all | Where-Object { $_.Roles.Properties.ContainsKey('SkipServer') }

    if ($consoles)
    {
        $jobs = Install-ScvmmConsole -Computer $consoles
    }

    if ($server)
    {
        Install-ScvmmServer -Computer $server
    }

    # In case console setup took longer than server...
    if ($jobs) { Wait-LWLabJob -Job $jobs }
}
