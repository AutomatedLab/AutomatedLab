function Set-UnattendedYastUserLocale
{
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserLocale
    )

    $language = $script:un.SelectSingleNode('/un:profile/un:language', $script:nsm)
    $languageNode = $script:un.SelectSingleNode('/un:profile/un:language/un:language', $script:nsm)
    $keyboard = $script:un.SelectSingleNode('/un:profile/un:keyboard/un:keymap', $script:nsm)

    try
    {
        $ci = [cultureinfo]::new($UserLocale)
    }
    catch
    {
        $ci = [cultureinfo]::new('en-us')
    }

    # Primary language
    $languageNode.InnerText = $ci.IetfLanguageTag -replace '-', '_'

    # Secondary language
    if ($ci.Name -ne 'en-US')
    {
        $languagesNode = $script:un.CreateElement('languages', $script:nsm.LookupNamespace('un'))
        $languagesNode.InnerText = 'en-us'
        $null = $language.AppendChild($languagesNode)
    }

    $keyMapName = '{0}-{1}' -f ($ci.EnglishName -split " ")[0].Trim().ToLower(), ($ci.Name -split '-')[-1].ToLower()
    $keyboard.InnerText = $keyMapName
}