Function Test-IpInSameSameNetwork
{
	param
    (
		[AutomatedLab.IPNetwork]$Ip1,
		[AutomatedLab.IPNetwork]$Ip2
	)

    $ip1Decimal = $Ip1.SerializationNetworkAddress
    $ip2Decimal = $Ip2.SerializationNetworkAddress
    $ip1Total   = $Ip1.Total
    $ip2Total   = $Ip2.Total

    if (($ip1Decimal -ge $ip2Decimal) -and ($ip1Decimal -lt ([long]$ip2Decimal+[long]$ip2Total)))
    {
        return $true
    }

    if (($ip2Decimal -ge $ip1Decimal) -and ($ip2Decimal -lt ([long]$ip1Decimal+[long]$ip1Total)))
    {
        return $true
    }

    return $false
}
