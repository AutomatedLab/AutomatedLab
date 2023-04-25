function Get-LabSshKnownHost
{
    [CmdletBinding()]
    param ()

    if (-not (Test-Path -Path $home/.ssh/known_hosts)) { return }

    Get-Content -Path $home/.ssh/known_hosts | ConvertFrom-String -Delimiter ' ' -PropertyNames ComputerName,Cipher,Fingerprint -ErrorAction SilentlyContinue
}
