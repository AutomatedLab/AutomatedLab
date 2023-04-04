function Register-LabArgumentCompleters
{
    $commands = Get-Command -Module AutomatedLab*, PSFileTransfer | Where-Object { $_.Parameters -and $_.Parameters.ContainsKey('ComputerName') }

    Register-PSFTeppArgumentCompleter -Command $commands -Parameter ComputerName -Name 'AutomatedLab-ComputerName'
}
