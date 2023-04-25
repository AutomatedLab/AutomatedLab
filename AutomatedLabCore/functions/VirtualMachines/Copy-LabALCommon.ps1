function Copy-LabALCommon
{
    [CmdletBinding()]
    param
    ( 
        [Parameter(Mandatory)]
        [string[]]
        $ComputerName
    )
    
    $childPath = foreach ($vm in $ComputerName)
    {
        Invoke-LabCommand -ScriptBlock {
            if ($PSEdition -eq 'Core')
            {
                'core'
            } else
            {
                'full'
            }
        } -ComputerName $vm -NoDisplay -IgnoreAzureLabSources -DoNotUseCredSsp -PassThru |
        Add-Member -MemberType NoteProperty -Name ComputerName -Value $vm -Force -PassThru
    }

    $coreChild = @($childPath) -eq 'core'
    $fullChild = @($childPath) -eq 'full'
    $libLocation = Split-Path -Parent -Path (Split-Path -Path ([AutomatedLab.Common.Win32Exception]).Assembly.Location -Parent)

    if ($coreChild -and @(Invoke-LabCommand -ScriptBlock{
                Get-Item -Path '/ALLibraries/core/AutomatedLab.Common.dll' -ErrorAction SilentlyContinue
    } -ComputerName $coreChild.ComputerName -IgnoreAzureLabSources -NoDisplay -DoNotUseCredSsp -PassThru).Count -ne $coreChild.Count)
    {
        $coreLibraryFolder = Join-Path -Path $libLocation -ChildPath $coreChild[0]
        Copy-LabFileItem -Path $coreLibraryFolder -ComputerName $coreChild.ComputerName -DestinationFolderPath '/ALLibraries' -UseAzureLabSourcesOnAzureVm $false
    }

    if ($fullChild -and @(Invoke-LabCommand -ScriptBlock {
                Get-Item -Path '/ALLibraries/full/AutomatedLab.Common.dll' -ErrorAction SilentlyContinue
    } -ComputerName $fullChild.ComputerName -IgnoreAzureLabSources -NoDisplay -DoNotUseCredSsp -PassThru).Count -ne $fullChild.Count)
    {
        $fullLibraryFolder = Join-Path -Path $libLocation -ChildPath $fullChild[0]
        Copy-LabFileItem -Path $fullLibraryFolder -ComputerName $fullChild.ComputerName -DestinationFolderPath '/ALLibraries' -UseAzureLabSourcesOnAzureVm $false
    }
}
