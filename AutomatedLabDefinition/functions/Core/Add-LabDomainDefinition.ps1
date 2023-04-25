function Add-LabDomainDefinition
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$AdminUser,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$AdminPassword,

        [switch]$PassThru
    )

    Write-LogFunctionEntry

    if ($script:lab.Domains | Where-Object { $_.Name -eq $Name })
    {
        $errorMessage = "A domain with the name '$Name' is already defined"
        Write-Error $errorMessage
        Write-LogFunctionExitWithError -Message $errorMessage
        return
    }

    $domain = New-Object -TypeName AutomatedLab.Domain
    $domain.Name = $Name

    $user = New-Object -TypeName AutomatedLab.User
    $user.UserName = $AdminUser
    $user.Password = $AdminPassword

    $domain.Administrator = $user

    $script:lab.Domains.Add($domain)
    Write-PSFMessage "Added domain '$Name'. Lab now has $($Script:lab.Domains.Count) domain(s) defined"

    if ($PassThru)
    {
        $domain
    }

    Write-LogFunctionExit
}
