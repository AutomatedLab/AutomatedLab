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

                # One result per clone task, the last one repeats. __NEWID__ stands for the VMID of the clone.
                [string[]]$WaitResult = @('OK'),

                # One answer per clone request: 'OK', 'NOANSWER' or the reason Proxmox refuses it with. The last one repeats.
                [string[]]$CloneAnswer = @('OK'),

                # The guests that /cluster/resources lists
                [hashtable[]]$ClusterGuest = @(@{ vmid = 9000; type = 'qemu' }),

                # The value of the configuration item ProxmoxRetryCount, empty when it is not configured
                [string]$RetryCount = '',

                # From the first refused clone on, a VM with the name of the machine exists
                [switch]$SameNameVmAfterRefusal,

                # From the first refused clone on, the guests of the cluster cannot be listed
                [switch]$ClusterListFailsAfterRefusal
            )

            $workerPath = Join-Path $PSScriptRoot '..\..\..\AutomatedLabWorker\functions'
            $settings = @{
                TargetNode             = $TargetNode
                WaitResult             = $WaitResult
                CloneAnswer            = $CloneAnswer
                ClusterGuest           = $ClusterGuest
                RetryCount             = $RetryCount
                SameNameVmAfterRefusal = $SameNameVmAfterRefusal.IsPresent
                ClusterListFailsAfterRefusal = $ClusterListFailsAfterRefusal.IsPresent
            }
            $settingsJson = ConvertTo-Json -InputObject $settings -Depth 4 -Compress

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
. '__WORKERPATH__\ProxmoxWorkerVirtualMachines\New-LWProxmoxVM.ps1'
. '__WORKERPATH__\Internals\ConvertTo-LWProxmoxTaskResultText.ps1'
. '__WORKERPATH__\Internals\Get-LWProxmoxNextVmId.ps1'
$settings = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('__SETTINGS__')) | ConvertFrom-Json

function Write-LogFunctionEntry {}
function Write-LogFunctionExit {}
function Write-ProgressIndicatorEnd {}
function Write-PSFMessage { param ($Message, $Level) }
function Write-ScreenInfo { param ($Message, $Type) }
function Get-Lab { [pscustomobject]@{ Name = 'TestLab' } }
function Get-LabConfigurationItem
{
    param ($Name)
    if ($Name -eq 'ProxmoxRetryCount' -and $settings.RetryCount) { [int]$settings.RetryCount }
}
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
function Get-PveClusterResources
{
    param ($Type)
    if ($settings.ClusterListFailsAfterRefusal -and $script:refused)
    {
        return [pscustomobject]@{ StatusCode = 500; ReasonPhrase = 'cluster list unavailable' }
    }
    $guests = @($settings.ClusterGuest)
    if ($script:sameNameVmExists) { $guests += [pscustomobject]@{ vmid = 9001; name = 'VM1'; type = 'qemu'; node = 'pve1' } }
    [pscustomobject]@{ StatusCode = 200; Response = [pscustomobject]@{ data = $guests } }
}
function New-PveNodesQemuClone
{
    param ($Node, $Name, $Description, $Vmid, $Newid, $Target, $Full, $Pool, $Storage)
    $script:cloneNewIds.Add([int]$Newid)
    $answers = @($settings.CloneAnswer)
    $answer = $answers[[Math]::Min($script:cloneNewIds.Count, $answers.Count) - 1]
    if ($answer -eq 'OK')
    {
        return [pscustomobject]@{ StatusCode = 200; Response = [pscustomobject]@{ data = 'UPID:clone' } }
    }
    if ($answer -eq 'NOANSWER')
    {
        return [pscustomobject]@{ StatusCode = -1; ReasonPhrase = 'The operation has timed out.' }
    }
    $script:refused = $true
    if ($settings.SameNameVmAfterRefusal) { $script:sameNameVmExists = $true }
    [pscustomobject]@{ StatusCode = 500; ReasonPhrase = $answer.Replace('__NEWID__', [string]$Newid) }
}
function Wait-LWProxmoxTasksStatus
{
    param ($Node, $Upid, $DesiredValues, $TimeoutInSeconds)
    $script:taskWaits++
    $results = @($settings.WaitResult)
    $results[[Math]::Min($script:taskWaits, $results.Count) - 1].Replace('__NEWID__', [string]$script:cloneNewIds[$script:cloneNewIds.Count - 1])
}
function Invoke-LWProxmoxCallWithRetry
{
    param ([scriptblock]$ScriptBlock, [string]$ActivityName, [int]$MaxRetries = 3, [int]$RetryDelaySeconds)
    if ($ActivityName -like 'Retrieve storage*')
    {
        return [pscustomobject]@{ StatusCode = 200; Response = [pscustomobject]@{ data = @([pscustomobject]@{ storage = 'local-lvm'; type = 'lvm' }) } }
    }
    # The clone and the cluster list run against the stubs above and are sent again, like the real function does,
    # after any answer other than 200
    if ("$ScriptBlock" -match 'New-PveNodesQemuClone|Get-PveClusterResources')
    {
        for ($attempt = 1; $attempt -le $MaxRetries; $attempt++)
        {
            $result = & $ScriptBlock
            if ($result.StatusCode -eq 200) { break }
        }
        return $result
    }
    # The first call after the clone fails, so the function returns before it needs more stubs
    [pscustomobject]@{ StatusCode = 500; ReasonPhrase = 'Not part of this test' }
}

$script:proxmoxVmCache = @{ pve1 = @(); pve2 = @() }
$script:cloneNewIds = [System.Collections.Generic.List[int]]::new()
$script:taskWaits = 0
$script:sameNameVmExists = $false
$script:refused = $false
$proxmoxProperties = @{}
if ($settings.TargetNode) { $proxmoxProperties.TargetNode = $settings.TargetNode }
$machine = [AutomatedLab.Machine]@{ Name = 'VM1'; ResourceName = 'VM1'; OperatingSystem = 'Windows Server 2022'; Processors = 2; Memory = 4GB; ProxmoxProperties = $proxmoxProperties }
$null = New-LWProxmoxVM -Machine $machine -ErrorAction SilentlyContinue -ErrorVariable cloneErrors
'CLONE-REQUESTED=' + ($script:cloneNewIds.Count -gt 0)
'CLONE-NEWIDS=' + ($script:cloneNewIds -join ',')
'STORED-VMID=' + $machine.ProxmoxProperties.VmId
'CACHED-NODES=' + (($script:proxmoxVmCache.Keys | Sort-Object) -join ',')
foreach ($cloneError in $cloneErrors) { 'CLONE-ERROR=' + $cloneError.Exception.Message }
'@
            $childScript = $childScript.Replace('__WORKERPATH__', $workerPath.Replace("'", "''"))
            $childScript = $childScript.Replace('__SETTINGS__', [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($settingsJson)))
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

        $output | Should -Contain 'CLONE-NEWIDS=9001' -Because ($output -join [Environment]::NewLine)
        $errorLines = @($output | Where-Object { $_ -like 'CLONE-ERROR=Failed to create VM*' })
        $errorLines.Count | Should -Be 1 -Because ($output -join [Environment]::NewLine)
        $errorLines[0] | Should -Match ([regex]::Escape($taskText))
        $errorLines[0] | Should -Match "node 'pve1'"
        $errorLines[0] | Should -Match 'VMID 9001'
        $errorLines[0] | Should -Match 'UPID:clone'
    }

    It 'clones with the VMID after the highest VMID of the cluster, containers included' {
        $output = Invoke-CloneInChildProcess -ClusterGuest @{ vmid = 120; type = 'qemu' }, @{ vmid = 9000; type = 'qemu' }, @{ vmid = 9005; type = 'lxc' }

        $output | Should -Contain 'CLONE-NEWIDS=9006' -Because ($output -join [Environment]::NewLine)
        $output | Should -Contain 'STORED-VMID=9006'
    }

    It 'clones again with a higher VMID when Proxmox refuses the VMID as taken' {
        # The cluster list still ends at 9000, as for a guest that the connected user may not see
        $output = Invoke-CloneInChildProcess -CloneAnswer "VM __NEWID__ already exists on node 'pve1'", 'OK'

        $output | Should -Contain 'CLONE-NEWIDS=9001,9002' -Because ($output -join [Environment]::NewLine)
        $output | Should -Contain 'STORED-VMID=9002'
        $output | Where-Object { $_ -like 'CLONE-ERROR=Failed to create VM*' } | Should -BeNullOrEmpty
    }

    It 'clones again with a higher VMID when the clone task fails because another clone took the VMID' {
        $output = Invoke-CloneInChildProcess -WaitResult "VM __NEWID__ already exists on node 'pve1'", 'OK'

        $output | Should -Contain 'CLONE-NEWIDS=9001,9002' -Because ($output -join [Environment]::NewLine)
        $output | Should -Contain 'STORED-VMID=9002'
        $output | Where-Object { $_ -like 'CLONE-ERROR=Failed to create VM*' } | Should -BeNullOrEmpty
    }

    It 'clones at most <RetryCount> more times and names each VMID it tried' -ForEach @(
        @{ RetryCount = '2'; Tried = '9001,9002,9003' }
        @{ RetryCount = '0'; Tried = '9001' }
    ) {
        $output = Invoke-CloneInChildProcess -CloneAnswer "VM __NEWID__ already exists on node 'pve1'" -RetryCount $RetryCount

        $output | Should -Contain "CLONE-NEWIDS=$Tried" -Because ($output -join [Environment]::NewLine)
        $output | Should -Contain 'STORED-VMID='
        $errorLines = @($output | Where-Object { $_ -like 'CLONE-ERROR=*' })
        $errorLines.Count | Should -Be 1 -Because ($output -join [Environment]::NewLine)
        $errorLines[0] | Should -Match ([regex]::Escape(($Tried -replace ',', ', ')))
        $errorLines[0] | Should -Match 'already exists'
    }

    It 'does not clone again when a VM with the name of the machine holds a VMID after the refusal' {
        $output = Invoke-CloneInChildProcess -CloneAnswer "VM __NEWID__ already exists on node 'pve1'", 'OK' -SameNameVmAfterRefusal

        $output | Should -Contain 'CLONE-NEWIDS=9001' -Because ($output -join [Environment]::NewLine)
        $output | Should -Contain 'STORED-VMID='
        $errorLines = @($output | Where-Object { $_ -like 'CLONE-ERROR=*' })
        $errorLines.Count | Should -Be 1 -Because ($output -join [Environment]::NewLine)
        $errorLines[0] | Should -Match "named 'VM1' exists now \(VMID 9001\)"
    }

    It 'sends the clone request once and stops with the VMID when it gets no answer' {
        # A second request for the VMID would be refused as taken by the clone that the first one may have started
        $output = Invoke-CloneInChildProcess -CloneAnswer 'NOANSWER', "VM __NEWID__ already exists on node 'pve1'", 'OK'

        $output | Should -Contain 'CLONE-NEWIDS=9001' -Because ($output -join [Environment]::NewLine)
        $output | Should -Contain 'STORED-VMID='
        $errorLines = @($output | Where-Object { $_ -like 'CLONE-ERROR=*' })
        $errorLines.Count | Should -Be 1 -Because ($output -join [Environment]::NewLine)
        $errorLines[0] | Should -Match 'VMID 9001 may exist now'
    }

    It 'does not clone again when the guests of the cluster cannot be listed after a refusal' {
        $output = Invoke-CloneInChildProcess -CloneAnswer "VM __NEWID__ already exists on node 'pve1'", 'OK' -ClusterListFailsAfterRefusal

        $output | Should -Contain 'CLONE-NEWIDS=9001' -Because ($output -join [Environment]::NewLine)
        $errorLines = @($output | Where-Object { $_ -like 'CLONE-ERROR=*' })
        $errorLines.Count | Should -Be 1 -Because ($output -join [Environment]::NewLine)
        $errorLines[0] | Should -Match 'cluster list unavailable'
    }

    It 'does not clone again when Proxmox refuses the clone for another reason' {
        $output = Invoke-CloneInChildProcess -CloneAnswer "storage 'fast' does not exist", 'OK'

        $output | Should -Contain 'CLONE-NEWIDS=9001' -Because ($output -join [Environment]::NewLine)
        $errorLines = @($output | Where-Object { $_ -like 'CLONE-ERROR=*' })
        $errorLines.Count | Should -Be 1 -Because ($output -join [Environment]::NewLine)
        $errorLines[0] | Should -Match "storage 'fast' does not exist"
    }
}
