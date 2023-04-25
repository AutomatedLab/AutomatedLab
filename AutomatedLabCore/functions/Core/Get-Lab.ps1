function Get-Lab
{
    [CmdletBinding()]
    [OutputType([AutomatedLab.Lab])]

    param (
        [switch]$List
    )

    if ($List)
    {
        $labsPath = "$((Get-LabConfigurationItem -Name LabAppDataRoot))/Labs"

        foreach ($path in Get-ChildItem -Path $labsPath -Directory -ErrorAction SilentlyContinue)
        {
            $labXmlPath = Join-Path -Path $path.FullName -ChildPath Lab.xml
            if (Test-Path -Path $labXmlPath)
            {
                Split-Path -Path $path -Leaf
            }
        }
    }
    else
    {
        if ($Script:data)
        {
            $Script:data
        }
        else
        {
            Write-Error 'Lab data not available. Use Import-Lab and reference a Lab.xml to import one.'
        }
    }
}
