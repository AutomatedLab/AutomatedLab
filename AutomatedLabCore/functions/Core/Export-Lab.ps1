function Export-Lab
{
    [cmdletBinding()]

    param ()

    Write-LogFunctionEntry

    $lab = Get-Lab

    Remove-Item -Path $lab.LabFilePath

    Remove-Item -Path $lab.MachineDefinitionFiles[0].Path
    Remove-Item -Path $lab.DiskDefinitionFiles[0].Path

    $lab.Machines.Export($lab.MachineDefinitionFiles[0].Path)
    try
    {
        $lab.Disks.Export($lab.DiskDefinitionFiles[0].Path)
    }
    catch
    {
        $tmpList = [AutomatedLab.ListXmlStore[AutomatedLab.Disk]]::new()
        foreach ($d in $lab.Disks)
        {
            $tmpList.Add($d)
        }
        $tmpList.Export($lab.DiskDefinitionFiles[0].Path)
    }
    $lab.Machines.Clear()
    if ($lab.Disks)
    {
        $lab.Disks.Clear()
    }

    $lab.Export($lab.LabFilePath)

    Import-Lab -Name $lab.Name -NoValidation -NoDisplay -DoNotRemoveExistingLabPSSessions

    Write-LogFunctionExit
}
