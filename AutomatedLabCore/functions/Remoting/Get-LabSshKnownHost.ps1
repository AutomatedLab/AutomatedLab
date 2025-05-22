function Get-LabSshKnownHost
{
    [CmdletBinding()]
    param ()

    if (-not (Test-Path -Path $home/.ssh/known_hosts)) { return }

    foreach ($line in (Get-Content -Path $home/.ssh/known_hosts)) {
        $values = $line -split '\s'
        [pscustomobject]@{
            ComputerName = $values[0]
            Cipher       = $values[1]
            Fingerprint  = $values[2]
        }
    }
}
