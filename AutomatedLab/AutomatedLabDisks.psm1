#region New-LabBaseImages
function New-LabBaseImages
{
	# .ExternalHelp AutomatedLab.Help.xml
	[cmdletBinding()]
	param ()
	
	Write-LogFunctionEntry
	
    $lab = Get-Lab
	if (-not $lab)
	{
		Write-Error 'No definitions imported, so there is nothing to do. Please use Import-Lab first'
		return
	}
	
	$isos = $lab.Sources.ISOs | Where-Object { $_.IsOperatingSystem }
	$oses = (Get-LabMachine -All | Select-Object).OperatingSystem
    
	if (-not $lab.Sources.AvailableOperatingSystems)
	{
		throw "There isn't a single operating system ISO available in the lab. Please call 'Get-LabAvailableOperatingSystem' to see what AutomatedLab has found and check the LabSources folder location by calling 'Get-LabSourcesLocation'."
	}

	$osesProcessed = @()
    $BaseImagesCreated = 0

    foreach ($os in $oses)
	{
		if (-not $os.ProductKey)
		{
			$message = "The product key is unknown for the OS '$($os.OperatingSystemName)' in ISO image '$($os.OSName)'. Cannot install lab until this problem is solved."
			Write-LogFunctionExitWithError -Message $message
			throw $message
		}
	
        $baseDiskPath = Join-Path -Path $lab.Target.Path -ChildPath "BASE_$($os.OperatingSystemName.Replace(' ', ''))_$($os.Version).vhdx"
		$os.BaseDiskPath = $baseDiskPath
        
		$hostOsVersion = [System.Version]((Get-CimInstance -ClassName Win32_OperatingSystem).Version) 
        
        if ($hostOsVersion -ge [System.Version]'6.3' -and $os.Version -ge [System.Version]'6.2')
		{
            Write-Verbose -Message "Host OS version is '$($hostOsVersion)' and OS to create disk for is version '$($os.Version)'. So, setting partition style to GPT."
			$partitionStyle = 'GPT'
		}
        else
        {
            Write-Verbose -Message "Host OS version is '$($hostOsVersion)' and OS to create disk for is version '$($os.Version)'. So, KEEPING partition style as MBR."
            $partitionStyle = 'MBR'
        }
        
        if ($osesProcessed -notcontains $os)
        {
            $osesProcessed += $os
            
    	    if (-not (Test-Path $baseDiskPath))
            {
                Stop-ShellHWDetectionService
                
                New-LWReferenceVHDX -IsoOsPath $os.IsoPath `
                    -ReferenceVhdxPath $baseDiskPath `
				    -OsName $os.OperatingSystemName `
				    -ImageName $os.OperatingSystemImageName `
				    -SizeInGb $lab.Target.ReferenceDiskSizeInGB `
				    -PartitionStyle $partitionStyle

                $BaseImagesCreated++
            }
            else
            {
                Write-Verbose -Message "The base image $baseDiskPath already exists"
            }
        }
		else
		{
            Write-Verbose -Message "Base disk for operating system '$os' already created previously"
		}
	}
    
    if (-not $BaseImagesCreated)
    {
        Write-ScreenInfo -Message 'All base images were created previously'
    }

	Start-ShellHWDetectionService
    
	Write-LogFunctionExit
}
#endregion New-LabBaseImages


function Stop-ShellHWDetectionService
{
	# .ExternalHelp AutomatedLab.Help.xml

    Write-LogFunctionEntry

    $service = Get-Service -Name ShellHWDetection -ErrorAction SilentlyContinue
    if (-not $service)
    {
        Write-Verbose "The service 'ShellHWDetection' is not installed, exiting."
        Write-LogFunctionExit
        return
    }

    Write-Verbose 'Stopping the ShellHWDetection service (Shell Hardware Detection) to prevent the OS from responding to the new disks.'

    $retries = 5
    while ($retries -gt 0 -and ((Get-Service -Name ShellHWDetection).Status -ne 'Stopped'))
    {
        Write-Debug -Message 'Trying to stop ShellHWDetection'
        
        Stop-Service -Name ShellHWDetection | Out-Null
        Start-Sleep -Seconds 1
        if ((Get-Service -Name ShellHWDetection).Status -eq 'Running')
        {
            Write-Debug -Message "Could not stop service ShellHWDetection. Retrying."
            Start-Sleep -Seconds 5
        }
        $retries--
    }

    Write-LogFunctionExit
}	

function Start-ShellHWDetectionService
{
	# .ExternalHelp AutomatedLab.Help.xml

    Write-LogFunctionEntry

    $service = Get-Service -Name ShellHWDetection -ErrorAction SilentlyContinue
    if (-not $service)
    {
        Write-Verbose "The service 'ShellHWDetection' is not installed, exiting."
        Write-LogFunctionExit
        return
    }

	if ((Get-Service -Name ShellHWDetection).Status -eq 'Running')
    {
        Write-Verbose -Message "'ShellHWDetection' Service is already running."
        Write-LogFunctionExit
        return
    }
    
    Write-Verbose 'Starting the ShellHWDetection service (Shell Hardware Detection) again.'

    $retries = 5
    while ($retries -gt 0 -and ((Get-Service -Name ShellHWDetection).Status -ne 'Running'))
    {
        Write-Debug -Message 'Trying to start ShellHWDetection'
        Start-Service -Name ShellHWDetection -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
        if ((Get-Service -Name ShellHWDetection).Status -ne 'Running')
        {
            Write-Debug -Message 'Could not start service ShellHWDetection. Retrying.'
            Start-Sleep -Seconds 5
        }
        $retries--
    }

    Write-LogFunctionExit
}


#region New-LabVHDX
function New-LabVHDX
{
	# .ExternalHelp AutomatedLab.Help.xml
	[cmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ByName')]
		[string[]]$Name,
		
		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'All')]
		[switch]$All
	)
	
	Write-LogFunctionEntry
	
	$lab = Get-Lab
	if (-not $lab)
	{
		Write-Error 'No definitions imported, so there is nothing to do. Please use Import-Lab first'
		return
	}
	
	Write-Verbose 'Stopping the ShellHWDetection service (Shell Hardware Detection) to prevent the OS from responding to the new disks.'
    Stop-ShellHWDetectionService
	
	if ($Name)
	{
		$disks = $lab.Disks | Where-Object Name -in $Name
	}
	else
	{
		$disks = $lab.Disks
	}
	
	if (-not $disks)
	{
		Write-Verbose 'No disks found to create. Either the given name is wrong or there is no disk defined yet'
		Write-LogFunctionExit
		return
	}
	
	$diskPath = Join-Path -Path $lab.Target.Path -ChildPath Disks
	
	foreach ($disk in $disks)
	{
		New-LWVHDX -VhdxPath (Join-Path -Path $diskPath -ChildPath ($disk.Name + '.vhdx')) -SizeInGB $disk.DiskSize -SkipInitialize:$disk.SkipInitialization
	}
	
	Write-Verbose 'Starting the ShellHWDetection service (Shell Hardware Detection) again.'
    Start-ShellHWDetectionService
    
	Write-LogFunctionExit
}
#endregion New-LabVHDX

#region Get-LabVHDX
function Get-LabVHDX
{
	# .ExternalHelp AutomatedLab.Help.xml
	[OutputType([AutomatedLab.Machine])]
	param (
		[Parameter(Mandatory = $true, ParameterSetName = 'ByName')]
		[ValidateNotNullOrEmpty()]
		[string[]]$Name,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'All')]
		[switch]$All
	)
	
	Write-LogFunctionEntry
	
	$lab = Get-Lab
	if (-not $lab)
	{
		Write-Error 'No definitions imported, so there is nothing to do. Please use Import-Lab first'
		return
	}
	
	if ($PSCmdlet.ParameterSetName -eq 'ByName')
	{
		$results = $lab.Disks | Where-Object -FilterScript {
			$_.Name -in $Name
		}
	}
	
	if ($PSCmdlet.ParameterSetName -eq 'All')
	{
		$results = $lab.Disks
	}
	
	if ($results)
	{
		$diskPath = Join-Path -Path $lab.Target.Path -ChildPath Disks
		foreach ($result in $results)
		{
			$result.Path = Join-Path -Path $diskPath -ChildPath ($result.Name + '.vhdx')
		}
		
		Write-LogFunctionExit -ReturnValue $results.ToString()
		
		return $results
	}
	else
	{
		return
	}
}
#endregion Get-LabVHDX