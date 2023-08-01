function Get-LabConfigurationItem
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [string]
        $Name,

        [Parameter()]
        $Default
    )

    if ($Name)
    {
        $setting = (Get-PSFConfig -Module AutomatedLab -Name $Name -Force).Value
        if (-not $setting -and $Default)
        {
            return $Default
        }

        return $setting
    }

    Get-PSFConfig -Module AutomatedLab
}
