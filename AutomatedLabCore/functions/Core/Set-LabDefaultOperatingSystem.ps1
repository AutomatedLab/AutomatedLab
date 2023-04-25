function Set-LabDefaultOperatingSystem
{
    [Cmdletbinding()]
    Param(
        [Parameter(Mandatory)]
        [Alias('Name')]
        [string]
        $OperatingSystem,

        [string]
        $Version
    )

    $labDefinition = Get-LabDefinition -ErrorAction SilentlyContinue

    if (-not $labDefinition) { throw 'No lab defined. Please call New-LabDefinition first before calling Set-LabDefaultOperatingSystem.' }

    if ($labDefinition.DefaultVirtualizationEngine -eq 'Azure' -and -not $labDefinition.AzureSettings)
    {
        try
        {
            Add-LabAzureSubscription -ErrorAction Stop
        }
        catch
        {
            throw "No Azure subscription added yet. Please run 'Add-LabAzureSubscription' first."
        }
        $labDefinition = Get-LabDefinition -ErrorAction Stop
    }

    $additionalParameter = @{}
    if ($labDefinition.DefaultVirtualizationEngine -eq 'Azure')
    {
        $additionalParameter['Location'] = $labDefinition.AzureSettings.DefaultLocation.DisplayName
        $additionalParameter['Azure'] = $true
    }
   
    if ($Version)
    {
        $os = Get-LabAvailableOperatingSystem @additionalParameter | Where-Object { $_.OperatingSystemName -eq $OperatingSystem -and $_.Version -eq $OperatingSystemVersion }
    }
    else
    {
        $os = Get-LabAvailableOperatingSystem @additionalParameter | Where-Object { $_.OperatingSystemName -eq $OperatingSystem }
        if ($os.Count -gt 1)
        {
            $os = $os | Sort-Object Version -Descending | Select-Object -First 1
            Write-ScreenInfo "The operating system '$OperatingSystem' is available multiple times. Choosing the one with the highest version ($($os.Version)) as default operating system" -Type Warning
        }
    }

    if (-not $os)
    {
        throw "The operating system '$OperatingSystem' could not be found in the available operating systems. Call 'Get-LabAvailableOperatingSystem' to get a list of operating systems available to the lab."
    }
    $labDefinition.DefaultOperatingSystem = $os
}
