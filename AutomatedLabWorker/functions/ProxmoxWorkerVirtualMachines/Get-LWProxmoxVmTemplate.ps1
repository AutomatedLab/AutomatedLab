function Get-LWProxmoxVmTemplate
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true)]
        [object]$Node,

        [Parameter()]
        [string]$OperatingSystem,

        [Parameter()]
        [string]$OperatingSystemVersion,

        [Parameter()]
        [switch]
        $NoCache
    )

    begin {
        if (-not (Test-LabProxmoxConnection))
        {
            Write-Error 'There is no connection to the Proxmox cluster.'
            return
        }

        if ($null -eq $Node)
        {
            $Node = Get-LWProxmoxNode
        }

        $result = @()
    }

    process {

        if ($Node -isnot [string])
        {
            $Node = $Node.node
        }

        $templates = Get-LWProxmoxVM -Node $Node -IncludeTemplates -NoCache:$NoCache.IsPresent | Where-Object { $_.template -eq 1 }

        Write-ScreenInfo -Message "Found $($templates.Count) templates on Proxmox node '$Node'" -Type Verbose

        $OperatingSystem = ($OperatingSystem -replace '[\s\(\)]', '').ToLower()

        $result += if ($OperatingSystem -and $OperatingSystemVersion)
        {
            $templates | Where-Object {
                $_.tags -contains $OperatingSystem -and
                $_.tags -contains $OperatingSystemVersion -and
                $_.tags -contains 'template'
            }
        }
        elseif ($OperatingSystem)
        {
            $templates | Where-Object {
                $_.tags -contains $OperatingSystem -and
                $_.tags -contains 'template'
        }
        }
        else
        {
            $templates
        }

        Write-ScreenInfo -Message "Found $($result.Count) matching templates on Proxmox node '$Node'" -Type Verbose
    }

    end {
        if ($null -eq $result)
        {
            Write-Error "No templates found on Proxmox node '$Node'"
            return
        }
        else
        {
            Write-ScreenInfo -Message "Found $($result.Count) matching templates on Proxmox cluster." -Type Verbose
            $result
        }
    }
}
