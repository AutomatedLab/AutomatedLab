function Enable-LabAzureJitAccess
{
    [CmdletBinding()]
    param 
    (
        [timespan]
        $MaximumAccessRequestDuration = '05:00:00',

        [switch]
        $PassThru
    )

    $vms = Get-LWAzureVm
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

    if (Get-AzJitNetworkAccessPolicy @parameters -ErrorAction SilentlyContinue)
    {
        Write-ScreenInfo -Type Verbose -Message 'JIT policy already configured'
        return
    }

    $weirdTimestampFormat = [System.Xml.XmlConvert]::ToString($MaximumAccessRequestDuration)
    $pip = Get-PublicIpAddress

    $vmPolicies = foreach ($vm in $vms)
    {
        @{
            id    = $vm.Id
            ports = @{
                number                     = 22
                protocol                   = "*"
                allowedSourceAddressPrefix = @($pip)
                maxRequestAccessDuration   = $weirdTimestampFormat
            },
            @{
                number                     = 3389
                protocol                   = "*"
                allowedSourceAddressPrefix = @($pip)
                maxRequestAccessDuration   = $weirdTimestampFormat
            },
            @{
                number                     = 5985
                protocol                   = "*"
                allowedSourceAddressPrefix = @($pip)
                maxRequestAccessDuration   = $weirdTimestampFormat
            }
        }
    }

    $policy = Set-AzJitNetworkAccessPolicy -Kind "Basic" @parameters -VirtualMachine $vmPolicies
    while ($policy.ProvisioningState -ne 'Succeeded')
    {
        $policy = Get-AzJitNetworkAccessPolicy @parameters
    }

    if ($PassThru) { $policy }
}
