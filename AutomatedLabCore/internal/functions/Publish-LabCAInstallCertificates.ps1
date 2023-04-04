function Publish-LabCAInstallCertificates
{

    param (
        [switch]$PassThru
    )

    #Install the certificates to all machines in lab

    Write-LogFunctionEntry

    $targetMachines = @()

    #Publish to all Root DC machines (only one DC from each Root domain)
    $targetMachines += Get-LabVM -All -IsRunning | Where-Object { ($_.Roles.Name -eq 'RootDC') -or ($_.Roles.Name -eq 'FirstChildDC') }

    #Also publish to any machines not domain joined
    $targetMachines += Get-LabVM -All -IsRunning | Where-Object { -not $_.IsDomainJoined }
    Write-PSFMessage -Message "Target machines for publishing: '$($targetMachines -join ', ')'"

    $machinesNotTargeted = Get-LabVM -All | Where-Object { $_.Roles.Name -notcontains 'RootDC' -and $_.Name -notin $targetMachines.Name -and -not $_.IsDomainJoined }

    if ($machinesNotTargeted)
    {
        Write-ScreenInfo -Message 'The following machines are not updated with Root and Subordinate certificates from the newly installed Root and Subordinate certificate servers. Please update these manually.' -Type Warning
        $machinesNotTargeted | ForEach-Object { Write-ScreenInfo -Message "  $_" -Type Warning }
    }

    foreach ($machine in $targetMachines)
    {
        $machineSession = New-LabPSSession -ComputerName $machine
        foreach ($certfile in (Get-ChildItem -Path "$((Get-Lab).LabPath)\Certificates"))
        {
            Write-PSFMessage -Message "Send file '$($certfile.FullName)' to 'C:\Windows\$($certfile.BaseName).crt'"
            Send-File -SourceFilePath $certfile.FullName -DestinationFolderPath /Windows -Session $machineSession
        }

        $scriptBlock = {
            foreach ($certfile in (Get-ChildItem -Path 'C:\Windows\*.crt'))
            {
                Write-Verbose -Message "Install certificate ($((Get-PfxCertificate $certfile.FullName).Subject)) on machine $(hostname)"
                #If workgroup, publish to local store
                $domJoined = if (Get-Command Get-CimInstance -ErrorAction SilentlyContinue)
                {
                    (Get-CimInstance -Namespace root\cimv2 -Class Win32_ComputerSystem).DomainRole -eq 2
                }
                else
                {
                    (Get-WmiObject -Namespace root\cimv2 -Class Win32_ComputerSystem).DomainRole -eq 2
                }

                if ($domJoined)
                {
                    Write-Verbose -Message '  Machine is not domain joined. Publishing certificate to local store'

                    $Cert = Get-PfxCertificate $certfile.FullName
                    if ($Cert.GetNameInfo('SimpleName', $false) -eq $Cert.GetNameInfo('SimpleName', $true))
                    {
                        $targetStore = 'Root'
                    }
                    else
                    {
                        $targetStore = 'CA'
                    }

                    if (-not (Get-ChildItem -Path "Cert:\LocalMachine\$targetStore" | Where-Object { $_.ThumbPrint -eq (Get-PfxCertificate $($certfile.FullName)).ThumbPrint }))
                    {
                        $result = Invoke-Expression -Command "certutil -addstore -f $targetStore c:\Windows\$($certfile.BaseName).crt"

                        if ($result | Where-Object { $_ -like '*already in store*' })
                        {
                            Write-Verbose -Message "  Certificate ($((Get-PfxCertificate $certfile.FullName).Subject)) is already in local store on $(hostname)"
                        }
                        elseif ($result | Where-Object { $_ -like '*added to store.' })
                        {
                            Write-Verbose -Message "  Certificate ($((Get-PfxCertificate $certfile.FullName).Subject)) added to local store on $(hostname)"
                        }
                        else
                        {
                            Write-Error -Message "Certificate ($((Get-PfxCertificate $certfile.FullName).Subject)) was not added to local store on $(hostname)"
                        }
                    }
                    else
                    {
                        Write-Verbose -Message "  Certificate ($((Get-PfxCertificate $certfile.FullName).Subject)) is already in local store on $(hostname)"
                    }
                }
                else #If domain joined, publish to AD Enterprise store
                {
                    Write-Verbose -Message '  Machine is domain controller. Publishing certificate to AD Enterprise store'

                    if (((Get-PfxCertificate $($certfile.FullName)).Subject) -like '*root*')
                    {
                        $dsPublishStoreName = 'RootCA'
                        $readStoreName = 'Root'
                    }
                    else
                    {
                        $dsPublishStoreName = 'SubCA'
                        $readStoreName = 'CA'
                    }


                    if (-not (Get-ChildItem "Cert:\LocalMachine\$readStoreName" | Where-Object { $_.ThumbPrint -eq (Get-PfxCertificate $($certfile.FullName)).ThumbPrint }))
                    {
                        $result = Invoke-Expression -Command "certutil -f -dspublish c:\Windows\$($certfile.BaseName).crt $dsPublishStoreName"

                        if ($result | Where-Object { $_ -like '*Certificate added to DS store*' })
                        {
                            Write-Verbose -Message "  Certificate ($((Get-PfxCertificate $certfile.FullName).Subject)) added to DS store on $(hostname)"
                        }
                        elseif ($result | Where-Object { $_ -like '*Certificate already in DS store*' })
                        {
                            Write-Verbose -Message "  Certificate ($((Get-PfxCertificate $certfile.FullName).Subject)) is already in DS store on $(hostname)"
                        }
                        else
                        {
                            Write-Error -Message "Certificate ($((Get-PfxCertificate $certfile.FullName).Subject)) was not added to DS store on $(hostname)"
                        }
                    }
                    else
                    {
                        Write-Verbose -Message "  Certificate ($((Get-PfxCertificate $certfile.FullName).Subject)) is already in DS store on $(hostname)"
                    }
                }
            }
        }

        $job = Invoke-LabCommand -ActivityName 'Publish Lab CA(s) and install certificates' -ComputerName $machine -ScriptBlock $scriptBlock -NoDisplay -AsJob -PassThru
        if ($PassThru) { $job }
    }

    Write-LogFunctionExit
}
