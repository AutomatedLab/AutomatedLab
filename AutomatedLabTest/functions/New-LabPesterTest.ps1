function New-LabPesterTest
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string[]]
        $Role,

        [Parameter(Mandatory)]
        [string]
        $Path,

        [Parameter()]
        [switch]
        $IsCustomRole
    )

    foreach ($r in $Role)
    {
        $line = if ($IsCustomRole.IsPresent)
        {
            "(Get-LabVM).Where({`$_.PostInstallationActivity.Where({`$_.IsCustomRole}).RoleName -contains '$r'})"
        }
        else
        {
            "(Get-LabVm -Role $r).Count | Should -Be `$(Get-Lab).Machines.Where({`$_.Roles.Name -contains '$r'}).Count"
        }

        $fileContent = @"
Describe "[`$((Get-Lab).Name)] $r" -Tag $r {
    Context "Role deployment successful" {
        It "[$r] Should return the correct amount of machines" {
            $line
        }
    }
}
"@

        if (Test-Path -Path (Join-Path -Path $Path -ChildPath "$r.tests.ps1"))
        {
            continue
        }

        Set-Content -Path (Join-Path -Path $Path -ChildPath "$r.tests.ps1") -Value $fileContent
    }
}