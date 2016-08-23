Configuration DscTestFile
{
    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
    
    Node localhost
    {
        File TestFile
        {
            Ensure = 'Present'
            Type = 'File'
            DestinationPath = 'C:\DscTestFile'
            Contents = 'OK'
        }
    }
}

DscTestFile -OutputPath C:\DscTestConfig | Out-Null
Rename-Item -Path C:\DscTestConfig\localhost.mof -NewName TestConfig.mof