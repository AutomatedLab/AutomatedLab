function Install-LabOrchestrator2012
{
    [cmdletBinding()]
    param ()

    Write-LogFunctionEntry

    #region prepare setup script
    function Install-LabPrivateOrchestratorRole
    {
        param (
            [Parameter(Mandatory)]
            [string]$OrchServiceUser,

            [Parameter(Mandatory)]
            [string]$OrchServiceUserPassword,

            [Parameter(Mandatory)]
            [string]$SqlServer,

            [Parameter(Mandatory)]
            [string]$SqlDbName
        )

        Write-Verbose -Message 'Installing Orchestrator'

        $start = Get-Date

        if (-not ((Get-WindowsFeature -Name NET-Framework-Features).Installed))
        {
            Write-Error "The WindowsFeature 'NET-Framework-Features' must be installed prior of installing Orchestrator. Use the cmdlet 'Install-LabWindowsFeature' to install the missing feature."
            return
        }

        $TimeoutInMinutes = 15
        $productName = 'Orchestrator 2012'
        $installProcessName = 'Setup'
        $installProcessDescription = 'Orchestrator Setup'
        $drive = (Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DriveType = 5').DeviceID
        $computerDomain = [System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain().Name
        $cmd = "$drive\Setup\Setup.exe /Silent /ServiceUserName:$computerDomain\$OrchServiceUser /ServicePassword:$OrchServiceUserPassword /Components:All /DbServer:$SqlServer /DbNameNew:$SqlDbName /WebServicePort:81 /WebConsolePort:82 /OrchestratorRemote /SendCEIPReports:0 /EnableErrorReporting:never /UseMicrosoftUpdate:0"

        Write-Verbose 'Logs can be found here: C:\Users\<UserName>\AppData\Local\Microsoft System Center 2012\Orchestrator\Logs'

        #--------------------------------------------------------------------------------------

        Write-Verbose "Starting setup of '$productName' with the following command"
        Write-Verbose "`t$cmd"
        Write-Verbose "The timeout is $timeoutInMinutes minutes"

        Invoke-Expression -Command $cmd
        Start-Sleep -Milliseconds 500

        $timeout = Get-Date

        $queryExpression = "`$_.Name -eq '$installProcessName'"
        if ($installProcessDescription)
        {
            $queryExpression += "-and `$_.Description -eq '$installProcessDescription'"
        }
        $queryExpression = [scriptblock]::Create($queryExpression)

        Write-Verbose 'Query expression for looking for the setup process:'
        Write-Verbose "`t$queryExpression"

        if (-not (Get-Process | Where-Object $queryExpression))
        {
            Write-Error "Installation of '$productName' did not start"
            return
        }
        else
        {
            $p = Get-Process | Where-Object $queryExpression
            Write-Verbose "Installation process is '$($p.Name)' with ID $($p.Id)"
        }

        while (Get-Process | Where-Object $queryExpression)
        {
            if ((Get-Date).AddMinutes(- $TimeoutInMinutes) -gt $start)
            {
                Write-Error "Installation of '$productName' hit the timeout of 30 minutes. Killing the setup process"

                if ($installProcessDescription)
                {
                    Get-Process |
                    Where-Object  { $_.Name -eq $installProcessName -and $_.Description -eq 'Orchestrator Setup' } |
                    Stop-Process -Force
                }
                else
                {
                    Get-Process -Name $installProcessName | Stop-Process -Force
                }

                Write-Error "Installation of $productName was not successfull"
                return
            }

            Start-Sleep -Seconds 10
        }

        $end = Get-Date
        Write-Verbose "Installation finished in $($end - $start)"
    }
    #endregion

    $roleName = [AutomatedLab.Roles]::Orchestrator2012

    if (-not (Get-LabVM))
    {
        Write-LogFunctionExitWithError -Message 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }

    $machines = Get-LabVM -Role $roleName
    if (-not $machines)
    {
        Write-LogFunctionExitWithError -Message "There is no machine with the role $roleName"
        return
    }

    $isoImage = $Script:data.Sources.ISOs | Where-Object { $_.Name -eq $roleName }
    if (-not $isoImage)
    {
        Write-LogFunctionExitWithError -Message "There is no ISO image available to install the role '$roleName'. Please add the required ISO to the lab and name it '$roleName'"
        return
    }

    Start-LabVM -RoleName $roleName -Wait

    Install-LabWindowsFeature -ComputerName $machines -FeatureName RSAT, NET-Framework-Core -Verbose:$false

    Mount-LabIsoImage -ComputerName $machines -IsoPath $isoImage.Path -SupressOutput

    foreach ($machine in $machines)
    {
        $role = $machine.Roles | Where-Object { $_.Name -eq $roleName }

        $createUserScript = "
            `$user = New-ADUser -Name $($role.Properties.ServiceAccount) -AccountPassword ('$($role.Properties.ServiceAccountPassword)' | ConvertTo-SecureString -AsPlainText -Force) -Description 'Orchestrator Service Account' -Enabled `$true -PassThru
            Get-ADGroup -Identity 'Domain Admins' | Add-ADGroupMember -Members `$user
        Get-ADGroup -Identity 'Administrators' | Add-ADGroupMember -Members `$user"

        $dc = Get-LabVM -All | Where-Object {
            $_.DomainName -eq $machine.DomainName -and
            $_.Roles.Name -in @([AutomatedLab.Roles]::DC, [AutomatedLab.Roles]::FirstChildDC, [AutomatedLab.Roles]::RootDC)
        } | Get-Random

        Write-PSFMessage "Domain controller for installation is '$($dc.Name)'"

        Invoke-LabCommand -ComputerName $dc -ScriptBlock ([scriptblock]::Create($createUserScript)) -ActivityName CreateOrchestratorServiceAccount -NoDisplay

        Invoke-LabCommand -ComputerName $machine -ActivityName Orchestrator2012Installation -NoDisplay -ScriptBlock (Get-Command Install-LabPrivateOrchestratorRole).ScriptBlock `
        -ArgumentList $Role.Properties.ServiceAccount, $Role.Properties.ServiceAccountPassword, $Role.Properties.DatabaseServer, $Role.Properties.DatabaseName
    }

    Dismount-LabIsoImage -ComputerName $machines -SupressOutput

    Write-LogFunctionExit
}
