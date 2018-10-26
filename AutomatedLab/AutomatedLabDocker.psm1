#region Install-LabDocker
function Install-LabDocker
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding()]
    param (
        [int]$InstallationTimeout = 15
    )
    
    Write-LogFunctionEntry

    $roleName = [AutomatedLab.Roles]::Docker

    if (-not (Get-LabVM))
    {
        Write-ScreenInfo -Message 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first'
        Write-LogFunctionExit
        return
    }

    $machines = Get-LabVM -Role $roleName    
    if (-not $machines)
    {
        Write-ScreenInfo -Message "No machines with the role '$roleName' defined in this lab, so there is nothing to do"
        Write-LogFunctionExit
        return
    }

    $windowsMachines = $machines | Where-Object OperatingSystemType -eq 'Windows'
    $linuxMachines = $machines | Where-Object OperatingSystemType -eq 'Linux'

    if ($windowsMachines)
    {
        Install-LabDockerForWindows -Machines $windowsMachines
    }

    if ($linuxMachines)
    {
        Write-Error -Exception (New-Object System.NotImplementedException)
    }
    
    Write-LogFunctionExit
}
#endregion Install-LabDocker

function Install-LabDockerForWindows
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [AutomatedLab.Machine[]]$Machines,

        [int]$InstallationTimeout = 15
    )

    Write-LogFunctionEntry

    Write-ScreenInfo "Setting ExposeVirtualizationExtensions on machines '$($Machines.Name -join ', ')'" 
    Get-VM -Name $Machines | Set-VMProcessor -ExposeVirtualizationExtensions $true

    Write-ScreenInfo 'Starting Docker servers and waiting until they are ready' -NoNewLine
    Start-LabVM -RoleName Docker -ProgressIndicator 15 -Wait

    Write-ScreenInfo "Installing the features 'Hyper-V, Containers' on machines '$($Machines.Name -join ', ')'"
    Install-LabWindowsFeature -ComputerName $Machines -FeatureName Hyper-V, Containers -IncludeAllSubFeature -IncludeManagementTools -NoDisplay
    Restart-LabVM -ComputerName $Machines -Wait #A restart is required by the Hyper-V installer
    #Start-Sleep -Seconds 5
    #Wait-LabVMRestart -ComputerName $Machines -TimeoutInMinutes 2 #As the Hyper-V installation does another restart

    $dockerForWindowsDownloadUri = (Get-Module AutomatedLab).PrivateData.DockerForWindowsDownloadUri

    $dockerInstallFile = Get-LabInternetFile -Uri $dockerForWindowsDownloadUri -Path $global:labSources\SoftwarePackages -PassThru

    Write-ScreenInfo "Installing Docker for Windows in $($Machines.Count) machines." -NoNewLine
    $installJob = Install-LabSoftwarePackage -Path $dockerInstallFile.FullName -CommandLine 'install --quiet' -ComputerName $Machines -UseShellExecute -AsJob -PassThru -NoDisplay
    Wait-LWLabJob -Job $installJob -ProgressIndicator 10 -Timeout $InstallationTimeout

    Restart-LabVM -ComputerName $Machines -Wait

    Invoke-LabCommand -ActivityName 'Switching Docker to use Windows Containers' -ComputerName $Machines -ScriptBlock {
        
        $result = docker info *>&1 | Out-String
        while ($result -match 'docker : error during connect|Error response from daemon: An invalid argument was supplied')
        {
            $result = docker info *>&1 | Out-String
        }

        & $Env:ProgramFiles\Docker\Docker\DockerCli.exe -SwitchWindowsEngine

        if (-not (docker info | Where-Object { $_ -like '*OSType: windows*' }))
        {
            & $Env:ProgramFiles\Docker\Docker\DockerCli.exe -SwitchWindowsEngine
        }

        if (-not (docker info | Where-Object { $_ -like '*OSType: windows*' }))
        {
            Write-Error "Failed to switch docker to Windows Containers on on '$(HOSTNAME.EXE)'"
        }
    }

    foreach ($machine in $Machines)
    {
        $role = $machine.Roles | Where-Object Name -eq 'Docker'
        if ($role.Properties.DataRoot)
        {
            $dataRoot = $role.Properties.DataRoot
            Invoke-LabCommand -ActivityName 'Setting docker data-root' -ComputerName $machine -ScriptBlock {
                if (-not (Test-Path -Path $dataRoot))
                {
                    mkdir -Path $dataRoot
                }
            
                $daemonConfig = Get-Content -Path C:\ProgramData\Docker\config\daemon.json | ConvertFrom-Json
                if ($daemonConfig.'data-root')
                {
                    $daemonConfig.'data-root' = $dataRoot
                }
                else
                {
                    $daemonConfig | Add-Member -Name data-root -MemberType NoteProperty -Value $dataRoot
                }
                $daemonConfig | ConvertTo-Json | Out-File -FilePath C:\ProgramData\Docker\config\daemon.json
            } -Variable (Get-Variable -Name dataRoot)
        }
    }

    Restart-LabVM -ComputerName $Machines -Wait

    Write-LogFunctionExit
}

function Add-LabDockerImage
{
    [cmdletBinding(DefaultParameterSetName = 'FromLocalFile')]
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName,

        [Parameter(Mandatory, ParameterSetName = 'FromLocalFile')]
        [string]$Path,

        [Parameter(Mandatory, ParameterSetName = 'FromInternet')]
        [string]$ImageName,

        [switch]$PassThru
    )

    Write-LogFunctionEntry

    if ($PSCmdlet.ParameterSetName -eq 'FromLocalFile')
    {
        Copy-LabFileItem -Path $Path -ComputerName $ComputerName -DestinationFolderPath C:\
        $Path = "C:\$(Split-Path -Path $Path -Leaf)"
    }

    $variables = Get-Variable -Name Path, ImageName

    Invoke-LabCommand -ActivityName "Adding Docker image" -ComputerName $computerName -ScriptBlock {
        $Name = $args[0]
        $Path = $args[1]
        Set-Location -Path C:\
        if ($Path)
        {
            docker load -i $Path
        }
        else
        {
            docker pull $ImageName
        }

        docker images 

        Remove-Item -Path $Path -Force

    } -ArgumentList $Name, $Path -NoDisplay

    if ($PassThru)
    {
        Get-LabDockerImage -ComputerName $ComputerName
    }

    Write-LogFunctionExit
}

function Get-LabDockerImage
{
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName
    )

    Write-LogFunctionEntry

    Invoke-LabCommand -ActivityName "Get Docker image" -ComputerName $computerName -ScriptBlock {

        docker images --format "table {{.Repository}}|{{.Tag}}|{{.ID}}|{{.CreatedAt}}|{{.Size}}" | ConvertFrom-Csv -Delimiter '|'

    } -NoDisplay -PassThru

    Write-LogFunctionExit
}

function Remove-LabDockerImage
{
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName,

        [Parameter(Mandatory)]
        [string]$ImageName
    )

    Write-LogFunctionEntry

    $image = Get-LabDockerImage -ComputerName $ComputerName | Where-Object Repository -eq $ImageName
    if (-not $image)
    {
        Write-Error "The Docker image with the name '$ImageName' could not be found"
        return
    }

    Invoke-LabCommand -ActivityName "Get Docker image" -ComputerName $computerName -ScriptBlock {
        $id = $args[0]        
        
        docker rmi $id -f

    } -ArgumentList $image.'IMAGE ID' -NoDisplay

    Write-LogFunctionExit
}

function Get-LabDockerContainer
{
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName
    )

    Write-LogFunctionEntry

    Invoke-LabCommand -ActivityName "Get Docker containers" -ComputerName $computerName -ScriptBlock {

        docker ps --all --format "table {{.ID}}|{{.Image}}|{{.Command}}|{{.CreatedAt}}|{{.Status}}|{{.Ports}}" | ConvertFrom-Csv -Delimiter '|'

    } -NoDisplay -PassThru

    Write-LogFunctionExit
}

function Stop-LabDockerContainer
{
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName,

        [Parameter(Mandatory, ParameterSetName = 'ByImageName')]
        [string]$ImageName,

        [Parameter(Mandatory, ParameterSetName = 'ByContainerId')]
        [string]$ContainerId
    )

    Write-LogFunctionEntry

    $containers = if ($ImageName)
    {
        Get-LabDockerContainer -ComputerName $ComputerName | Where-Object Image -eq $ImageName
    }
    else
    {
        Get-LabDockerContainer -ComputerName $ComputerName | Where-Object { $_.'Container Id' -eq $ContainerId }
    }

    if (-not $containers)
    {
        Write-Error "The Docker image with the name '$ImageName' could not be found"
        return
    }

    Invoke-LabCommand -ActivityName "Stopping Docker Container" -ComputerName $computerName -ScriptBlock {
        $containers = $args
        
        foreach ($container in $containers)
        {
            docker stop $container.'CONTAINER ID'
        }

    } -ArgumentList $containers -NoDisplay

    Write-LogFunctionExit
}

function Start-LabDockerContainer
{
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName,

        [Parameter(Mandatory, ParameterSetName = 'ByImageName')]
        [string]$ImageName,

        [Parameter(Mandatory, ParameterSetName = 'ByContainerId')]
        [string]$ContainerId
    )

    Write-LogFunctionEntry

    $containers = if ($ImageName)
    {
        Get-LabDockerContainer -ComputerName $ComputerName | Where-Object Image -eq $ImageName
    }
    else
    {
        Get-LabDockerContainer -ComputerName $ComputerName | Where-Object { $_.'Container Id' -eq $ContainerId }
    }

    if (-not $containers)
    {
        Write-Error "The Docker image with the name '$ImageName' could not be found"
        return
    }

    Invoke-LabCommand -ActivityName "Starting Docker Container" -ComputerName $computerName -ScriptBlock {
        $containers = $args
        
        foreach ($Container in $containers)
        {
            docker start $Container.'CONTAINER ID'
        }

    } -ArgumentList $containers -NoDisplay

    Write-LogFunctionExit
}

function Remove-LabDockerContainer
{
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName,

        [Parameter(Mandatory, ParameterSetName = 'ByImageName')]
        [string]$ImageName,

        [Parameter(Mandatory, ParameterSetName = 'ByContainerId')]
        [string]$ContainerId
    )

    Write-LogFunctionEntry

    $containers = if ($ImageName)
    {
        Get-LabDockerContainer -ComputerName $ComputerName | Where-Object Image -eq $ImageName
    }
    else
    {
        Get-LabDockerContainer -ComputerName $ComputerName | Where-Object { $_.'Container Id' -eq $ContainerId }
    }

    if (-not $containers)
    {
        Write-Error "The Docker image with the name '$ImageName' could not be found"
        return
    }

    Invoke-LabCommand -ActivityName "Removing Docker Container" -ComputerName $computerName -ScriptBlock {
        $containers = $args
        
        foreach ($Container in $containers)
        {
            docker rm $Container.'CONTAINER ID'
        }

    } -ArgumentList $containers -NoDisplay

    Write-LogFunctionExit
}

function New-LabDockerImage
{
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$Path,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$ImageName
    )

    begin
    {
        Write-LogFunctionEntry
    }

    process
    {
        if (-not (Test-Path -Path $Path -PathType Container))
        {
            Write-Error "The path '$Path' does not exist"
            return
        }
        if (-not (Get-ChildItem -Path $Path -Filter dockerfile))
        {
            Write-Error "There is no dockerfile in the path '$Path'. This file is required."
            return
        }

        Copy-LabFileItem -Path $Path -ComputerName $ComputerName -DestinationFolderPath C:\
        $Path = "C:\$(Split-Path -Path $Path -Leaf)"
        if (-not $ImageName)
        {
            $ImageName = Split-Path -Path $Path -Leaf
        }

        Invoke-LabCommand -ActivityName "Creating new Docker image" -ComputerName $computerName -ScriptBlock {
            $path = $args[0]
            $imageName = $args[1]
            Set-Location -Path $path
            docker build -t $imageName.ToLower() .

            Remove-Item -Path $path -Recurse -Force
        
        } -ArgumentList $Path, $ImageName -NoDisplay
    }

    end
    {
        Write-LogFunctionExit
    }
}