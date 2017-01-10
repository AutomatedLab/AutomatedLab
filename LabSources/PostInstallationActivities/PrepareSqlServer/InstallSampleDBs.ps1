if (Get-Module -ListAvailable -Name SQLPS)
{
    Import-Module -Name SQLPS -ErrorAction SilentlyContinue
}
elseif (Get-PSSnapin -Registered -Name SqlServerCmdletSnapin100 -ErrorAction SilentlyContinue)
{
    Add-PSSnapin -Name SqlServerCmdletSnapin100 -ErrorAction SilentlyContinue
}
else
{
    throw 'Could neither add SQLPS module nor SqlServerCmdletSnapin100 snapin as they are not available'
}

Invoke-Sqlcmd -InputFile C:\PrepareSqlServer\instnwnd.sql -ServerInstance $env:COMPUTERNAME
Invoke-Sqlcmd -InputFile C:\PrepareSqlServer\instpubs.sql -ServerInstance $env:COMPUTERNAME