function Set-LabBuildWorkerCapability
{
    [CmdletBinding()]
    param
    ( )

    $buildWorkers = Get-LabVM -Role TfsBuildWorker
    if (-not $buildWorkers)
    {
        return
    }

    foreach ($machine in $buildWorkers)
    {
        $role = $machine.Roles | Where-Object Name -eq TfsBuildWorker
        $agentPool = if ($role.Properties.ContainsKey('AgentPool'))
        {
            $role.Properties['AgentPool']
        }
        else
        {
            'default'
        }

        [int]$numberOfBuildWorkers = $role.Properties.NumberOfBuildWorkers
        
        if ((Get-Command -Name Add-TfsAgentUserCapability -ErrorAction SilentlyContinue) -and $role.Properties.ContainsKey('Capabilities'))
        {
            $bwParam = Get-LabTfsParameter -ComputerName $machine
            if ($numberOfBuildWorkers)
            {
                $range = 1..$numberOfBuildWorkers
            }
            else
            {
                $range = 1
            }

            foreach ($numberOfBuildWorker in $range)
            {
                $agt = Get-TfsAgent @bwParam -PoolName $agentPool -Filter ([scriptblock]::Create("`$_.name -eq '$($machine.Name)-$numberOfBuildWorker'"))
                $caps = @{}
                foreach ($prop in ($role.Properties['Capabilities'] | ConvertFrom-Json).PSObject.Properties)
                {
                    $caps[$prop.Name] = $prop.Value
                }

                $null = Add-TfsAgentUserCapability @bwParam -Capability $caps -Agent $agt -PoolName $agentPool
            }
        }
    }
}
