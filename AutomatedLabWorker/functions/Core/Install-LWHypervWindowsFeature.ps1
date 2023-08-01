function Install-LWHypervWindowsFeature
{
    [cmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [AutomatedLab.Machine[]]$Machine,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$FeatureName,

        [switch]$IncludeAllSubFeature,

        [switch]$IncludeManagementTools,

        [switch]$UseLocalCredential,

        [switch]$AsJob,

        [switch]$PassThru
    )

    Write-LogFunctionEntry

    $activityName = "Install Windows Feature(s): '$($FeatureName -join ', ')'"

    $result = @()
    foreach ($m in $Machine)
    {
        if ($m.OperatingSystem.Version -ge [System.Version]'6.2')
        {
            if ($m.OperatingSystem.Installation -eq 'Client')
            {
                $cmd = [scriptblock]::Create("Enable-WindowsOptionalFeature -Online -FeatureName $($FeatureName -join ', ') -Source ""`$(@(Get-WmiObject -Class Win32_CDRomDrive)[-1].Drive)\sources\sxs"" -All:`$$IncludeAllSubFeature -NoRestart -WarningAction SilentlyContinue")
                $result += Invoke-LabCommand -ComputerName $m -ActivityName $activityName -NoDisplay -ScriptBlock $cmd -UseLocalCredential:$UseLocalCredential -AsJob:$AsJob -PassThru:$PassThru
            }
            else
            {
                $cmd = [scriptblock]::Create("Install-WindowsFeature $($FeatureName -join ', ') -Source ""`$(@(Get-WmiObject -Class Win32_CDRomDrive)[-1].Drive)\sources\sxs"" -IncludeAllSubFeature:`$$IncludeAllSubFeature -IncludeManagementTools:`$$IncludeManagementTools -WarningAction SilentlyContinue")
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
                        $cmd = [scriptblock]::Create("DISM /online /enable-feature /featurename:$($feature)")
                        $result += Invoke-LabCommand -ComputerName $m -ActivityName $activityName -NoDisplay -ScriptBlock $cmd -UseLocalCredential:$UseLocalCredential -AsJob:$AsJob -PassThru:$PassThru
                    }
                }
                else
                {
                    $cmd = [scriptblock]::Create("DISM /online /enable-feature /featurename:$($feature)")
                    $result += Invoke-LabCommand -ComputerName $m -ActivityName $activityName -NoDisplay -ScriptBlock $cmd -UseLocalCredential:$UseLocalCredential -AsJob:$AsJob -PassThru:$PassThru
                }
            }
            else
            {
                $cmd = [scriptblock]::Create("`$null;Import-Module -Name ServerManager; Add-WindowsFeature $($FeatureName -join ', ') -IncludeAllSubFeature:`$$IncludeAllSubFeature -WarningAction SilentlyContinue")
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
