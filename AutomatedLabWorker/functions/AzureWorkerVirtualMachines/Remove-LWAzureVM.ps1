function Remove-LWAzureVM
{
    Param (
        [Parameter(Mandatory)]
        [string]$Name,

        [switch]$AsJob,

        [switch]$PassThru
    )

    Test-LabHostConnected -Throw -Quiet

    Write-LogFunctionEntry

    $azureRetryCount = Get-LabConfigurationItem -Name AzureRetryCount

    $Lab = Get-Lab
    $vm = Get-AzVM -ResourceGroupName $Lab.AzureSettings.DefaultResourceGroup.ResourceGroupName -Name $Name -ErrorAction SilentlyContinue
    $null = $vm | Remove-AzVM -Force
    foreach ($loadBalancer in (Get-AzLoadBalancer -ResourceGroupName $Lab.AzureSettings.DefaultResourceGroup.ResourceGroupName))
    {
        $rules = $loadBalancer | Get-AzLoadBalancerInboundNatRuleConfig | Where-Object Name -like "$($Name)*"
        foreach ($rule in $rules)
        {
            $null = Remove-AzLoadBalancerInboundNatRuleConfig -LoadBalancer $loadBalancer -Name $rule.Name -Confirm:$false
        }
    }

    $vmResources = Get-AzResource -ResourceGroupName $Lab.AzureSettings.DefaultResourceGroup.ResourceGroupName -Name "$($name)*"
    $jobs = $vmResources | Remove-AzResource -AsJob -Force -Confirm:$false

    if (-not $AsJob.IsPresent)
    {
        $null = $jobs | Wait-Job
    }

    if ($PassThru.IsPresent)
    {
        $jobs
    }

    Write-LogFunctionExit
}
