function Update-LabMemorySettings
{
    # Cmdlet is not called on Linux systems
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "")]
    [Cmdletbinding()]
    Param ()

    Write-LogFunctionEntry

    $machines = Get-LabVM -All -IncludeLinux | Where-Object SkipDeployment -eq $false
    $lab = Get-LabDefinition

    if ($machines | Where-Object Memory -lt 32)
    {
        $totalMemoryAlreadyReservedAndClaimed = ((Get-LWHypervVM -Name $machines.ResourceName -ErrorAction SilentlyContinue) | Measure-Object -Sum -Property MemoryStartup).Sum
        $machinesNotCreated = $machines | Where-Object { (-not (Get-LWHypervVM -Name $_.ResourceName -ErrorAction SilentlyContinue)) }

        $totalMemoryAlreadyReserved = ($machines | Where-Object { $_.Memory -ge 128 -and $_.Name -notin $machinesNotCreated.Name } | Measure-Object -Property Memory -Sum).Sum

        $totalMemory = (Get-CimInstance -Namespace Root\Cimv2 -Class win32_operatingsystem).FreePhysicalMemory * 1KB * 0.8 - $totalMemoryAlreadyReserved + $totalMemoryAlreadyReservedAndClaimed

        if ($lab.MaxMemory -ne 0 -and $lab.MaxMemory -le $totalMemory)
        {
            $totalMemory = $lab.MaxMemory
            Write-Debug -Message "Memory in lab is manually limited to: $totalmemory MB"
        }
        else
        {
            Write-Debug -Message "80% of total available (free) physical memory minus memory already reserved by machines where memory is defined: $totalmemory bytes"
        }


        $totalMemoryUnits = ($machines | Where-Object Memory -lt 32 | Measure-Object -Property Memory -Sum).Sum

        ForEach ($machine in $machines | Where-Object Memory -ge 128)
        {
            Write-Debug -Message "$($machine.Name.PadRight(20)) $($machine.Memory / 1GB)GB (set manually)"
        }

        #Test if necessary to limit memory at all
        $memoryUsagePrediction = $totalMemoryAlreadyReserved
        foreach ($machine in $machines | Where-Object Memory -lt 32)
        {
            switch ($machine.Memory)
            {
                1 { if ($lab.UseStaticMemory)
                    {
                        $memoryUsagePrediction += 768
                    }
                    else
                    {
                        $memoryUsagePrediction += 512
                    }
                }
                2 { if ($lab.UseStaticMemory)
                    {
                        $memoryUsagePrediction += 1024
                    }
                    else
                    {
                        $memoryUsagePrediction += 512
                    }
                }
                3 { if ($lab.UseStaticMemory)
                    {
                        $memoryUsagePrediction += 2048
                    }
                    else
                    {
                        $memoryUsagePrediction += 1024
                    }
                }
                4 { if ($lab.UseStaticMemory)
                    {
                        $memoryUsagePrediction += 4096
                    }
                    else
                    {
                        $memoryUsagePrediction += 1024
                    }
                }
            }
        }

        ForEach ($machine in $machines | Where-Object { $_.Memory -lt 32 -and -not (Get-LWHypervVM -Name $_.ResourceName -ErrorAction SilentlyContinue) })
        {
            $memoryCalculated = ($totalMemory / $totalMemoryUnits * $machine.Memory / 64) * 64
            if ($memoryUsagePrediction -gt $totalMemory)
            {
                $machine.Memory = $memoryCalculated
                if (-not $lab.UseStaticMemory)
                {
                    $machine.MaxMemory = $memoryCalculated * 4
                }
            }
            else
            {
                if ($lab.MaxMemory -eq 4TB)
                {
                    #If parameter UseAllMemory was used for New-LabDefinition
                    $machine.Memory = $memoryCalculated
                }
                else
                {
                    switch ($machine.Memory)
                    {
                        1 { if ($lab.UseStaticMemory)
                            {
                                $machine.Memory = 768MB
                            }
                            else
                            {
                                $machine.MinMemory = 384MB
                                $machine.Memory    = 512MB
                                $machine.MaxMemory = 1.25GB
                            }
                        }
                        2 { if ($lab.UseStaticMemory)
                            {
                                $machine.Memory = 1GB
                            }
                            else
                            {
                                $machine.MinMemory = 384MB
                                $machine.Memory    = 512MB
                                $machine.MaxMemory = 2GB
                            }
                        }
                        3 { if ($lab.UseStaticMemory)
                            {
                                $machine.Memory = 2GB
                            }
                            else
                            {
                                $machine.MinMemory = 384MB
                                $machine.Memory    = 1GB
                                $machine.MaxMemory = 4GB
                            }
                        }
                        4 { if ($lab.UseStaticMemory)
                            {
                                $machine.Memory = 4GB
                            }
                            else
                            {
                                $machine.MinMemory = 384MB
                                $machine.Memory    = 1GB
                                $machine.MaxMemory = 8GB
                            }
                        }
                    }
                }
            }
            Write-Debug -Message "$("Memory in $($machine)".PadRight(30)) $($machine.Memory / 1GB)GB (calculated)"
            if ($machine.MaxMemory)
            {
                Write-Debug -Message "$("MaxMemory in $($machine)".PadRight(30)) $($machine.MaxMemory / 1GB)GB (calculated)"
            }

            if ($memoryCalculated -lt 256)
            {
                Write-ScreenInfo -Message "Machine '$($machine.Name)' is now auto-configured with $($memoryCalculated / 1GB)GB of memory. This might give unsatisfactory performance. Consider adding memory to the host, raising the available memory for this lab or use fewer machines in this lab" -Type Warning
            }
        }
    }

    Write-LogFunctionExit
}
