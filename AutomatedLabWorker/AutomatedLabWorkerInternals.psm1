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

#author Iain Brighton, from here: https://gist.github.com/iainbrighton/9d3dd03630225ee44126769c5d9c50a9
function Get-RequiredModulesFromMOF {
    <#
    .SYNOPSIS
        Scans a Desired State Configuration .mof file and returns the declared/
        required modules.
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [System.String] $Path
    )
    process {

        $modules = @{ }
        $moduleName = $null
        $moduleVersion = $null

        Get-Content -Path $Path -Encoding Unicode | ForEach-Object {
    
            $line = $_;
            if ($line -match '^\s?Instance of') {
                ## We have a new instance so write the existing one
                if (($null -ne $moduleName) -and ($null -ne $moduleVersion)) {
            
                    $modules[$moduleName] = $moduleVersion;
                    $moduleName = $null
                    $moduleVersion = $null
                    Write-Verbose "Module Instance found: $moduleName $moduleVersion"
                }
            }
            elseif ($line -match '(?<=^\s?ModuleName\s?=\s?")\S+(?=";)') {

                ## Ignore the default PSDesiredStateConfiguration module
                if ($Matches[0] -notmatch 'PSDesiredStateConfiguration') {
                    $moduleName = $Matches[0]
                    Write-Verbose "Found Module Name $modulename"
                }
                else {
                    Write-Verbose 'Excluding PSDesiredStateConfiguration module'
                }
            }
            elseif ($line -match '(?<=^\s?ModuleVersion\s?=\s?")\S+(?=";)') {
                $moduleVersion = $Matches[0] -as [System.Version]
                Write-Verbose "Module version = $moduleVersion"
            }
        }

        Write-Output -InputObject $modules
    } #end process
}

function Get-ModuleDependency
{
	[CmdletBinding()]
	param
	(
		[System.Management.Automation.PSModuleInfo]
		$Module
	)

	if ($Module.RequiredModules)
	{
		Write-Verbose "$($Module.Name) has required modules"
		foreach ($moduleName in $Module.RequiredModules)
		{
			$moduleInfo = Get-Module -ListAvailable -Name $moduleName.Name
			if ($moduleName.Version) {$moduleInfo = $moduleInfo | Where-Object Version -eq $moduleName.Version}
			$moduleInfo = $moduleInfo | Sort-Object Version -Descending | Select-Object -First 1
			Write-Verbose "Detecting dependencies for $($moduleInfo.Name)"
			Get-ModuleDependency -Module $moduleInfo
		}
	}
	
	$Module.ModuleBase
}
