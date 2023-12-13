function Remove-LWNetworkSwitch
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    param (
        [Parameter(Mandatory)]
        [string]$Name
    )

    Write-LogFunctionEntry

    if (-not (Get-VMSwitch -Name $Name -ErrorAction SilentlyContinue))
    {
        Write-ScreenInfo 'The network switch does not exist' -Type Warning
        return
    }

    if ((Get-LWHypervVM -ErrorAction SilentlyContinue | Get-VMNetworkAdapter | Where-Object {$_.SwitchName -eq $Name} | Measure-Object).Count -eq 0)
    {
        try
        {
            Remove-VMSwitch -Name $Name -Force -ErrorAction Stop
        }
        catch
        {
            Start-Sleep -Seconds 2
            Remove-VMSwitch -Name $Name -Force

            $networkDescription = Join-Path -Path (Get-Lab).LabPath -ChildPath "Network_$Name.xml"
            if (Test-Path -Path $networkDescription) {
                Remove-Item -Path $networkDescription
            }
        }

        Write-PSFMessage "Network switch '$Name' removed"
    }
    else
    {
        Write-ScreenInfo "Network switch '$Name' is still in use, skipping removal" -Type Warning
    }

    Write-LogFunctionExit

}
