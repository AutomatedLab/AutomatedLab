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
        cleanup fails, Sysprep is not started. The cleanup runs VM by VM, and Sysprep is started on all VMs
        only after the cleanup succeeded on every VM.

        The cleanup is idempotent, so it may run again. When its result is lost together with the QEMU Guest
        Agent (the agent restarted or the guest rebooted while the cleanup ran, which
        Start-LWProxmoxAgentExecutionOnVM -Wait reports with the error id 'ProxmoxAgentCommandResultLost'),
        the function waits until the guest agent can execute commands again (timeout: configuration item
        ProxmoxAgentExecTimeout, 300 seconds by default) and runs the cleanup again, at most
        ProxmoxAgentCleanupRetries more times (default 2; 0 disables the re-run). Any other cleanup failure,
        such as a non-zero exit code, a signal or a timeout, still ends the function without starting
        Sysprep. The Sysprep command itself is never run twice.

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

    $cleanupRetries = -1
    foreach ($name in $ComputerName)
    {
        $run = 0
        while ($true)
        {
            $run++
            try
            {
                Start-LWProxmoxAgentExecutionOnVM -ComputerName $name -Command $cleanupCommand -Wait
                break
            }
            catch
            {
                $cleanupError = $_

                # Write-Error appends the name of the calling command to the error id.
                if ($cleanupError.FullyQualifiedErrorId -notmatch '^ProxmoxAgentCommandResultLost(,|$)')
                {
                    throw
                }

                if ($cleanupRetries -lt 0)
                {
                    # No -Default: Get-LabConfigurationItem would turn a configured 0 into the default.
                    $configuredRetries = Get-LabConfigurationItem -Name ProxmoxAgentCleanupRetries
                    $cleanupRetries = 2
                    if (-not [string]::IsNullOrEmpty([string]$configuredRetries))
                    {
                        $cleanupRetries = [Math]::Max(0, [int]$configuredRetries)
                    }
                }

                if ($run -gt $cleanupRetries)
                {
                    Write-Error -Message "The AppX cleanup on VM '$name' lost its result on every run (runs: $run, re-runs allowed by ProxmoxAgentCleanupRetries: $cleanupRetries). Sysprep was not started. Last error: $($cleanupError.Exception.Message)" -TargetObject $name -ErrorAction Stop
                }

                $proxmoxVm = Get-LWProxmoxVM -ComputerName $name -ErrorAction Stop | Select-Object -First 1
                $execTimeout = Get-LabConfigurationItem -Name ProxmoxAgentExecTimeout -Default 300
                Write-PSFMessage -Level Warning -Message "The AppX cleanup on VM '$name' lost its result (run $run of $($cleanupRetries + 1)): $($cleanupError.Exception.Message) Waiting for the guest agent to run commands again, then running the cleanup again."
                $execReady = Wait-LWProxmoxGuestAgentReady -Node $proxmoxVm.node -Vmid $proxmoxVm.VmId -Name $name -TimeoutSeconds $execTimeout -RequireExec
                if (-not $execReady)
                {
                    Write-Error -Message "The QEMU guest agent on VM '$name' did not run commands again within $execTimeout seconds after the AppX cleanup lost its result. The cleanup was not run again and Sysprep was not started." -TargetObject $name -ErrorAction Stop
                }
            }
        }
    }

    $sysprepCommand = 'C:\Windows\System32\Sysprep\sysprep.exe /generalize /oobe /reboot /unattend:C:\Unattend.xml'
    Start-LWProxmoxAgentExecutionOnVM -ComputerName $ComputerName -Command $sysprepCommand -ErrorAction Stop
}