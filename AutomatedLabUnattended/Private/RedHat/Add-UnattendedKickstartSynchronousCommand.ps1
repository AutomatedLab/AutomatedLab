function Add-UnattendedKickstartSynchronousCommand
{
    param (
        [Parameter(Mandatory)]
        [string]$Command,

        [Parameter(Mandatory)]
        [string]$Description
    )

    Write-PSFMessage -Message "Adding command to %post section to $Description"

    $idx = $script:un.IndexOf('%post')

    if ($idx -eq -1)
    {
        $script:un.Add('%post')
        $idx = $script:un.IndexOf('%post')
    }

    $script:un.Insert($idx + 1, $Command)
}
