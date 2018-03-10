function Set-UnattendedYastPackage
{
    param
    (
        [string[]]$Package
    )
    
    $packagesNode = $script:un.SelectSingleNode('/un:profile/un:software/un:packages', $script:nsm)
    foreach ($p in $Package)
    {
        $packageNode = $script:un.CreateElement('package', $script:nsm.LookupNamespace('un'))
        $packageNode.InnerText = $p
        $null = $packagesNode.AppendChild($packageNode)
    }
}