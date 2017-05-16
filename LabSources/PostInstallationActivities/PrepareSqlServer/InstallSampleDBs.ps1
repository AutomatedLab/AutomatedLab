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

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | out-null
$srv = New-Object "Microsoft.SqlServer.Management.Smo.Server" "."
if (-not $srv)
{
    Write-Error -Message 'Could not discover database server version. Execute the necessary sample DB script manually.' -ErrorAction Stop
}

# 2008
if ($srv.VersionMajor -eq 10 -and $srv.VersionMinor -eq 0)
{
    $mdf = Get-Item -Path (Join-Path (Join-Path -Path $PSScriptRoot -ChildPath 2008) -ChildPath 'AdventureWorksLT2008_Data.mdf') -ErrorAction SilentlyContinue
    $ldf = Get-Item -Path (Join-Path (Join-Path -Path $PSScriptRoot -ChildPath 2008) -ChildPath 'AdventureWorksLT2008_Log.ldf') -ErrorAction SilentlyContinue
    $query = 'CREATE DATABASE AdventureWorks2008 ON ({0}),({1}) FOR ATTACH;' -f $mdf.FullName, $ldf.FullName
    Invoke-Sqlcmd -ServerInstance localhost -Query $query
}

# 2008 R2
if ($srv.VersionMajor -eq 10 -and $srv.VersionMinor -eq 50)
{
    $mdf = Get-Item -Path (Join-Path (Join-Path -Path $PSScriptRoot -ChildPath 2008R2) -ChildPath 'AdventureWorksLT2008R2_Data.mdf') -ErrorAction SilentlyContinue
    $ldf = Get-Item -Path (Join-Path (Join-Path -Path $PSScriptRoot -ChildPath 2008R2) -ChildPath 'AdventureWorksLT2008R2_Log.ldf') -ErrorAction SilentlyContinue
    $query = 'CREATE DATABASE AdventureWorks2008R2 ON ({0}),({1}) FOR ATTACH;' -f $mdf.FullName, $ldf.FullName
    Invoke-Sqlcmd -ServerInstance localhost -Query $query
}

# 2012
if ($srv.VersionMajor -eq 11)
{
    $mdf = Get-Item -Path (Join-Path (Join-Path -Path $PSScriptRoot -ChildPath 2012) -ChildPath 'AdventureWorksLT2012_Data.mdf') -ErrorAction SilentlyContinue
    $ldf = Get-Item -Path (Join-Path (Join-Path -Path $PSScriptRoot -ChildPath 2012) -ChildPath 'AdventureWorksLT2012_Log.ldf') -ErrorAction SilentlyContinue
    $query = 'CREATE DATABASE AdventureWorks2012 ON ({0}),({1}) FOR ATTACH;' -f $mdf.FullName, $ldf.FullName
    Invoke-Sqlcmd -ServerInstance localhost -Query $query
}

# 2014
if ($srv.VersionMajor -eq 12)
{
    $scriptFile = Get-Item -Path (Join-Path (Join-Path -Path $PSScriptRoot -ChildPath 2014) -ChildPath 'instawdb.sql') -ErrorAction SilentlyContinue
    $newContent =  (Get-Content $scriptFile) -replace ':setvar SqlSamplesSourceDataPath .*', (':setvar SqlSamplesSourceDataPath "{0}\"' -f $scriptFile.Directory.FullName)

    # Invoke-SqlCmd fails with this SQL script. Using .NET instead
    $connection = New-Object -TypeName System.Data.SqlClient.SqlConnection('Server=localhost;Trusted_Connection=True;')
    $commandStrings = [regex]::Split($newContent,  "^\s*GO\s*$", 'Multiline,IgnoreCase')
    
    $command = New-Object -TypeName System.Data.SqlClient.SqlCommand
    $command.CommandType = 'Text'
    $command.CommandText = $newContent
    $command.Connection = $connection

    $connection.Open()

    $command.ExecuteNonQuery()


    <#
    string script = File.ReadAllText(@"E:\someSqlScript.sql");

  // split script on GO command
  IEnumerable<string> commandStrings = Regex.Split(script, @"^\s*GO\s*$", 
                           RegexOptions.Multiline | RegexOptions.IgnoreCase);

  Connection.Open();
  foreach (string commandString in commandStrings)
  {
    if (commandString.Trim() != "")
    {
       using(var command = new SqlCommand(commandString, Connection))
       {
          command.ExecuteNonQuery();
       }
    }
  }     
  Connection.Close();
    #>
}

# 2016
if ($srv.VersionMajor -eq 13)
{
    
}
