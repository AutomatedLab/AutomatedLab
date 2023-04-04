function Get-LabAzureLocation
{
    [CmdletBinding()]
    param (
        [string]$LocationName,

        [switch]$List
    )

    Test-LabHostConnected -Throw -Quiet

    Write-LogFunctionEntry

    $azureLocations = Get-AzLocation

    if ($LocationName)
    {
        if ($LocationName -notin ($azureLocations.DisplayName))
        {
            Write-Error "Invalid location. Please specify one of the following locations: ""'$($azureLocations.DisplayName -join ''', ''')"
            return
        }

        $azureLocations | Where-Object DisplayName -eq $LocationName
    }
    else
    {
        if ((Get-Lab -ErrorAction SilentlyContinue) -and (-not $list))
        {
            #if lab already exists, use the location used when this was deployed to create lab stickyness
            return (Get-Lab).AzureSettings.DefaultLocation.Name
        }

        $locationUrls = Get-LabConfigurationItem -Name AzureLocationsUrls

        foreach ($location in $azureLocations)
        {
            if ($locationUrls."$($location.DisplayName)")
            {
                $location | Add-Member -MemberType NoteProperty -Name 'Url' -Value ($locationUrls."$($location.DisplayName)" + '.blob.core.windows.net')
            }
            $location | Add-Member -MemberType NoteProperty -Name 'Latency' -Value 9999
        }

        $jobs = @()
        foreach ($location in ($azureLocations | Where-Object { $_.Url }))
        {
            $url = $location.Url
            $jobs += Start-Job -Name $location.DisplayName -ScriptBlock {
                $testUrl = $using:url

                try
                {
                    (Test-Port -ComputerName $testUrl -Port 443 -Count 4 -ErrorAction Stop | Measure-Object -Property ResponseTime -Average).Average
                }
                catch
                {
                    9999
                    #Write-PSFMessage -Level Warning "$testUrl $($_.Exception.Message)"
                }
            }
        }

        Wait-LWLabJob -Job $jobs -NoDisplay
        foreach ($job in $jobs)
        {
            $result = Receive-Job -Keep -Job $job
            ($azureLocations | Where-Object { $_.DisplayName -eq $job.Name }).Latency = $result
        }
        $jobs | Remove-Job

        Write-PSFMessage -Message 'DisplayName            Latency'
        foreach ($location in $azureLocations)
        {
            Write-PSFMessage -Message "$($location.DisplayName.PadRight(20)): $($location.Latency)"
        }

        if ($List)
        {
            $azureLocations | Sort-Object -Property Latency | Format-Table DisplayName, Latency
        }
        else
        {
            $azureLocations | Sort-Object -Property Latency | Select-Object -First 1 | Select-Object -ExpandProperty DisplayName
        }
    }

    Write-LogFunctionExit
}
