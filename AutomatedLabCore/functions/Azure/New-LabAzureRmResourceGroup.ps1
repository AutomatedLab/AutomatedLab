function New-LabAzureRmResourceGroup
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string[]]$ResourceGroupNames,

        [Parameter(Mandatory, Position = 1)]
        [string]$LocationName,

        [switch]$PassThru
    )

    Test-LabHostConnected -Throw -Quiet

    Write-LogFunctionEntry

    Update-LabAzureSettings

    Write-PSFMessage "Creating the resource groups '$($ResourceGroupNames -join ', ')' for location '$LocationName'"

    $resourceGroups = Get-AzResourceGroup

    foreach ($name in $ResourceGroupNames)
    {
        if ($resourceGroups | Where-Object ResourceGroupName -eq $name)
        {
            if (-not $script:lab.AzureSettings.ResourceGroups.ResourceGroupName.Contains($name))
            {
                $script:lab.AzureSettings.ResourceGroups.Add([AutomatedLab.Azure.AzureRmResourceGroup]::Create((Get-AzResourceGroup -ResourceGroupName $name)))
                Write-PSFMessage "The resource group '$name' does already exist"
            }
            continue
        }

        $result = New-AzResourceGroup -Name $name -Location $LocationName -Tag @{
            AutomatedLab = $script:lab.Name
            CreationTime = Get-Date
        }

        $script:lab.AzureSettings.ResourceGroups.Add([AutomatedLab.Azure.AzureRmResourceGroup]::Create((Get-AzResourceGroup -ResourceGroupName $name)))
        if ($PassThru)
        {
            $result
        }

        Write-PSFMessage "Resource group '$name' created"
    }

    Write-LogFunctionExit
}
