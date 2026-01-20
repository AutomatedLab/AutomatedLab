function Get-LWProxmoxVmTemplate {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [object]$Node,

        [Parameter()]
        [string]$OperatingSystem,

        [Parameter()]
        [string]$OperatingSystemVersion
    )

    if (-not (Test-LabProxmoxConnection)) {
        Write-Error 'There is no connection to the Proxmox cluster.'
        return
    }

    $templates = Get-PveNodesQemu -Node $Node

    if ($templates.StatusCode -ne 200) {
        Write-Error "Failed to retrieve VM templates from Proxmox node '$($Node.node)': $($templates.ReasonPhrase)"
        return
    }

    $OperatingSystem = ($OperatingSystem -replace '[\s\(\)]', '').ToLower()

    $templates = $templates.Response.data | Where-Object { $_.template -eq 1 }
    foreach ($template in $templates) {
        $template.tags = $template.tags -split ';'
    }

    if ($OperatingSystem -and $OperatingSystemVersion) {
        $template | Where-Object { $_.tags -contains $OperatingSystem -and $_.tags -contains $OperatingSystemVersion }
    }
    elseif ($OperatingSystem) {
        $template | Where-Object { $_.tags -contains $OperatingSystem }
    }
    else {
        $templates
    }
}
