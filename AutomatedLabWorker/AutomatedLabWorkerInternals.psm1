#region Internals
#region IP function
Function Get-NetworkAddress
{
  <#
    .Synopsis
    Takes an IP address and subnet mask then calculates the network address for the range.
    .Description
    Get-NetworkAddress returns the network address for a subnet by performing a bitwise AND 
    operation against the decimal forms of the IP address and subnet mask. Get-NetworkAddress
    expects both the IP address and subnet mask in dotted decimal format.
    .Parameter IPAddress
    Any IP address within the network range.
    .Parameter SubnetMask
    The subnet mask for the network.
  #>
	
	[CmdLetBinding()]
	Param (
		[Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
		[Net.IPAddress]$IPAddress,
		
		[Parameter(Mandatory = $True, Position = 1)]
		[Alias('Mask')]
		[Net.IPAddress]$SubnetMask
	)
	
	Process
	{
		Return ConvertTo-DottedDecimalIP ((ConvertTo-DecimalIP $IPAddress) -BAnd (ConvertTo-DecimalIP $SubnetMask))
	}
}

Function ConvertTo-Mask
{
  <#
    .Synopsis
    Returns a dotted decimal subnet mask from a mask length.
    .Description
    ConvertTo-Mask returns a subnet mask in dotted decimal format from an integer value ranging 
    between 0 and 32. ConvertTo-Mask first creates a binary string from the length, converts 
    that to an unsigned 32-bit integer then calls ConvertTo-DottedDecimalIP to complete the operation.
    .Parameter MaskLength
    The number of bits which must be masked.
  #>
	
	[CmdLetBinding()]
	Param (
		[Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
		[Alias('Length')]
		[ValidateRange(0, 32)]
		$MaskLength
	)
	
	Process
	{
		Return ConvertTo-DottedDecimalIP ([Convert]::ToUInt32($(('1' * $MaskLength).PadRight(32, '0')), 2))
	}
}


Function ConvertTo-MaskLength
{
  <#
    .Synopsis
    Returns the length of a subnet mask.
    .Description
    ConvertTo-MaskLength accepts any IPv4 address as input, however the output value 
    only makes sense when using a subnet mask.
    .Parameter SubnetMask
    A subnet mask to convert into length
  #>
	
	[CmdLetBinding()]
	Param (
		[Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
		[Alias('Mask')]
		[Net.IPAddress]$SubnetMask
	)
	
	Process
	{
		$Bits = "$( $SubnetMask.GetAddressBytes() | ForEach-Object  -Process { [Convert]::ToString($_, 2) 
    } )"
		$Bitsx = $Bits -Replace '[\s0]'
		
		Return $Bitsx.Length
	}
}

Function ConvertTo-DottedDecimalIP
{
  <#
    .Synopsis
    Returns a dotted decimal IP address from either an unsigned 32-bit integer or a dotted binary string.
    .Description
    ConvertTo-DottedDecimalIP uses a regular expression match on the input string to convert to an IP address.
    .Parameter IPAddress
    A string representation of an IP address from either UInt32 or dotted binary.
  #>
	
	[CmdLetBinding()]
	Param (
		[Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
		[String]$IPAddress
	)
	
	process
	{
		switch -RegEx ($IPAddress)
		{
			'([01]{8}\.){3}[01]{8}'
			{
				return [String]::Join('.', $($IPAddress.Split('.') | ForEach-Object -Process {
					[Convert]::ToUInt32($_, 2)
				}
				))
			}
			'\d'
			{
				$IPAddress = [UInt32]$IPAddress
				$dottedIP = $(For ($i = 3; $i -gt -1; $i--)
				{
					$remainder = $IPAddress % [Math]::Pow(256, $i)
					($IPAddress - $remainder) / [Math]::Pow(256, $i)
					$IPAddress = $remainder
				}
				)
				
				return [String]::Join('.', $dottedIP)
			}
			default
			{
				Write-Error 'Cannot convert this format'
			}
		}
	}
}

Function ConvertTo-DecimalIP
{
  <#
    .Synopsis
    Converts a Decimal IP address into a 32-bit unsigned integer.
    .Description
    ConvertTo-DecimalIP takes a decimal IP, uses a shift-like operation on each octet and returns a single UInt32 value.
    .Parameter IPAddress
    An IP Address to convert.
  #>
	
	[CmdLetBinding()]
	Param (
		[Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
		[Net.IPAddress]$IPAddress
	)
	
	Process
	{
		$i = 3
		$decimalIP = 0
		$IPAddress.GetAddressBytes() | ForEach-Object -Process {
			$decimalIP += $_ * [Math]::Pow(256, $i)
			$i--
		}
		
		Return [UInt32]$decimalIP
	}
}

Function ConvertTo-BinaryIP
{
  <#
    .Synopsis
    Converts a Decimal IP address into a binary format.
    .Description
    ConvertTo-BinaryIP uses System.Convert to switch between decimal and binary format. The output from this function is dotted binary.
    .Parameter IPAddress
    An IP Address to convert.
  #>
	
	[CmdLetBinding()]
	Param (
		[Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
		[Net.IPAddress]$IPAddress
	)
	
	Process
	{
		Return [String]::Join('.', $($IPAddress.GetAddressBytes() |
		ForEach-Object -Process {
			[Convert]::ToString($_, 2).PadLeft(8, '0')
		}
		))
	}
}

Function Get-BroadcastAddress
{
  <#
    .Synopsis
    Takes an IP address and subnet mask then calculates the broadcast address for the range.
    .Description
    Get-BroadcastAddress returns the broadcast address for a subnet by performing a bitwise AND 
    operation against the decimal forms of the IP address and inverted subnet mask. 
    Get-BroadcastAddress expects both the IP address and subnet mask in dotted decimal format.
    .Parameter IPAddress
    Any IP address within the network range.
    .Parameter SubnetMask
    The subnet mask for the network.
  #>
	
	[CmdLetBinding()]
	Param (
		[Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
		[Net.IPAddress]$IPAddress,
		
		[Parameter(Mandatory = $True, Position = 1)]
		[Alias('Mask')]
		[Net.IPAddress]$SubnetMask
	)
	
	process
	{
		return ConvertTo-DottedDecimalIP $((ConvertTo-DecimalIP $IPAddress) -BOr `
		((-bnot (ConvertTo-DecimalIP $SubnetMask)) -band [UInt32]::MaxValue))
	}
}

function Get-NetworkSummary
{
	param (
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
	
	return $netInfo
}

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

function Get-NetworkRange
{
	param (
		[string]$IPAddress,
		[string]$SubnetMask
	)
	
	if ($IPAddress.Contains('/'))
	{
		$temp = $IPAddress.Split('/')
		$IPAddress = $temp[0]
		$SubnetMask = $temp[1]
	}
	
	If (-not $SubnetMask.Contains('.'))
	{
		$SubnetMask = ConvertTo-Mask -MaskLength $SubnetMask
	}
	
	$decimalIP = ConvertTo-DecimalIP -IPAddress $IPAddress
	$decimalMask = ConvertTo-DecimalIP -IPAddress $SubnetMask
	
	$network = $decimalIP -band $decimalMask
	$broadcast = $decimalIP -bor ((-bnot $decimalMask) -band [UInt32]::MaxValue)
	
	for ($i = $($network + 1); $i -lt $broadcast; $i++)
	{
		ConvertTo-DottedDecimalIP -IPAddress $i
	}
}

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

#endregion IP functions

#region Get-Type (helper function for creating generic types)
function Get-Type
{
	param (
		[Parameter(Position = 0, Mandatory = $True)]
		[string] $GenericType,
		
		[Parameter(Position = 1, Mandatory = $True)]
		[string[]] $T
	)
	
	$T = $T -as [type[]]
	
	try
	{
		$generic = [type]($GenericType + '`' + $T.Count)
		$generic.MakeGenericType($T)
	}
	catch [Exception]
	{
		throw New-Object -TypeName System.Exception -ArgumentList ('Cannot create generic type', $_.Exception)
	}
}
#endregion
#region Invoke-Ternary
function Invoke-Ternary ([scriptblock]$decider, [scriptblock]$ifTrue, [scriptblock]$ifFalse)
{
	if (&$decider)
	{
		&$ifTrue
	}
	else
	{
		&$ifFalse
	}
}
Set-Alias -Name ?? -Value Invoke-Ternary -Option AllScope -Description "Ternary Operator like '?' in C#"
#endregion
#endregion Internals