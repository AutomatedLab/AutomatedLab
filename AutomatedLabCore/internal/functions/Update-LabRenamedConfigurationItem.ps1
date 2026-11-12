function Update-LabRenamedConfigurationItem
{
    <#
    .SYNOPSIS
        Applies a value that is still set under the old name of a renamed configuration item.

    .DESCRIPTION
        A value set under the old name, for example registered with Register-PSFConfig before the rename, is applied to
        the new name for this session while the new name has its default value. A warning names the command that
        registers the value under the new name. A value that the new name refuses is not applied, and the warning says
        why.

    .PARAMETER OldName
        The name of the item before the rename.

    .PARAMETER NewName
        The registered name of the item.

    .PARAMETER DefaultValue
        The default value of the new name. The value of the old name applies only while the new name has it.

    .PARAMETER Module
        The module of both names.
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string]
        $OldName,

        [Parameter(Mandatory)]
        [string]
        $NewName,

        [Parameter(Mandatory)]
        [AllowNull()]
        [object]
        $DefaultValue,

        [Parameter()]
        [string]
        $Module = 'AutomatedLab'
    )

    $oldValue = Get-PSFConfigValue -FullName "$Module.$OldName"
    if ([string]::IsNullOrEmpty([string]$oldValue))
    {
        return
    }

    if ([string](Get-PSFConfigValue -FullName "$Module.$NewName") -ne [string]$DefaultValue)
    {
        return
    }

    try
    {
        Set-PSFConfig -Module $Module -Name $NewName -Value $oldValue -EnableException
    }
    catch
    {
        Write-PSFMessage -Level Warning -Message "The configuration item '$Module.$OldName' was renamed to '$Module.$NewName'. Its value '$oldValue' is not used: $($_.Exception.Message)"
        return
    }

    Write-PSFMessage -Level Warning -Message "The configuration item '$Module.$OldName' was renamed to '$Module.$NewName'. Its value '$oldValue' is used for this session. Register it under the new name: Set-PSFConfig -Module $Module -Name $NewName -Value '$oldValue' -PassThru | Register-PSFConfig"
}
