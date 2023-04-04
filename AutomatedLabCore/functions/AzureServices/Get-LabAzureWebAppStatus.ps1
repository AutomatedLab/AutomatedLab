function Get-LabAzureWebAppStatus
{
    [CmdletBinding(DefaultParameterSetName = 'All')]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'ByName', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Name,

        [Parameter(Position = 1, ParameterSetName = 'ByName', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$ResourceGroup,

        [Parameter(ParameterSetName = 'All')]
        [switch]$All = $true,

        [switch]$AsHashTable
    )

    begin
    {
        Write-LogFunctionEntry
        $script:lab = Get-Lab
        if (-not $lab)
        {
            Write-Error 'No definitions imported, so there is nothing to do. Please use Import-Lab first'
            return
        }
        $allAzureWebApps = Get-AzWebApp
        if ($PSCmdlet.ParameterSetName -eq 'All')
        {
            $Name = $lab.AzureResources.Services.Name
            $ResourceGroup = $lab.AzureResources.Services.Name.ResourceGroup
        }
        $result = [ordered]@{}
    }

    process
    {
        $services = foreach ($n in $name)
        {
            if (-not $n -and -not $PSCmdlet.ParameterSetName -eq 'All') { return }

            $service = if ($ResourceGroup)
            {
                $lab.AzureResources.Services | Where-Object { $_.Name -eq $n -and $_.ResourceGroup -eq $ResourceGroup }
            }
            else
            {
                $lab.AzureResources.Services | Where-Object { $_.Name -eq $n }
            }

            if (-not $service)
            {
                Write-Error "The Azure App Service '$n' does not exist."
            }
            else
            {
                $service
            }
        }

        foreach ($service in $services)
        {
            $s = $allAzureWebApps | Where-Object { $_.Name -eq $service.Name -and $_.ResourceGroup -eq $service.ResourceGroup }
            if ($s)
            {
                $service.Merge($s, 'PublishProfiles')
                $result.Add($service, $s.State)
            }
            else
            {
                Write-Error "The Web App '$($service.Name)' does not exist in the Azure Resource Group $($service.ResourceGroup)."
            }
        }

    }

    end
    {
        Export-Lab
        if ($result.Count -eq 1 -and -not $AsHashTable)
        {
            $result[$result.Keys[0]]
        }
        else
        {
            $result
        }
        Write-LogFunctionExit
    }
}
