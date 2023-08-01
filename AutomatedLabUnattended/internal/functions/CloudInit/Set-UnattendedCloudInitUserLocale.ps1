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
        $script:un.locale = 'en_US.UTF-8'
        return
    }

    $script:un.locale = "$($ci.IetfLanguageTag -replace '-','_').UTF-8"
}
