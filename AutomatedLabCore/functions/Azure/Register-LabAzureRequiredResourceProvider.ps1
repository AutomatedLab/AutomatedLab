function Register-LabAzureRequiredResourceProvider
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $SubscriptionName,

        [Parameter()]
        [int]
        $ProgressIndicator = 5,

        [Parameter()]
        [switch]
        $NoDisplay
    )

    Write-LogFunctionEntry

    $null = Set-AzContext -Subscription $SubscriptionName

    $providers = @(
        'Microsoft.Network'
        'Microsoft.Compute'
        'Microsoft.Storage'
    )

    $providerObjects = Get-AzResourceProvider -ProviderNamespace $providers | Where-Object RegistrationState -ne 'Registered'
    if ($providerObjects)
    {
        Write-ScreenInfo -Message "Registering required Azure Resource Providers"
        $providerRegistrations = $providerObjects | Register-AzResourceProvider -ConsentToPermissions $true
        while ($providerRegistrations.RegistrationState -contains 'Registering')
        {
            $providerRegistrations = $providerRegistrations | Get-AzResourceProvider | Where-Object RegistrationState -ne 'Registered'
            Start-Sleep -Seconds 10
            Write-ProgressIndicator
        }
    }

    $providersAndFeatures = @{
        'Microsoft.Network' = @(
            'AllowBastionHost'
        )
    }

    $featureState = foreach ($paf in $providersAndFeatures.GetEnumerator())
    {
        foreach ($featureName in $paf.Value)
        {
            $feature = Get-AzProviderFeature -FeatureName $featureName -ProviderNamespace $paf.Key
            if ($feature.RegistrationState -eq 'NotRegistered')
            {
                Register-AzProviderFeature -FeatureName $featureName -ProviderNamespace $paf.Key
            }
        }
    }

    if (-not $featureState) { Write-LogFunctionExit; return }

    Write-ScreenInfo -Message "Waiting for $($featureState.Count) provider features to register"
    while ($featureState.RegistrationState -contains 'Registering')
    {
        $featureState = $featureState | ForEach-Object {
            Get-AzProviderFeature -FeatureName $_.FeatureName -ProviderNamespace $_.ProviderName
        }
        Start-Sleep -Seconds 10
        Write-ProgressIndicator
    }

    Write-LogFunctionExit
}