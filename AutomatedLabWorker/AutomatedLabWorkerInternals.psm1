<#Work in progress
function Test-SubnetInSubnet
{
	param (
		[Parameter(Mandatory)]
		$SubNets,
		[Parameter(Mandatory)]
		[String]$IPAddress,
		[Parameter(Mandatory)]
		[String]$SubnetMask
	)

    If ($IPAddress.Contains('/'))
	{
		$temp = $IP.Split('/')
		$IPAddress = $temp[0]
		$SubnetMask = $temp[1]
	}

	If (!$SubnetMask.Contains('.'))
	{
		$SubnetMask = ConvertTo-Mask $SubnetMask
	}



    $decimalIP = ConvertTo-DecimalIP $IPAddress
	$decimalMask = ConvertTo-DecimalIP $SubnetMask

	$network = $decimalIP -BAnd $decimalMask
	$broadcast = $decimalIP -BOr
	((-BNot $decimalMask) -BAnd [UInt32]::MaxValue)
	$networkAddress = ConvertTo-DottedDecimalIP $network
	$rangeStart = ConvertTo-DottedDecimalIP ($network + 1)
	$rangeEnd = ConvertTo-DottedDecimalIP ($broadcast - 1)
	$broadcastAddress = ConvertTo-DottedDecimalIP $broadcast
	$MaskLength = ConvertTo-MaskLength $SubnetMask

	$binaryIP = ConvertTo-BinaryIP $IPAddress
	$private = $false

	switch -RegEx ($binaryIP)
	{
		'^1111'
		{
			$class = 'E'
			$subnetBitMap = '1111'
		}
		'^1110'
		{
			$class = 'D'
			$subnetBitMap = '1110'
		}
		'^110'
		{
			$class = 'C'
			If ($binaryIP -Match '^11000000.10101000')
			{
				$private = $True
			}
		}
		'^10'
		{
			$class = 'B'
			If ($binaryIP -Match '^10101100.0001')
			{
				$private = $True
			}
		}
		'^0'
		{
			$class = 'A'
			If ($binaryIP -Match '^00001010')
			{
				$private = $True
			}
		}
	}

	$netInfo = New-Object -TypeName Object
	Add-Member -MemberType NoteProperty -Name 'Network' -InputObject $netInfo -Value $networkAddress
	Add-Member -MemberType NoteProperty -Name 'Broadcast' -InputObject $netInfo -Value $broadcastAddress
	Add-Member -MemberType NoteProperty -Name 'Range' -InputObject $netInfo `
			   -Value "$rangeStart - $rangeEnd"
	Add-Member -MemberType NoteProperty -Name 'Mask' -InputObject $netInfo -Value $SubnetMask
	Add-Member -MemberType NoteProperty -Name 'MaskLength' -InputObject $netInfo -Value $MaskLength
	Add-Member -MemberType NoteProperty -Name 'Hosts' -InputObject $netInfo `
			   -Value $($broadcast - $network - 1)
	Add-Member -MemberType NoteProperty -Name 'Class' -InputObject $netInfo -Value $class
	Add-Member -MemberType NoteProperty -Name 'IsPrivate' -InputObject $netInfo -Value $private

    $startIP = ($rangeStart.split('.')[0] * 256*256*256) + ($rangeStart.split('.')[1] * 256*256) + ($rangeStart.split('.')[2] * 256) + ($rangeStart.split('.')[3])
    $endIP   = ($rangeEnd.split('.')[0] * 256*256*256) + ($rangeEnd.split('.')[1] * 256*256) + ($rangeEnd.split('.')[2] * 256) + ($rangeEnd.split('.')[3])


    if (([ipaddress]$IpAddress).Address -ge ([ipaddress]$rangeStart).Address -and ([ipaddress]$IpAddress).Address -le ([ipaddress]$rangeEnd).Address)
    {
        $true
    }
    else
    {
        $false
    }
}
#>

#region Function Test-IpInSameSameNetwork
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

#endregion Test-IpInSameSameNetwork
