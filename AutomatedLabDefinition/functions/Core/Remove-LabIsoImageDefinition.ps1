function Remove-LabIsoImageDefinition
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$Name
    )

    Write-LogFunctionEntry

    $iso = $script:lab.Sources.ISOs | Where-Object -FilterScript {
        $_.Name -eq $Name
    }

    if (-not $iso)
    {
        Write-ScreenInfo "There is no Iso Image defined with the name '$Name'" -Type Warning
    }
    else
    {
        [Void]$script:lab.Sources.ISOs.Remove($iso)
        Write-PSFMessage "Iso Image '$Name' removed. Lab has $($Script:lab.Sources.ISOs.Count) Iso Image(s) defined"
    }

    Write-LogFunctionExit
}
