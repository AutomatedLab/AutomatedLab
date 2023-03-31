function Install-LabCA
{

    [cmdletBinding()]
    param ([switch]$CreateCheckPoints)

    Write-LogFunctionEntry

    $roles = [AutomatedLab.Roles]::CaRoot -bor [AutomatedLab.Roles]::CaSubordinate

    $lab = Get-Lab
    if (-not $lab.Machines)
    {
        Write-LogFunctionExitWithError -Message 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }

    $machines = Get-LabVM -Role CaRoot, CaSubordinate
    if (-not $machines)
    {
        Write-ScreenInfo -Message 'There is no machine(s) with CA role' -Type Warning
        return
    }

    if (-not (Get-LabVM -Role CaRoot))
    {
        Write-ScreenInfo -Message 'Subordinate CA(s) defined but lab has no Root CA(s) defined. Skipping installation of CA(s).' -Type Error
        return
    }

    if ((Get-LabVM -Role CaRoot).Name)
    {
        Write-ScreenInfo -Message "Machines with Root CA role to be installed: '$((Get-LabVM -Role CaRoot).Name -join ', ')'" -TaskStart
    }

    #Bring the RootCA server online and start installing
    Write-ScreenInfo -Message 'Waiting for machines to start up' -NoNewline

    Start-LabVM -RoleName CaRoot, CaSubordinate -Wait -ProgressIndicator 15

    $caRootMachines = Get-LabVM -Role CaRoot -IsRunning
    if ($caRootMachines.Count -ne (Get-LabVM -Role CaRoot).Count)
    {
        Write-Error 'Not all machines of type Root CA could be started, aborting the installation'
        return
    }

    $installSequence = 0
    $jobs = @()
    foreach ($caRootMachine in $caRootMachines)
    {
        $caFeature = Invoke-LabCommand -ComputerName $caRootMachine -ActivityName "Check if CA is already installed on '$caRootMachine'" -ScriptBlock { (Get-WindowsFeature -Name 'ADCS-Cert-Authority') } -PassThru -NoDisplay
        if ($caFeature.Installed)
        {
            Write-ScreenInfo -Message "Root CA '$caRootMachine' is already installed" -Type Warning
        }
        else
        {
            $jobs += Install-LabCAMachine -Machine $caRootMachine -PassThru -PreDelaySeconds ($installSequence++*30)
        }
    }

    if ($jobs)
    {
        Write-ScreenInfo -Message 'Waiting for Root CA(s) to complete installation' -NoNewline

        Wait-LWLabJob -Job $jobs -ProgressIndicator 10 -NoDisplay

        Write-PSFMessage -Message "Getting certificates from Root CA servers and placing them in '<labfolder>\Certs' on host machine"
        Get-LabVM -Role CaRoot | Get-LabCAInstallCertificates

        Write-ScreenInfo -Message 'Publishing certificates from CA servers to all online machines' -NoNewLine
        $jobs = Publish-LabCAInstallCertificates -PassThru
        Wait-LWLabJob -Job $jobs -ProgressIndicator 20 -Timeout 30 -NoNewLine -NoDisplay

        Write-PSFMessage -Message 'Waiting for all running machines to be contactable'
        Wait-LabVM -ComputerName (Get-LabVM -All -IsRunning) -ProgressIndicator 20 -NoNewLine

        Write-PSFMessage -Message 'Invoking a GPUpdate on all running machines'
        $jobs = Invoke-LabCommand -ActivityName 'GPUpdate after Root CA install' -ComputerName (Get-LabVM -All -IsRunning) -ScriptBlock {
            gpupdate.exe /force
        } -AsJob -PassThru -NoDisplay
        Wait-LWLabJob -Job $jobs -ProgressIndicator 20 -Timeout 30 -NoDisplay
    }

    Write-ScreenInfo -Message 'Finished installation of Root CAs' -TaskEnd

    #If any Subordinate CA servers to install, bring these online and start installing
    if ($machines | Where-Object { $_.Roles.Name -eq ([AutomatedLab.Roles]::CaSubordinate) })
    {
        $caSubordinateMachines = Get-LabVM -Role CaSubordinate -IsRunning
        if ($caSubordinateMachines.Count -ne (Get-LabVM -Role CaSubordinate).Count)
        {
            Write-Error 'Not all machines of type CaSubordinate could be started, aborting the installation'
            return
        }

        Write-ScreenInfo -Message "Machines with Subordinate CA role to be installed: '$($caSubordinateMachines -join ', ')'" -TaskStart


        Write-ScreenInfo -Message 'Waiting for machines to start up' -NoNewline
        Wait-LabVM -ComputerName (Get-LabVM -Role CaSubordinate).Name -ProgressIndicator 10

        $installSequence = 0
        $jobs = @()
        foreach ($caSubordinateMachine in $caSubordinateMachines)
        {
            $caFeature = Invoke-LabCommand -ComputerName $caSubordinateMachine -ActivityName "Check if CA is already installed on '$caSubordinateMachine'" -ScriptBlock { (Get-WindowsFeature -Name 'ADCS-Cert-Authority') } -PassThru -NoDisplay
            if ($caFeature.Installed)
            {
                Write-ScreenInfo -Message "Subordinate CA '$caSubordinateMachine' is already installed" -Type Warning
            }
            else
            {
                $jobs += Install-LabCAMachine -Machine $caSubordinateMachine -PassThru -PreDelaySeconds ($installSequence++ * 30)
            }
        }

        if ($Jobs)
        {
            Write-ScreenInfo -Message 'Waiting for Subordinate CA(s) to complete installation' -NoNewline

            Start-LabVM -StartNextMachines 1

            Wait-LWLabJob -Job $jobs -ProgressIndicator 20 -NoNewLine -NoDisplay

            Write-PSFMessage -Message "- Getting certificates from CA servers and placing them in '<labfolder>\Certs' on host machine"
            Get-LabVM -Role CaRoot, CaSubordinate | Get-LabCAInstallCertificates

            Write-PSFMessage -Message '- Publishing certificates from Subordinate CA servers to all online machines'
            $jobs = Publish-LabCAInstallCertificates -PassThru
            Wait-LWLabJob -Job $jobs -ProgressIndicator 20 -Timeout 30 -NoNewLine -NoDisplay

            Write-PSFMessage -Message 'Invoking a GPUpdate on all machines that are online'
            $jobs = Invoke-LabCommand -ComputerName (Get-LabVM -All -IsRunning) -ActivityName 'GPUpdate after Root CA install' -NoDisplay -ScriptBlock { gpupdate.exe /force } -AsJob -PassThru
            Wait-LWLabJob -Job $jobs -ProgressIndicator 20 -Timeout 30 -NoDisplay
        }

        Invoke-LabCommand -ComputerName $caRootMachines -NoDisplay -ScriptBlock {
            certutil.exe -setreg ca\PolicyModules\CertificateAuthority_MicrosoftDefault.Policy\RequestDisposition 101
            Restart-Service -Name CertSvc
        }

        Write-ScreenInfo -Message 'Finished installation of Subordinate CAs' -TaskEnd
    }


    Write-LogFunctionExit
}
