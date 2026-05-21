function Initialize-LWProxmoxVM
{
    <#
    .SYNOPSIS
        Initializes Windows-based Proxmox VMs after deployment.

    .DESCRIPTION
        Performs post-deployment initialization tasks on Windows-based virtual machines running on
        Proxmox VE. The function applies a set of default registry tweaks (suppressing first-logon
        animations, Server Manager auto-launch, UAC prompts and IE Enhanced Security Configuration)
        and prepares the deploy debug folder used by AutomatedLab on each target machine.

    .PARAMETER Machine
        One or more AutomatedLab.Machine objects representing the Proxmox-hosted VMs to initialize.
        Only machines whose OperatingSystemType is 'Windows' are processed.

    .PARAMETER DeployDebugPath
        Path on the target machine that is used as the AutomatedLab deploy debug folder. Defaults to
        the value of the global $AL_DeployDebugFolder variable.

    .EXAMPLE
        Initialize-LWProxmoxVM -Machine (Get-LabVM -ComputerName Server1)

        Initializes the Proxmox-hosted VM 'Server1' using the default deploy debug path.
    #>
    [Cmdletbinding()]
    Param (
        [Parameter(Mandatory)]
        [AutomatedLab.Machine[]]$Machine,

        [Parameter()]
        [string]$DeployDebugPath = $AL_DeployDebugFolder
    )

    Write-LogFunctionEntry

    $machines = $Machine | Where-Object OperatingSystemType -eq 'Windows'

    $result = Invoke-LabCommand -ActivityName "Initialize Proxmox VM" -ComputerName $machines -ScriptBlock {
        $deployDebugPath = (New-Item -ItemType Directory -Path $ExecutionContext.InvokeCommand.ExpandString($AL_DeployDebugFolder) -ErrorAction SilentlyContinue -Force).FullName

        $alPath = Join-Path -Path $deployDebugPath -ChildPath AL
        if (-not (Test-Path $alPath))
        {
            $alDir = New-Item -ItemType Directory -Path $alPath -Force
        }

        $null = reg.exe add 'HKLM\SOFTWARE\Microsoft\ServerManager\oobe' /v DoNotOpenInitialConfigurationTasksAtLogon /d 1 /t REG_DWORD /f
        $null = reg.exe add 'HKLM\SOFTWARE\Microsoft\ServerManager' /v DoNotOpenServerManagerAtLogon /d 1 /t REG_DWORD /f
        $null = reg.exe add 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' /v EnableFirstLogonAnimation /d 0 /t REG_DWORD /f
        $null = reg.exe add 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' /v FilterAdministratorToken /t REG_DWORD /d 0 /f
        $null = reg.exe add 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' /v EnableLUA /t REG_DWORD /d 0 /f
        $null = reg.exe add 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 0 /f
        $null = reg.exe add 'HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}' /v IsInstalled /t REG_DWORD /d 0 /f #disable admin IE Enhanced Security Configuration
        $null = reg.exe add 'HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}' /v IsInstalled /t REG_DWORD /d 0 /f #disable user IE Enhanced Security Configuration
        $null = reg.exe add 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' /v BgInfo /t REG_SZ /d "$alDir\BgInfo.exe $alDir\BgInfo.bgi /Timer:0 /nolicprompt" /f

        [pscustomobject]@{
            DeployDebugPath = $deployDebugPath
            AlPath = $alPath
        }

    } -Variable (Get-Variable -Name AL_DeployDebugFolder -Scope Global) -PassThru -NoDisplay

    $alCommonModule = Get-Module -ListAvailable -Name AutomatedLab.Common | Sort-Object -Property Version -Descending | Select-Object -First 1
    $alToolsPath = "$((Get-Module -Name AutomatedLabCore)[0].ModuleBase)\Tools\HyperV\*"
    $psSessions = New-LabPSSession -ComputerName $machines

    Copy-LabFileItem -Path $alToolsPath -ComputerName $machines -DestinationFolderPath $result.AlPath
    Send-ModuleToPSSession -Module $alCommonModule -Session $psSessions -IncludeDependencies -Force

    Write-ScreenInfo "Restarting machines to apply configuration changes..." -Type Verbose
    Restart-LabVM -ComputerName $machines -Wait

    Write-LogFunctionExit

}
