function Start-LWHypervVM
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [int]$DelayBetweenComputers = 0,

        [int]$PreDelaySeconds = 0,

        [int]$PostDelaySeconds = 0,

        [int]$ProgressIndicator,

        [switch]$NoNewLine
    )

    if ($PreDelaySeconds) {
        $job = Start-Job -Name 'Start-LWHypervVM - Pre Delay' -ScriptBlock { Start-Sleep -Seconds $Using:PreDelaySeconds }
        Wait-LWLabJob -Job $job -NoNewLine -ProgressIndicator $ProgressIndicator -Timeout 15 -NoDisplay
    }

    foreach ($Name in $(Get-LabVM -ComputerName $ComputerName -IncludeLinux | Where-Object SkipDeployment -eq $false))
    {
        $machine = Get-LabVM -ComputerName $Name -IncludeLinux
        $hvMachine = Get-LWHypervVM -Name $Name.ResourceName

        <#
            Remove _INSTALL.vhdx on Ubuntu if the VM has been shut down once - indicating that the
            cloudinit/subiquity phase was successfully finished.
            We compare GuestStatePath LastWriteTime as a simple and quick way to check if
            the VM's status has changed i.e. when it was stopped.
            One minute seems like a sane interval, we might need to increase it in the future.
        #>
        if ($hvMachine.State -ne 'Running' -and ((Get-Item -Path $hvMachine.GuestStatePath).LastWriteTime - $hvMachine.CreationTime) -gt '00:01:00')
        {
            Write-ScreenInfo -Type Verbose "Removing installation disk '$Name'"
            $disk = $hvMachine | Get-VMHardDiskDrive | Where-Object Path -like "*_INSTALL*"
            $diskPath = $disk.Path # Otherwise $disk will be update after remove-vmharddiskdrive was called
            $disk | Remove-VMHardDiskDrive
            Remove-Item -Path $diskPath -Force
        }

        try
        {
            $hvMachine | Hyper-V\Start-VM -ErrorAction Stop
        }
        catch
        {
            $ex = New-Object System.Exception("Could not start Hyper-V machine '$ComputerName': $($_.Exception.Message)", $_.Exception)
            throw $ex
        }

        if ($Name.OperatingSystemType -eq 'Linux')
        {
            Write-PSFMessage -Message "Skipping the wait period for $Name as it is a Linux system"
            continue
        }

        if ($DelayBetweenComputers -and $Name -ne $ComputerName[-1])
        {
            $job = Start-Job -Name 'Start-LWHypervVM - DelayBetweenComputers' -ScriptBlock { Start-Sleep -Seconds $Using:DelayBetweenComputers }
            Wait-LWLabJob -Job $job -NoNewLine:$NoNewLine -ProgressIndicator $ProgressIndicator -Timeout 15 -NoDisplay
        }
    }

    if ($PostDelaySeconds)
    {
        $job = Start-Job -Name 'Start-LWHypervVM - Post Delay' -ScriptBlock { Start-Sleep -Seconds $Using:PostDelaySeconds }
        Wait-LWLabJob -Job $job -NoNewLine:$NoNewLine -ProgressIndicator $ProgressIndicator -Timeout 15 -NoDisplay
    }

    Write-LogFunctionExit
}
