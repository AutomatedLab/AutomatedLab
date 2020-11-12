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

    $script:un.Add("keyboard '$($ci.TwoLetterISOLanguageName)'")
    $script:un.Add("lang $($ci.IetfLanguageTag -replace '-','_')")
}
