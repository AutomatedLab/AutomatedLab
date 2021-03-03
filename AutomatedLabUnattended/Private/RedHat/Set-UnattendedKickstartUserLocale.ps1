function Set-UnattendedKickstartUserLocale
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
        $script:un.Add("keyboard 'us'")
        $script:un.Add('lang en_us')
        return
    }

    $weirdLinuxCultureName = if ($ci.IsNeutralCulture) { $ci.TwoLetterISOLanguageName } else {$ci.Name -split '-' | Select-Object -Last 1}
    $script:un.Add("keyboard '$($weirdLinuxCultureName.ToLower())'")
    $script:un.Add("lang $($ci.IetfLanguageTag -replace '-','_')")
}
