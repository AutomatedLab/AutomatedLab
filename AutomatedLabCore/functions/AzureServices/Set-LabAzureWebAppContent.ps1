function Set-LabAzureWebAppContent
{
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Name,

        [Parameter(Mandatory, Position = 1)]
        [string]$LocalContentPath
    )

    begin
    {
        Write-LogFunctionEntry

        if (-not (Test-Path -Path $LocalContentPath))
        {
            Write-LogFunctionExitWithError -Message "The path '$LocalContentPath' does not exist"
            continue
        }

        $script:lab = Get-Lab
    }

    process
    {
        if (-not $Name) { return }

        $webApp = $lab.AzureResources.Services | Where-Object Name -eq $Name

        if (-not $webApp)
        {
            Write-Error "The Azure App Service '$Name' does not exist."
            return
        }

        $publishingProfile = $webApp.PublishProfiles | Where-Object PublishMethod -eq 'FTP'
        $cred = New-Object System.Net.NetworkCredential($publishingProfile.UserName, $publishingProfile.UserPWD)
        $publishingProfile.PublishUrl -match '(ftp:\/\/)(?<url>[\w-\.]+)(\/)' | Out-Null
        $hostUrl = $Matches.url

        Send-FtpFolder -Path $LocalContentPath -DestinationPath site/wwwroot/ -HostUrl $hostUrl -Credential $cred -Recure
    }

    end
    {
        Write-LogFunctionExit
    }
}
