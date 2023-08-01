function Uninstall-LWAzureWindowsFeature
{
    [cmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [AutomatedLab.Machine[]]$Machine,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$FeatureName,

        [switch]$IncludeManagementTools,

        [switch]$UseLocalCredential,

        [switch]$AsJob,

        [switch]$PassThru
    )

    Write-LogFunctionEntry

    $activityName = "Uninstall Windows Feature(s): '$($FeatureName -join ', ')'"

    $result = @()
    foreach ($m in $Machine)
    {
        if ($m.OperatingSystem.Version -ge [System.Version]'6.2')
        {
            if ($m.OperatingSystem.Installation -eq 'Client')
            {
                $cmd = [scriptblock]::Create("Disable-WindowsOptionalFeature -Online -FeatureName $($FeatureName -join ', ') -NoRestart -WarningAction SilentlyContinue")
                $result += Invoke-LabCommand -ComputerName $m -ActivityName $activityName -NoDisplay -ScriptBlock $cmd -UseLocalCredential:$UseLocalCredential -AsJob:$AsJob -PassThru:$PassThru
            }
            else
            {
                $cmd = [scriptblock]::Create("Uninstall-WindowsFeature $($FeatureName -join ', ') -IncludeManagementTools:`$$IncludeManagementTools -WarningAction SilentlyContinue")
                $result += Invoke-LabCommand -ComputerName $m -ActivityName $activityName -NoDisplay -ScriptBlock $cmd -UseLocalCredential:$UseLocalCredential -AsJob:$AsJob -PassThru:$PassThru
            }
        }
        else
        {
            if ($m.OperatingSystem.Installation -eq 'Client')
            {
                if ($FeatureName.Count -gt 1)
                {
                    foreach ($feature in $FeatureName)
                    {
                        $cmd = [scriptblock]::Create("DISM /online /disable-feature /featurename:$($feature)")
                        $result += Invoke-LabCommand -ComputerName $m -ActivityName $activityName -NoDisplay -ScriptBlock $cmd -UseLocalCredential:$UseLocalCredential -AsJob:$AsJob -PassThru:$PassThru
                    }
                }
                else
                {
                    $cmd = [scriptblock]::Create("DISM /online /disable-feature /featurename:$($feature)")
                    $result += Invoke-LabCommand -ComputerName $m -ActivityName $activityName -NoDisplay -ScriptBlock $cmd -UseLocalCredential:$UseLocalCredential -AsJob:$AsJob -PassThru:$PassThru
                }
            }
            else
            {
                $cmd = [scriptblock]::Create("`$null;Import-Module -Name ServerManager; Remove-WindowsFeature $($FeatureName -join ', ') -WarningAction SilentlyContinue")
                $result += Invoke-LabCommand -ComputerName $m -ActivityName $activityName -NoDisplay -ScriptBlock $cmd -UseLocalCredential:$UseLocalCredential -AsJob:$AsJob -PassThru:$PassThru
            }
        }
    }

    if ($PassThru)
    {
        $result
    }

    Write-LogFunctionExit
}
