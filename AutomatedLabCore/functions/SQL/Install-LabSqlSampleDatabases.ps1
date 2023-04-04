function Install-LabSqlSampleDatabases
{
    param
    (
        [Parameter(Mandatory)]
        [AutomatedLab.Machine]
        $Machine
    )

    Write-LogFunctionEntry

    $role = $Machine.Roles | Where-Object Name -like SQLServer* | Sort-Object Name -Descending | Select-Object -First 1
    $roleName = ($role).Name
    $roleInstance = if ($role.Properties['InstanceName'])
    {
        $role.Properties['InstanceName']
    }
    else
    {
        'MSSQLSERVER'
    }

    $sqlLink = Get-LabConfigurationItem -Name $roleName.ToString()
    if (-not $sqlLink)
    {
        throw "No SQL link found to download $roleName sample database"
    }

    $targetFolder = Join-Path -Path (Get-LabSourcesLocationInternal -Local) -ChildPath SoftwarePackages\SqlSampleDbs

    if (-not (Test-Path $targetFolder))
    {
        [void] (New-Item -ItemType Directory -Path $targetFolder)
    }

    if ($roleName -like 'SQLServer2008*')
    {
        $targetFile = Join-Path -Path $targetFolder -ChildPath "$roleName.zip"
    }
    else
    {
        [void] (New-Item -ItemType Directory -Path (Join-Path -Path $targetFolder -ChildPath $rolename) -ErrorAction SilentlyContinue)
        $targetFile = Join-Path -Path $targetFolder -ChildPath "$rolename\$roleName.bak"
    }

    Get-LabInternetFile -Uri $sqlLink -Path $targetFile

    $dependencyFolder = Join-Path -Path $targetFolder -ChildPath $roleName

    switch ($roleName)
    {
        'SQLServer2008'
        {
            Microsoft.PowerShell.Archive\Expand-Archive $targetFile -DestinationPath $dependencyFolder -Force

            Invoke-LabCommand -ActivityName "$roleName Sample DBs" -ComputerName $Machine -ScriptBlock {
                $mdf = Get-Item -Path 'C:\SQLServer2008\AdventureWorksLT2008_Data.mdf' -ErrorAction SilentlyContinue
                $ldf = Get-Item -Path 'C:\SQLServer2008\AdventureWorksLT2008_Log.ldf' -ErrorAction SilentlyContinue
                $connectionInstance = if ($roleInstance -ne 'MSSQLSERVER') { "localhost\$roleInstance" } else { "localhost" }
                $query = 'CREATE DATABASE AdventureWorks2008 ON (FILENAME = "{0}"), (FILENAME = "{1}") FOR ATTACH;' -f $mdf.FullName, $ldf.FullName
                Invoke-Sqlcmd -ServerInstance $connectionInstance -Query $query
            } -DependencyFolderPath $dependencyFolder -Variable (Get-Variable roleInstance)
        }
        'SQLServer2008R2'
        {
            Microsoft.PowerShell.Archive\Expand-Archive $targetFile -DestinationPath $dependencyFolder -Force

            Invoke-LabCommand -ActivityName "$roleName Sample DBs" -ComputerName $Machine -ScriptBlock {
                $mdf = Get-Item -Path 'C:\SQLServer2008R2\AdventureWorksLT2008R2_Data.mdf' -ErrorAction SilentlyContinue
                $ldf = Get-Item -Path 'C:\SQLServer2008R2\AdventureWorksLT2008R2_Log.ldf' -ErrorAction SilentlyContinue
                $connectionInstance = if ($roleInstance -ne 'MSSQLSERVER') { "localhost\$roleInstance" } else { "localhost" }
                $query = 'CREATE DATABASE AdventureWorks2008R2 ON (FILENAME = "{0}"), (FILENAME = "{1}") FOR ATTACH;' -f $mdf.FullName, $ldf.FullName
                Invoke-Sqlcmd -ServerInstance $connectionInstance -Query $query
            } -DependencyFolderPath $dependencyFolder -Variable (Get-Variable roleInstance)
        }
        'SQLServer2012'
        {
            Invoke-LabCommand -ActivityName "$roleName Sample DBs" -ComputerName $Machine -ScriptBlock {
                $backupFile = Get-ChildItem -Filter *.bak -Path C:\SQLServer2012
                $connectionInstance = if ($roleInstance -ne 'MSSQLSERVER') { "localhost\$roleInstance" } else { "localhost" }
                $query = @"
                USE [master]

                RESTORE DATABASE AdventureWorks2012
                FROM disk= '$($backupFile.FullName)'
                WITH MOVE 'AdventureWorks2012_data' TO 'C:\Program Files\Microsoft SQL Server\MSSQL11.$roleInstance\MSSQL\DATA\AdventureWorks2012.mdf',
                MOVE 'AdventureWorks2012_Log' TO 'C:\Program Files\Microsoft SQL Server\MSSQL11.$roleInstance\MSSQL\DATA\AdventureWorks2012.ldf'
                ,REPLACE
"@
                Invoke-Sqlcmd -ServerInstance $connectionInstance -Query $query
            } -DependencyFolderPath $dependencyFolder -Variable (Get-Variable roleInstance)
        }
        'SQLServer2014'
        {
            Invoke-LabCommand -ActivityName "$roleName Sample DBs" -ComputerName $Machine -ScriptBlock {
                $backupFile = Get-ChildItem -Filter *.bak -Path C:\SQLServer2014
                $connectionInstance = if ($roleInstance -ne 'MSSQLSERVER') { "localhost\$roleInstance" } else { "localhost" }
                $query = @"
        USE [master]

        RESTORE DATABASE AdventureWorks2014
        FROM disk= '$($backupFile.FullName)'
        WITH MOVE 'AdventureWorks2014_data' TO 'C:\Program Files\Microsoft SQL Server\MSSQL12.$roleInstance\MSSQL\DATA\AdventureWorks2014.mdf',
        MOVE 'AdventureWorks2014_Log' TO 'C:\Program Files\Microsoft SQL Server\MSSQL12.$roleInstance\MSSQL\DATA\AdventureWorks2014.ldf'
        ,REPLACE
"@
                Invoke-Sqlcmd -ServerInstance $connectionInstance -Query $query
            } -DependencyFolderPath $dependencyFolder -Variable (Get-Variable roleInstance)
        }
        'SQLServer2016'
        {
            Invoke-LabCommand -ActivityName "$roleName Sample DBs" -ComputerName $Machine -ScriptBlock {
                $backupFile = Get-ChildItem -Filter *.bak -Path C:\SQLServer2016
                $connectionInstance = if ($roleInstance -ne 'MSSQLSERVER') { "localhost\$roleInstance" } else { "localhost" }
                $query = @"
        USE master
        RESTORE DATABASE WideWorldImporters
        FROM disk =
        '$($backupFile.FullName)'
        WITH MOVE 'WWI_Primary' TO
        'C:\Program Files\Microsoft SQL Server\MSSQL13.$roleInstance\MSSQL\DATA\WideWorldImporters.mdf',
        MOVE 'WWI_UserData' TO
        'C:\Program Files\Microsoft SQL Server\MSSQL13.$roleInstance\MSSQL\DATA\WideWorldImporters_UserData.ndf',
        MOVE 'WWI_Log' TO
        'C:\Program Files\Microsoft SQL Server\MSSQL13.$roleInstance\MSSQL\DATA\WideWorldImporters.ldf',
        MOVE 'WWI_InMemory_Data_1' TO
        'C:\Program Files\Microsoft SQL Server\MSSQL13.$roleInstance\MSSQL\DATA\WideWorldImporters_InMemory_Data_1',
        REPLACE
"@
                Invoke-Sqlcmd -ServerInstance $connectionInstance -Query $query
            } -DependencyFolderPath $dependencyFolder -Variable (Get-Variable roleInstance)
        }
        'SQLServer2017'
        {
            Invoke-LabCommand -ActivityName "$roleName Sample DBs" -ComputerName $Machine -ScriptBlock {
                $backupFile = Get-ChildItem -Filter *.bak -Path C:\SQLServer2017
                $connectionInstance = if ($roleInstance -ne 'MSSQLSERVER') { "localhost\$roleInstance" } else { "localhost" }
                $query = @"
        USE master
        RESTORE DATABASE WideWorldImporters
        FROM disk =
        '$($backupFile.FullName)'
        WITH MOVE 'WWI_Primary' TO
        'C:\Program Files\Microsoft SQL Server\MSSQL14.$roleInstance\MSSQL\DATA\WideWorldImporters.mdf',
        MOVE 'WWI_UserData' TO
        'C:\Program Files\Microsoft SQL Server\MSSQL14.$roleInstance\MSSQL\DATA\WideWorldImporters_UserData.ndf',
        MOVE 'WWI_Log' TO
        'C:\Program Files\Microsoft SQL Server\MSSQL14.$roleInstance\MSSQL\DATA\WideWorldImporters.ldf',
        MOVE 'WWI_InMemory_Data_1' TO
        'C:\Program Files\Microsoft SQL Server\MSSQL14.$roleInstance\MSSQL\DATA\WideWorldImporters_InMemory_Data_1',
        REPLACE
"@
                Invoke-Sqlcmd -ServerInstance $connectionInstance -Query $query
            } -DependencyFolderPath $dependencyFolder -Variable (Get-Variable roleInstance)
        }
        'SQLServer2019'
        {
            Invoke-LabCommand -ActivityName "$roleName Sample DBs" -ComputerName $Machine -ScriptBlock {
                $backupFile = Get-ChildItem -Filter *.bak -Path C:\SQLServer2019
                $connectionInstance = if ($roleInstance -ne 'MSSQLSERVER') { "localhost\$roleInstance" } else { "localhost" }
                $query = @"
        USE master
        RESTORE DATABASE WideWorldImporters
        FROM disk =
        '$($backupFile.FullName)'
        WITH MOVE 'WWI_Primary' TO
        'C:\Program Files\Microsoft SQL Server\MSSQL15.$roleInstance\MSSQL\DATA\WideWorldImporters.mdf',
        MOVE 'WWI_UserData' TO
        'C:\Program Files\Microsoft SQL Server\MSSQL15.$roleInstance\MSSQL\DATA\WideWorldImporters_UserData.ndf',
        MOVE 'WWI_Log' TO
        'C:\Program Files\Microsoft SQL Server\MSSQL15.$roleInstance\MSSQL\DATA\WideWorldImporters.ldf',
        MOVE 'WWI_InMemory_Data_1' TO
        'C:\Program Files\Microsoft SQL Server\MSSQL15.$roleInstance\MSSQL\DATA\WideWorldImporters_InMemory_Data_1',
        REPLACE
"@
                Invoke-Sqlcmd -ServerInstance $connectionInstance -Query $query
            } -DependencyFolderPath $dependencyFolder -Variable (Get-Variable roleInstance)
        }
        'SQLServer2022'
        {
            Invoke-LabCommand -ActivityName "$roleName Sample DBs" -ComputerName $Machine -ScriptBlock {
                $backupFile = Get-ChildItem -Filter *.bak -Path C:\SQLServer2022
                $connectionInstance = if ($roleInstance -ne 'MSSQLSERVER') { "localhost\$roleInstance" } else { "localhost" }
                $query = @"
        USE master
        RESTORE DATABASE WideWorldImporters
        FROM disk =
        '$($backupFile.FullName)'
        WITH MOVE 'WWI_Primary' TO
        'C:\Program Files\Microsoft SQL Server\MSSQL16.$roleInstance\MSSQL\DATA\WideWorldImporters.mdf',
        MOVE 'WWI_UserData' TO
        'C:\Program Files\Microsoft SQL Server\MSSQL16.$roleInstance\MSSQL\DATA\WideWorldImporters_UserData.ndf',
        MOVE 'WWI_Log' TO
        'C:\Program Files\Microsoft SQL Server\MSSQL16.$roleInstance\MSSQL\DATA\WideWorldImporters.ldf',
        MOVE 'WWI_InMemory_Data_1' TO
        'C:\Program Files\Microsoft SQL Server\MSSQL16.$roleInstance\MSSQL\DATA\WideWorldImporters_InMemory_Data_1',
        REPLACE
"@
                Invoke-Sqlcmd -ServerInstance $connectionInstance -Query $query
            } -DependencyFolderPath $dependencyFolder -Variable (Get-Variable roleInstance)
        }
        default
        {
            Write-LogFunctionExitWithError -Exception (New-Object System.ArgumentException("$roleName has no sample scripts yet.", 'roleName'))
        }
    }

    Write-LogFunctionExit
}
