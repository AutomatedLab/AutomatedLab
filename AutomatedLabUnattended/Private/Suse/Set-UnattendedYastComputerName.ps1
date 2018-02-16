function Set-UnattendedYastComputerName
{
    param (
        [Parameter(Mandatory = $true)]
        [string]$ComputerName
    )
    $component = $script:un.SelectSingleNode('/un:profile/un:networking/un:dns/un:hostname', $script:nsm)
    $component.InnerText = $ComputerName
}