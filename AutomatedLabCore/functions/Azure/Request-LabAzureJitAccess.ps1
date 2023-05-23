function Request-LabAzureJitAccess
{
    [CmdletBinding()]
    param
    (
        [string[]]
        $ComputerName,

        # Local end time, will be converted to UTC for request
        [timespan]
        $Duration = '04:45:00'
    )

    $lab = Get-Lab

    if ($lab.AzureSettings.IsAzureStack)
    {
        Write-Error -Message "$($lab.Name) is running on Azure Stack and thus does not support JIT access."
        return
    }

    $parameters = @{
        Location          = $lab.AzureSettings.DefaultLocation.Location
        Name              = 'AutomatedLabJIT'
        ResourceGroupName = $lab.AzureSettings.DefaultResourceGroup.ResourceGroupName
    }

    $policy = Get-AzJitNetworkAccessPolicy @parameters -ErrorAction SilentlyContinue
    if (-not $policy) { $policy = Enable-LabAzureJitAccess -MaximumAccessRequestDuration $Duration.Add('00:05:00') -PassThru }
    $nodes = if ($ComputerName.Count -eq 0) { Get-LabVm } else { Get-LabVm -ComputerName $ComputerName }
    $vms = Get-LWAzureVm -ComputerName $nodes.ResourceName
    $end = (Get-Date).Add($Duration)
    $utcEnd = $end.ToUniversalTime().ToString('u')
    $pip = Get-PublicIpAddress

    $jitRequests = foreach ($vm in $vms)
    {
        @{
            id    = $vm.Id
            ports = @{
                number                     = 22
                endTimeUtc                 = $utcEnd
                allowedSourceAddressPrefix = @($pip)
            }, @{
                number                     = 3389
                endTimeUtc                 = $utcEnd
                allowedSourceAddressPrefix = @($pip)
            }, @{
                number                     = 5985
                endTimeUtc                 = $utcEnd
                allowedSourceAddressPrefix = @($pip)
            }
        }
    }

    Set-PSFConfig -Module AutomatedLab -Name AzureJitTimestamp -Value $end -Validation datetime -Hidden
    $null = Start-AzJitNetworkAccessPolicy -ResourceId $policy.Id -VirtualMachine $jitRequests
}
