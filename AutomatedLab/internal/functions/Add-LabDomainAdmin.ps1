function Add-LabDomainAdmin
{
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [System.Security.SecureString]$Password,

        [string]$ComputerName
    )

    $cmd = {
        param(
            [Parameter(Mandatory)]
            [string]$Name,

            [Parameter(Mandatory)]
            [System.Security.SecureString]$Password
        )

        $server = 'localhost'

        $user = New-ADUser -Name $Name -AccountPassword $Password -Enabled $true -PassThru

        Add-ADGroupMember -Identity 'Domain Admins' -Members $user -Server $server

        try
        {
            Add-ADGroupMember -Identity 'Enterprise Admins' -Members $user -Server $server
            Add-ADGroupMember -Identity 'Schema Admins' -Members $user -Server $server
        }
        catch
        {
            #if adding the groups failed, this is executed propably in a child domain
        }
    }

    Invoke-LabCommand -ComputerName $ComputerName -ActivityName AddDomainAdmin -ScriptBlock $cmd -ArgumentList $Name, $Password
}
