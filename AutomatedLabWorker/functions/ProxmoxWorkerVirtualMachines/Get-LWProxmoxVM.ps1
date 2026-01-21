function Get-LWProxmoxVM
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCompatibleCmdlets', '', Justification = 'Not relevant on Linux')]
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [Alias('Name')]
        [string[]]
        $ComputerName,

        [Parameter()]
        [object[]]
        $Node,

        [Parameter()]
        [switch]
        $NoError,

        [Parameter()]
        [switch]
        $IncludeTemplates,

        [Parameter()]
        [switch]
        $NoCache,

        [Parameter()]
        [switch]
        $NoStatusCurrent
    )

    Write-LogFunctionEntry

    if (-not (Test-LabProxmoxConnection))
    {
        Write-Error 'There is no connection to the Proxmox cluster.' -ErrorAction Stop
        return
    }

    if (-not $Node)
    {
        $Node = Get-LWProxmoxNode | Select-Object -ExpandProperty node
    }
    else
    {
        $Node = Get-LWProxmoxNode -Name $Node | Select-Object -ExpandProperty node
    }

    if ($null -eq $script:proxmoxVmCache)
    {
        $script:proxmoxVmCache = @{}
    }

    if ($NoCache)
    {
        Write-ScreenInfo -Message "Retrieving VM(s) from Proxmox node(s) '$($Node -join ', ')'" -Type Verbose -NoNewLine -TaskStart
    }

    $vms = foreach ($n in $Node)
    {
        if ($NoCache.IsPresent -or -not $script:proxmoxVmCache.ContainsKey($n))
        {
            $script:proxmoxVmCache.$n = $null

            Write-ScreenInfo -Message "Retrieving VM(s) from Proxmox node '$($n)'" -Type Verbose
            Write-ScreenInfo -Message '.' -Type Verbose -NoNewLine
            $result = Get-PveNodesQemu -Node $n
            if ($result.StatusCode -ne 200)
            {
                Write-Error "Failed to retrieve VM(s) from Proxmox node '$($n)': $($result.ReasonPhrase)"
                return
            }

            $result = $result.response.data
            $result | Add-Member -Name node -MemberType NoteProperty -Value $n

            foreach ($vm in $result)
            {
                if (-not $NoStatusCurrent)
                {
                    Write-ScreenInfo -Message "Retrieving current status for VM '$($vm.name)' on Proxmox node '$n'" -Type Verbose
                    $currentStatus = Get-PveNodesQemuStatusCurrent -Node $n -Vmid $vm.vmid
                    $vm | Add-Member -Name CurrentStatus -MemberType NoteProperty -Value $currentStatus.Response.data
                }
                if (-not [string]::IsNullOrEmpty($vm.tags))
                {
                    $vm.tags = $vm.tags -split ';'
                }
            }
            $script:proxmoxVmCache.$n = $result
            $result
        }
        else
        {
            Write-ScreenInfo -Message "Using cached Proxmox VM information for node '$n'" -Type Verbose
            $script:proxmoxVmCache.$n
        }
    }
    Write-ScreenInfo -Message 'done.' -Type Verbose -TaskEnd

    [object[]]$vms = $vms

    if ($ComputerName.Count -gt 0)
    {
        $vms = $vms | Where-Object { $_.Name -in $ComputerName }
    }

    $vms = $vms | Sort-Object -Unique -Property Name

    if (-not $NoError.IsPresent -and $ComputerName.Count -gt 0 -and -not $vms)
    {
        Write-Error -Message "Virtual machine '$ComputerName' not found on node(s) '$($Node -join ', ')'"
        return
    }

    if ($vms.Count -eq 0)
    {
        return
    }

    if ($IncludeTemplates)
    {
        if ($ComputerName.Count -gt 0)
        {
            return $vms | Where-Object { $_.Name -in $ComputerName }
        }
        else
        {
            $vms
        }
    }
    else
    {
        if ($ComputerName.Count -gt 0)
        {
            return $vms | Where-Object { $_.Name -in $ComputerName -and $_.template -ne 1 }
        }
        else
        {
            return $vms | Where-Object { $_.template -ne 1 }
        }
    }

    Write-LogFunctionExit
}
