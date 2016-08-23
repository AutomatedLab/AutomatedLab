Import-Module SQLPS
Invoke-Sqlcmd -InputFile C:\PrepareSqlServer\instnwnd.sql -ServerInstance $env:COMPUTERNAME
Invoke-Sqlcmd -InputFile C:\PrepareSqlServer\instpubs.sql -ServerInstance $env:COMPUTERNAME