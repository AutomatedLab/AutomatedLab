function Get-LabBuildStep
{
    param
    (
        [string]
        $ComputerName
    )

    if (-not (Get-Lab -ErrorAction SilentlyContinue))
    {
        throw 'No lab imported. Please use Import-Lab to import the target lab containing at least one TFS server'
    }

    $tfsvm = Get-LabVm -Role Tfs2015, Tfs2017, Tfs2018, AzDevOps | Select-Object -First 1

    if ($ComputerName)
    {
        $tfsVm = Get-LabVm -ComputerName $ComputerName
    }

    if (-not $tfsvm) { throw ('No TFS VM in lab or no machine found with name {0}' -f $ComputerName) }

    $defaultParam = Get-LabTfsParameter -ComputerName $tfsvm
    $defaultParam.ProjectName = $ProjectName

    return (Get-TfsBuildStep @defaultParam)
}
