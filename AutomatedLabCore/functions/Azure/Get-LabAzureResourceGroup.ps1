function Get-LabAzureResourceGroup
{
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param (
        [Parameter(Position = 0, ParameterSetName = 'ByName')]
        [string[]]$ResourceGroupName,

        [Parameter(Position = 0, ParameterSetName = 'ByLab')]
        [switch]$CurrentLab
    )

    Test-LabHostConnected -Throw -Quiet

    Write-LogFunctionEntry

    Update-LabAzureSettings

    $resourceGroups = $script:lab.AzureSettings.ResourceGroups

    if ($ResourceGroupName)
    {
        Write-PSFMessage "Getting the resource groups '$($ResourceGroupName -join ', ')'"
        $resourceGroups | Where-Object ResourceGroupName -in $ResourceGroupName
    }
    elseif ($CurrentLab)
    {
        $result = $resourceGroups | Where-Object { $_.Tags.AutomatedLab -eq $script:lab.Name }

        if (-not $result)
        {
            $result = $script:lab.AzureSettings.DefaultResourceGroup
        }
        $result
    }
    else
    {
        Write-PSFMessage 'Getting all resource groups'
        $resourceGroups
    }

    Write-LogFunctionExit
}
