function Install-LabAzureRequiredModule
{
    [CmdletBinding()]
    param
    (
        [string]
        $Repository = 'PSGallery',

        [ValidateSet('CurrentUser', 'AllUsers')]
        [string]
        $Scope = 'CurrentUser',

        [switch]
        $AzureStack
    )

    [hashtable[]] $modules = if ($AzureStack.IsPresent) { Get-LabConfigurationItem -Name RequiredAzStackModules } else { Get-LabConfigurationItem -Name RequiredAzModules }
    foreach ($module in $modules)
    {
        $isPresent = if ($module.MinimumVersion)
        {
            Get-Module -ListAvailable -Name $module.Name | Where-Object Version -ge $module.MinimumVersion
        }
        elseif ($module.RequiredVersion)
        {
            Get-Module -ListAvailable -Name $module.Name | Where-Object Version -eq $module.RequiredVersion
        }
        
        if ($isPresent)
        {
            Write-PSFMessage -Message "$($module.Name) already present"
            continue
        }

        Install-Module @module -Repository $Repository -Scope $Scope -Force
    }
}
