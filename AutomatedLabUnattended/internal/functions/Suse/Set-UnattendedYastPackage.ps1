function Set-UnattendedYastPackage {
    param
    (
        [string[]]$Package
    )

    $packagesNode = $script:un.SelectSingleNode('/un:profile/un:software/un:packages', $script:nsm)
    $patternsNode = $script:un.SelectSingleNode('/un:profile/un:software/un:patterns', $script:nsm)

    foreach ($p in $Package) {
        if ($p -replace '^pattern_', '' -in $patternsNode.ChildNodes.InnerText -or $p -in $packagesNode.ChildNodes.InnerText) {
            Write-Verbose "Package or pattern '$p' already exists in the unattended Yast configuration."
            continue
        }

        if ($p -match "^pattern_") {
            $patternNode = $script:un.CreateElement('pattern', $script:nsm.LookupNamespace('un'))
            $patternNode.InnerText = $p
            $null = $patternsNode.AppendChild($patternNode)
        }
        else {
            $packageNode = $script:un.CreateElement('pattern', $script:nsm.LookupNamespace('un'))
            $packageNode.InnerText = $p
            $null = $packagesNode.AppendChild($packageNode)
        }
    }
}
