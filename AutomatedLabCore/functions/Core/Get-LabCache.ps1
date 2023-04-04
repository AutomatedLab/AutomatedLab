function Get-LabCache
{
    [CmdletBinding()]
    param
    ( )

    $regKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey('CurrentUser', 'Default')
    try
    {
        $key = $regKey.OpenSubKey('Software\AutomatedLab\Cache')
        foreach ($value in $key.GetValueNames())
        {
            $content = [xml]$key.GetValue($value)
            $timestamp = $content.SelectSingleNode('//Timestamp')
            [pscustomobject]@{
                Store     = $value
                Timestamp = $timestamp.datetime -as [datetime]
                Content   = $content
            }
        }
    }
    catch { Write-PSFMessage -Message "Cache not yet created" }
}
