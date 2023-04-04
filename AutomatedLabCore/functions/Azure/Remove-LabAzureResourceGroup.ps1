function Remove-LabAzureResourceGroup
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [string[]]$ResourceGroupName,

        [switch]$Force
    )

    begin
    {
        Test-LabHostConnected -Throw -Quiet

        Write-LogFunctionEntry

        Update-LabAzureSettings

        $resourceGroups = Get-LabAzureResourceGroup -CurrentLab
    }

    process
    {
        foreach ($name in $ResourceGroupName)
        {
            Write-ScreenInfo -Message "Removing the Resource Group '$name'" -Type Warning
            if ($resourceGroups.ResourceGroupName -contains $name)
            {
                Remove-AzResourceGroup -Name $name -Force:$Force | Out-Null
                Write-PSFMessage "Resource Group '$($name)' removed"

                $resourceGroup = $script:lab.AzureSettings.ResourceGroups | Where-Object ResourceGroupName -eq $name
                $script:lab.AzureSettings.ResourceGroups.Remove($resourceGroup) | Out-Null
            }
            else
            {
                Write-ScreenInfo -Message "RG '$name' could not be found" -Type Error
            }
        }
    }

    end
    {
        Write-LogFunctionExit
    }
}
