function Start-LWProxmoxWindowsSysprep
{
    <#
    .SYNOPSIS
        Syspreps a Windows-based Proxmox VM after removing per-user AppX packages that block generalization.

    .DESCRIPTION
        Prepares one or more Windows virtual machines running on Proxmox VE for image generalization and
        runs Sysprep through the QEMU Guest Agent.

        Sysprep '/generalize' fails on modern Windows client images when a per-user (staged or installed)
        AppX package is present that is not part of the provisioned (system) package set. To avoid the
        well-known AppX generalization failures, the function first runs a cleanup script on the guest
        that removes every user-installed AppX package whose identity (name, publisher and version) is not
        also present as a provisioned package, skipping framework and non-removable packages. Packages
        whose payload is already missing on disk (HRESULT 0x80070002) are ignored so the cleanup does not
        fail on partially removed packages.

        After the cleanup completes successfully the function starts
        'sysprep.exe /generalize /oobe /reboot /unattend:C:\Unattend.xml' on the guest. The cleanup step
        is executed with -Wait so that Sysprep is only started once the AppX removal has finished; if the
        cleanup fails, Sysprep is not started.

    .PARAMETER ComputerName
        The name(s) of the Proxmox-hosted Windows VM(s) to prepare and Sysprep.

    .EXAMPLE
        Start-LWProxmoxWindowsSysprep -ComputerName 'Client1'

        Removes the blocking per-user AppX packages on 'Client1' and then starts an unattended Sysprep
        generalization pass using C:\Unattend.xml.
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string[]]$ComputerName
    )

    $cleanupScript = @'
$ErrorActionPreference = 'Stop'

$provisionedPackageIdentities = @(
    Get-AppxProvisionedPackage -Online |
        ForEach-Object {
            '{0}|{1}|{2}' -f $_.DisplayName, $_.PublisherId, $_.Version
        }
)

Get-AppxPackage -AllUsers |
    Where-Object {
        $installedForUser = @(
            $_.PackageUserInformation |
                Where-Object InstallState -eq 'Installed'
        ).Count -gt 0
        $packageIdentity = '{0}|{1}|{2}' -f $_.Name, $_.PublisherId, $_.Version
        $installedForUser -and
        $packageIdentity -notin $provisionedPackageIdentities -and
        -not $_.IsFramework -and
        -not $_.NonRemovable
    } |
    ForEach-Object {
        try {
            Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction Stop
        }
        catch {
            $isMissingPackageFile =
                $_.Exception.HResult -eq -2147009286 -and
                $_.Exception.Message -match '0x80070002'
            if (-not $isMissingPackageFile) {
                throw
            }
        }
    }
'@

    $encodedCleanup = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($cleanupScript))
    $cleanupCommand = "powershell.exe -NoProfile -NonInteractive -EncodedCommand $encodedCleanup"
    Start-LWProxmoxAgentExecutionOnVM -ComputerName $ComputerName -Command $cleanupCommand -Wait

    $sysprepCommand = 'C:\Windows\System32\Sysprep\sysprep.exe /generalize /oobe /reboot /unattend:C:\Unattend.xml'
    Start-LWProxmoxAgentExecutionOnVM -ComputerName $ComputerName -Command $sysprepCommand -ErrorAction Stop
}