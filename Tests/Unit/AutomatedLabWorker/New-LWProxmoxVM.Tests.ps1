Describe 'New-LWProxmoxVM' {
    BeforeAll {
        # New-LWProxmoxVM binds an [AutomatedLab.Machine]. Without the LabXml assembly the test compiles a
        # stand-in type, which only a process of its own may hold: .NET cannot unload a type, and later
        # tests in this run would otherwise resolve AutomatedLab.Machine to the stand-in.
        function Invoke-CloneInChildProcess
        {
            param
            (
                [string]$TargetNode,

                [string]$WaitResult = 'OK'
            )

            $functionPath = Join-Path $PSScriptRoot '..\..\..\AutomatedLabWorker\functions\ProxmoxWorkerVirtualMachines\New-LWProxmoxVM.ps1'
            $helperPath = Join-Path $PSScriptRoot '..\..\..\AutomatedLabWorker\functions\Internals\ConvertTo-LWProxmoxTaskResultText.ps1'
            $childScript = @'
Add-Type -TypeDefinition @"
namespace AutomatedLab
{
    public class Machine
    {
        public string Name { get; set; }
        public string ResourceName { get; set; }
        public bool SkipDeployment { get; set; }
        public string OperatingSystem { get; set; }
        public int Processors { get; set; }
        public long Memory { get; set; }
        public long MaxMemory { get; set; }
        public long MinMemory { get; set; }
        public System.Collections.Hashtable ProxmoxProperties { get; set; }
        public override string ToString() { return Name; }
    }
}
"@
. '__FUNCTIONPATH__'
. '__HELPERPATH__'

function Write-LogFunctionEntry {}
function Write-LogFunctionExit {}
function Write-ProgressIndicatorEnd {}
function Write-PSFMessage { param ($Message, $Level) }
function Write-ScreenInfo { param ($Message, $Type) }
function Get-Lab { [pscustomobject]@{ Name = 'TestLab' } }
function Get-LabConfigurationItem { param ($Name) }
function Export-Lab {}
function mkdir { param ($Path, [switch]$Force) }
function Get-LWProxmoxNode { @([pscustomobject]@{ node = 'pve1' }, [pscustomobject]@{ node = 'pve2' }) }
function Get-LWProxmoxVM
{
    param ([Alias('Name')][string[]]$ComputerName, [object[]]$Node, [switch]$NoError, [switch]$IncludeTemplates, [switch]$NoCache)
    [pscustomobject]@{ Name = 'Template'; vmid = 9000; node = 'pve1'; template = 1 }
}
function Get-LWProxmoxVmTemplate
{
    param ([Parameter(ValueFromPipeline)][object]$Node, [string]$OperatingSystem)
    end { [pscustomobject]@{ Name = 'Template'; vmid = 9000; node = 'pve1' } }
}
function Wait-LWProxmoxTasksStatus { param ($Node, $Upid, $DesiredValues, $TimeoutInSeconds) '__WAITRESULT__' }
function Invoke-LWProxmoxCallWithRetry
{
    param ([scriptblock]$ScriptBlock, [string]$ActivityName, [int]$RetryDelaySeconds)
    if ($ActivityName -like 'Retrieve storage*')
    {
        return [pscustomobject]@{ StatusCode = 200; Response = [pscustomobject]@{ data = @([pscustomobject]@{ storage = 'local-lvm'; type = 'lvm' }) } }
    }
    if ($ActivityName -like 'Clone VM*')
    {
        $script:cloneRequested = $true
        return [pscustomobject]@{ StatusCode = 200; Response = [pscustomobject]@{ data = 'UPID:clone' } }
    }
    # The first call after the clone fails, so the function returns before it needs more stubs
    [pscustomobject]@{ StatusCode = 500; ReasonPhrase = 'Not part of this test' }
}

$script:proxmoxVmCache = @{ pve1 = @(); pve2 = @() }
$script:cloneRequested = $false
$proxmoxProperties = @{}
if ('__TARGETNODE__') { $proxmoxProperties.TargetNode = '__TARGETNODE__' }
$machine = [AutomatedLab.Machine]@{ Name = 'VM1'; ResourceName = 'VM1'; OperatingSystem = 'Windows Server 2022'; Processors = 2; Memory = 4GB; ProxmoxProperties = $proxmoxProperties }
$null = New-LWProxmoxVM -Machine $machine -ErrorAction SilentlyContinue -ErrorVariable cloneErrors
'CLONE-REQUESTED=' + $script:cloneRequested
'CACHED-NODES=' + (($script:proxmoxVmCache.Keys | Sort-Object) -join ',')
foreach ($cloneError in $cloneErrors) { 'CLONE-ERROR=' + $cloneError.Exception.Message }
'@
            $childScript = $childScript.Replace('__FUNCTIONPATH__', $functionPath.Replace("'", "''")).Replace('__HELPERPATH__', $helperPath.Replace("'", "''"))
            $childScript = $childScript.Replace('__TARGETNODE__', $TargetNode).Replace('__WAITRESULT__', $WaitResult.Replace("'", "''"))
            $encodedScript = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($childScript))
            $powershellPath = (Get-Process -Id $PID).Path

            & $powershellPath -NoProfile -NonInteractive -EncodedCommand $encodedScript 2>&1 | ForEach-Object { "$_" }
        }
    }

    It 'drops the cache entry of the target node after a successful clone' {
        $output = Invoke-CloneInChildProcess -TargetNode 'pve2'

        $output | Should -Contain 'CLONE-REQUESTED=True' -Because ($output -join [Environment]::NewLine)
        $output | Where-Object { $_ -like 'CACHED-NODES=*' } | Should -Be 'CACHED-NODES=pve1' -Because ($output -join [Environment]::NewLine)
    }

    It 'drops the cache entry of the template node when the machine has no target node' {
        $output = Invoke-CloneInChildProcess -TargetNode ''

        $output | Should -Contain 'CLONE-REQUESTED=True' -Because ($output -join [Environment]::NewLine)
        $output | Where-Object { $_ -like 'CACHED-NODES=*' } | Should -Be 'CACHED-NODES=pve2' -Because ($output -join [Environment]::NewLine)
    }

    It 'names the Proxmox task text, the node, the VMID and the task in the error of a failed clone' {
        $taskText = "clone failed: rbd clone 'base-701-disk-1' error: rbd: clone error: (17) File exists"

        $output = Invoke-CloneInChildProcess -TargetNode '' -WaitResult $taskText

        $errorLines = @($output | Where-Object { $_ -like 'CLONE-ERROR=Failed to create VM*' })
        $errorLines.Count | Should -Be 1 -Because ($output -join [Environment]::NewLine)
        $errorLines[0] | Should -Match ([regex]::Escape($taskText))
        $errorLines[0] | Should -Match "node 'pve1'"
        $errorLines[0] | Should -Match 'VMID 9001'
        $errorLines[0] | Should -Match 'UPID:clone'
    }
}
