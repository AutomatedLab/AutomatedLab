function Get-LWAzureWindowsFeature
{
    [cmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [AutomatedLab.Machine[]]$Machine,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$FeatureName,

        [switch]$UseLocalCredential,

        [switch]$AsJob
    )

    Write-LogFunctionEntry

    $activityName = "Get Windows Feature(s): '$($FeatureName -join ', ')'"

    $result = @()
    foreach ($m in $Machine)
    {
        if ($m.OperatingSystem.Version -ge [System.Version]'6.2')
        {
            if ($m.OperatingSystem.Installation -eq 'Client')
            {
                if ($FeatureName.Count -gt 1)
                {
                    foreach ($feature in $FeatureName)
                    {
                        $cmd = [scriptblock]::Create("Get-WindowsOptionalFeature -Online -FeatureName $($feature) -WarningAction SilentlyContinue")
                        $result += Invoke-LabCommand -ComputerName $m -ActivityName $activityName -NoDisplay -ScriptBlock $cmd -UseLocalCredential:$UseLocalCredential -AsJob:$AsJob
                    }
                }
                else
                {
                    $cmd = [scriptblock]::Create("Get-WindowsOptionalFeature -Online -FeatureName $($FeatureName -join ', ') -WarningAction SilentlyContinue")
                    $result += Invoke-LabCommand -ComputerName $m -ActivityName $activityName -NoDisplay -ScriptBlock $cmd -UseLocalCredential:$UseLocalCredential -AsJob:$AsJob
                }
            }
            else
            {
                $cmd = [scriptblock]::Create("Get-WindowsFeature $($FeatureName -join ', ')  -WarningAction SilentlyContinue")
                $result += Invoke-LabCommand -ComputerName $m -ActivityName $activityName -NoDisplay -ScriptBlock $cmd -UseLocalCredential:$UseLocalCredential -AsJob:$AsJob
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
                        $cmd = [scriptblock]::Create("DISM /online /get-featureinfo /featurename:$($feature)")
                        $featureList = Invoke-LabCommand -ComputerName $m -ActivityName $activityName -NoDisplay -ScriptBlock $cmd -UseLocalCredential:$UseLocalCredential -AsJob:$AsJob

                        $parseddismOutput = $featureList | Select-String -Pattern "Feature Name :", "State :", "Restart Required :"
                        [string]$featureNamedismOutput = $parseddismOutput[0]
                        [string]$featureRRdismOutput = $parseddismOutput[1]
                        [string]$featureStatedismOutput = $parseddismOutput[2]


                        $result += [PSCustomObject]@{
                            FeatureName     = $featureNamedismOutput.Split(":")[1].Trim()
                            RestartRequired = $featureRRdismOutput.Split(":")[1].Trim()
                            State           = $featureStatedismOutput.Split(":")[1].Trim()
                        }
                    }
                }
                else
                {
                    $cmd = [scriptblock]::Create("DISM /online /get-featureinfo /featurename:$($FeatureName)")
                    $featureList = Invoke-LabCommand -ComputerName $m -ActivityName $activityName -NoDisplay -ScriptBlock $cmd -UseLocalCredential:$UseLocalCredential -AsJob:$AsJob
                    $parseddismOutput = $featureList | Select-String -Pattern "Feature Name :", "State :", "Restart Required :"

                    [string]$featureNamedismOutput = $parseddismOutput[0]
                    [string]$featureRRdismOutput = $parseddismOutput[1]
                    [string]$featureStatedismOutput = $parseddismOutput[2]


                    $result += [PSCustomObject]@{
                        FeatureName     = $featureNamedismOutput.Split(":")[1].Trim()
                        RestartRequired = $featureRRdismOutput.Split(":")[1].Trim()
                        State           = $featureStatedismOutput.Split(":")[1].Trim()
                    }
                }
            }
            else
            {
                $cmd = [scriptblock]::Create("`$null;Import-Module -Name ServerManager; Get-WindowsFeature $($FeatureName -join ', ') -WarningAction SilentlyContinue")
                $result += Invoke-LabCommand -ComputerName $m -ActivityName $activityName -NoDisplay -ScriptBlock $cmd -UseLocalCredential:$UseLocalCredential -AsJob:$AsJob
            }
        }
    }

    if ($PassThru)
    {
        $result
    }

    Write-LogFunctionExit
}
