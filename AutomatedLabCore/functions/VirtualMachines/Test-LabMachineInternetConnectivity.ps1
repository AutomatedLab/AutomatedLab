function Test-LabMachineInternetConnectivity
{
    [OutputType([bool])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ComputerName,

        [int]$Count = 3,

        [switch]$AsJob
    )

    $cmd = {
        $result = 1..$Count |
        ForEach-Object {
            Test-NetConnection www.microsoft.com -CommonTCPPort HTTP -InformationLevel Detailed -WarningAction SilentlyContinue
            Start-Sleep -Seconds 1
        }
    
        #if 75% of the results are negative, return the first negative result, otherwise return the first positive result
        if (($result | Where-Object TcpTestSucceeded -eq $false).Count -ge ($count * 0.75))
        {
            $result | Where-Object TcpTestSucceeded -eq $false | Select-Object -First 1
        }
        else
        {
            $result | Where-Object TcpTestSucceeded -eq $true | Select-Object -First 1
        }
    }

    if ($AsJob)
    {
        $job = Invoke-LabCommand -ComputerName $ComputerName -ActivityName "Testing Internet Connectivity of '$ComputerName'" `
        -ScriptBlock $cmd -Variable (Get-Variable -Name Count) -PassThru -NoDisplay -AsJob

        return $job
    }
    else
    {
        $result = Invoke-LabCommand -ComputerName $ComputerName -ActivityName "Testing Internet Connectivity of '$ComputerName'" `
        -ScriptBlock $cmd -Variable (Get-Variable -Name Count) -PassThru -NoDisplay

        return $result.TcpTestSucceeded
    }
}
