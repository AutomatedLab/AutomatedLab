function Get-LabMachineDefinition {
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    [OutputType([AutomatedLab.Machine])]

    param (
        [Parameter(Position = 0, ParameterSetName = 'ByName', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName,

        [Parameter(Mandatory, ParameterSetName = 'ByRole')]
        [AutomatedLab.Roles]$Role,

        [Parameter(Mandatory, ParameterSetName = 'All')]
        [switch]$All
    )

    begin {
        #required to suporess verbose messages, warnings and errors
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        Write-LogFunctionEntry

        [System.Collections.Generic.List[AutomatedLab.Machine]]$result = [System.Collections.Generic.List[AutomatedLab.Machine]]::new()
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'ByName') {
            if ($ComputerName) {
                foreach ($n in $ComputerName) {
                    $machine = $Script:machines | Where-Object Name -in $n
                    if (-not $machine) {
                        continue
                    }

                    $result.Add($machine)
                }
            }
            else {
                $result.AddRange($Script:machines)
            }
        }

        if ($PSCmdlet.ParameterSetName -eq 'ByRole') {
            $Script:machines |
            Where-Object { $_.Roles.Name } |
            Where-Object { $_.Roles | Where-Object { $Role.HasFlag([AutomatedLab.Roles]$_.Name) } } |
            ForEach-Object { $result.Add($_) }

            if (-not $result) {
                return
            }
        }

        if ($PSCmdlet.ParameterSetName -eq 'All') {
            $result.AddRange($Script:machines)
        }
    }

    end {
        $result
    }
}
