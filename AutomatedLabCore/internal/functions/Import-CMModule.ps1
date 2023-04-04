function Import-CMModule
{
    Param(
        [String]$ComputerName,
        [String]$SiteCode
    )
    if (-not(Get-Module ConfigurationManager))
    {
        try
        {
            Import-Module ("{0}\..\ConfigurationManager.psd1" -f $ENV:SMS_ADMIN_UI_PATH) -ErrorAction "Stop" -ErrorVariable "ImportModuleError"
        }
        catch
        {
            throw ("Failed to import ConfigMgr module: {0}" -f $ImportModuleError.ErrorRecord.Exception.Message)
        }
    }
    try
    {
        if (-not(Get-PSDrive -Name $SiteCode -PSProvider "CMSite" -ErrorAction "SilentlyContinue"))
        {
            New-PSDrive -Name $SiteCode -PSProvider "CMSite" -Root $ComputerName -Scope "Script" -ErrorAction "Stop" | Out-Null
        }
        Set-Location ("{0}:\" -f $SiteCode) -ErrorAction "Stop"    
    } 
    catch
    {
        if (Get-PSDrive -Name $SiteCode -PSProvider "CMSite" -ErrorAction "SilentlyContinue")
        {
            Remove-PSDrive -Name $SiteCode -Force
        }
        throw ("Failed to create New-PSDrive with site code `"{0}`" and server `"{1}`"" -f $SiteCode, $ComputerName)
    }
}
