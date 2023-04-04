function Reset-LabAdPassword
{
    param(
        [Parameter(Mandatory)]
        [string]$DomainName
    )
    
    $lab = Get-Lab
    $domain = $lab.Domains | Where-Object Name -eq $DomainName
    $vm = Get-LabVM -Role RootDC, FirstChildDC | Where-Object DomainName -eq $DomainName
    
    Invoke-LabCommand -ActivityName 'Reset Administrator password in AD' -ScriptBlock {
        Add-Type -AssemblyName System.DirectoryServices.AccountManagement
        $ctx = New-Object System.DirectoryServices.AccountManagement.PrincipalContext('Domain')
        $i = 0
        while (-not $u -and $i -lt 25)
        {
            try
            {
                $u = [System.DirectoryServices.AccountManagement.UserPrincipal]::FindByIdentity($ctx, $args[0])
                $u.SetPassword($args[1])
            }
            catch
            {
                Start-Sleep -Seconds 10
                $i++
            }
        }
        
    } -ComputerName $vm -ArgumentList $domain.Administrator.UserName, $domain.Administrator.Password -NoDisplay
}
