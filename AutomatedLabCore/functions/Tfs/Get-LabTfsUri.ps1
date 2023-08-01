function Get-LabTfsUri
{
    [CmdletBinding()]
    param
    (
        [string]
        $ComputerName
    )

    if (-not (Get-Lab -ErrorAction SilentlyContinue))
    {
        throw 'No lab imported. Please use Import-Lab to import the target lab containing at least one TFS server'
    }

    $tfsvm = Get-LabVM -Role Tfs2015, Tfs2017, Tfs2018, AzDevOps | Select-Object -First 1

    if ($ComputerName)
    {
        $tfsVm = Get-LabVM -ComputerName $ComputerName
    }

    if (-not $tfsvm) { throw ('No TFS VM in lab or no machine found with name {0}' -f $ComputerName) }

    $defaultParam = Get-LabTfsParameter -ComputerName $tfsvm

    if (($tfsVm.Roles.Name -eq 'AzDevOps' -and $tfsVm.SkipDeployment) -or $defaultParam.Contains('PersonalAccessToken'))
    {
        'https://{0}/{1}' -f $defaultParam.InstanceName, $defaultParam.CollectionName
    }
    elseif ($defaultParam.UseSsl)
    {
        'https://{0}:{1}@{2}:{3}/{4}' -f $defaultParam.Credential.GetNetworkCredential().UserName, $defaultParam.Credential.GetNetworkCredential().Password, $defaultParam.InstanceName, $defaultParam.Port, $defaultParam.CollectionName
    }
    else
    {
        'http://{0}:{1}@{2}:{3}/{4}' -f $defaultParam.Credential.GetNetworkCredential().UserName, $defaultParam.Credential.GetNetworkCredential().Password, $defaultParam.InstanceName, $defaultParam.Port, $defaultParam.CollectionName
    }
}
