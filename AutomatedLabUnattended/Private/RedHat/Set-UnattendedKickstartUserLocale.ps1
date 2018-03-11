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
        Write-Verbose -Message "Could not determine culture from $UserLocale. Assuming en_us"        
        $script:un += "keyboard 'us'"
        $script:un += 'lang en_us'
        return
    }

    $script:un += "keyboard '$($ci.TwoLetterISOLanguageName)'"
    $script:un += "lang $($ci.IetfLanguageTag -replace '-','_')"
}
