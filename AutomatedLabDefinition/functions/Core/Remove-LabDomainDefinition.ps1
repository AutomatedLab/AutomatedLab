function Remove-LabDomainDefinition
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Name
    )

    Write-LogFunctionEntry

    $domain = $script:lab.Domains | Where-Object { $_.Name -eq $Name }

    if (-not $domain)
    {
        Write-ScreenInfo "There is no domain defined with the name '$Name'" -Type Warning
    }
    else
    {
        [Void]$script:lab.Domains.Remove($domain)
        Write-PSFMessage "Domain '$Name' removed. Lab has $($Script:lab.Domains.Count) domain(s) defined"
    }

    Write-LogFunctionExit
}
