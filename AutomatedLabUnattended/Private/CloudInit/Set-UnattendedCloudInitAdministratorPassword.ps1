function Set-UnattendedCloudInitAdministratorPassword
{
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $Password
    )

    $pw = [System.Text.Encoding]::UTF8.GetBytes($Password)
    $sha = [System.Security.Cryptography.SHA512Managed]::new()
    $hsh = $sha.ComputeHash($pw)
    $Script:un.identity.password = [Convert]::ToBase64String($hsh)
}
