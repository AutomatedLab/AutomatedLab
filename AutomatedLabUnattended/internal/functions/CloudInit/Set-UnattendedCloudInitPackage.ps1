function Set-UnattendedCloudInitPackage
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Package,

        [bool]
        $IsSnap = $false
    )

    if ($IsSnap -and -not $script:un['autoinstall'].Contains('snaps')) {
        $script:un['autoinstall']['snaps'] = [System.Collections.Generic.List[hashtable]]::new()
    }

    foreach ($pack in $Package)
    {
        if ($pack -in $script:un['autoinstall']['packages'] -or $pack -in $script:un['autoinstall']['snaps'].name) { continue }
        
        if ($IsSnap) {
            $script:un['autoinstall']['snaps'].Add(@{
                name = $pack
            })
            continue
        }

        $script:un['autoinstall']['packages'] += $pack
    }
}