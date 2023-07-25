function Set-UnattendedCloudInitPackage
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Package
    )

    foreach ($pack in $Package)
    {
        if ($pack -in $script:un['autoinstall']['packages']) { continue }
        $script:un['autoinstall']['packages'] += $pack
    }
}