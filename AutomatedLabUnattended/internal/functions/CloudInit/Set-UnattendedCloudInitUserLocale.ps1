function Set-UnattendedCloudInitUserLocale
{
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserLocale
    )

    try
    {
        $ci = [cultureinfo]::new($UserLocale)
    }
    catch
    {
        Write-PSFMessage -Message "Could not determine culture from $UserLocale. Assuming en_us"
        $script:un['autoinstall']['locale'] = 'en_US.UTF-8'
        $script:un['autoinstall']['keyboard'] = @{
            layout = 'us'
        }
        return
    }

    $weirdLinuxCultureName = if ($ci.IsNeutralCulture) { $ci.TwoLetterISOLanguageName } else {$ci.Name -split '-' | Select-Object -Last 1}
    $script:un['autoinstall']['locale'] = "$($ci.IetfLanguageTag -replace '-','_').UTF-8"
    $script:un['autoinstall']['keyboard'] = @{
        layout = $weirdLinuxCultureName.ToLower()
    }
}
