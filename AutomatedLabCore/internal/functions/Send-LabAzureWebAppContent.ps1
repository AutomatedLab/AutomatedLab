function Send-LabAzureWebAppContent
{
    [OutputType([string])]
    param (
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'ByName', ValueFromPipelineByPropertyName)]
        [string]$Name,

        [Parameter(Position = 1, ParameterSetName = 'ByName', ValueFromPipelineByPropertyName)]
        [string]$ResourceGroup
    )

    begin
    {
        Write-LogFunctionEntry
        $script:lab = Get-Lab
        if (-not $lab)
        {
            Write-Error 'No definitions imported, so there is nothing to do. Please use Import-Lab first'
            return
        }
    }

    process
    {
        foreach ($n in $name)
        {
            $webApp = Get-LabAzureWebApp -Name $n | Where-Object ResourceGroup -eq $ResourceGroup

        }
    }

    end
    {
        Export-Lab
        if ($result.Count -eq 1 -and -not $AsHashTable)
        {
            $result[$result.Keys[0]]
        }
        else
        {
            $result
        }
        Write-LogFunctionExit
    }
}
