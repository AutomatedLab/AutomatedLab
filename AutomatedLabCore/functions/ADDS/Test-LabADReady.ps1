function Test-LabADReady
{
    param (
        [Parameter(Mandatory)]
        [string]$ComputerName
    )

    Write-LogFunctionEntry

    $machine = Get-LabVM -ComputerName $ComputerName
    if (-not $machine)
    {
        Write-Error "The machine '$ComputerName' could not be found in the lab"
        return
    }

    $adReady = Invoke-LabCommand -ComputerName $machine -ActivityName GetAdwsServiceStatus -ScriptBlock {

        if ((Get-Service -Name ADWS -ErrorAction SilentlyContinue).Status -eq 'Running')
        {
            try
            {
                $env:ADPS_LoadDefaultDrive = 0
                $WarningPreference = 'SilentlyContinue'
                Import-Module -Name ActiveDirectory -ErrorAction Stop
                [bool](Get-ADDomainController -Server $env:COMPUTERNAME -ErrorAction SilentlyContinue)
            }
            catch
            {
                $false
            }
        }

    } -DoNotUseCredSsp -PassThru -NoDisplay  -ErrorAction SilentlyContinue

    [bool]$adReady

    Write-LogFunctionExit
}
