function Install-LabAzureServices
{
    [CmdletBinding()]
    param ()

    Write-LogFunctionEntry
    $lab = Get-Lab

    if (-not $lab)
    {
        Write-Error 'No definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }

    Write-ScreenInfo -Message "Starting Azure Services Deplyment"

    $services = Get-LabAzureWebApp
    $servicePlans = Get-LabAzureAppServicePlan

    if (-not $services)
    {
        Write-ScreenInfo "No Azure service defined, exiting."
        Write-LogFunctionExit
        return
    }

    Write-ScreenInfo "There are $($servicePlans.Count) Azure App Services Plans defined. Starting deployment." -TaskStart
    $servicePlans | New-LabAzureAppServicePlan
    Write-ScreenInfo 'Finished creating Azure App Services Plans.' -TaskEnd

    Write-ScreenInfo "There are $($services.Count) Azure Web Apps defined. Starting deployment." -TaskStart
    $services | New-LabAzureWebApp
    Write-ScreenInfo 'Finished creating Azure Web Apps.' -TaskEnd

    Write-LogFunctionExit
}

#region New-LabAzureAppServicePlan
function New-LabAzureAppServicePlan
{
    [OutputType([AutomatedLab.Azure.AzureRmServerFarmWithRichSku])]
    param (
        [Parameter(Position = 0, ParameterSetName = 'ByName', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Name,

        [switch]$PassThru
    )

    begin
    {
        Write-LogFunctionEntry
        $script:lab = Get-Lab
        if (-not $lab)
        {
            Write-Error 'No definitions imported, so there is nothing to do. Please use Import-Lab first'
            return
        }
    }

    process
    {
        foreach ($planName in $Name)
        {
            $plan = Get-LabAzureAppServicePlan -Name $planName

            if (-not (Get-LabAzureResourceGroup -ResourceGroupName $plan.ResourceGroup))
            {
                New-LabAzureRmResourceGroup -ResourceGroupNames $plan.ResourceGroup -LocationName $plan.Location
            }

            if ((Get-AzAppServicePlan -Name $plan.Name -ResourceGroupName $plan.ResourceGroup -ErrorAction SilentlyContinue))
            {
                Write-Error "The Azure Application Service Plan '$planName' does already exist in $($plan.ResourceGroup)"
                return
            }

            $plan = New-AzAppServicePlan -Name $plan.Name -Location $plan.Location -ResourceGroupName $plan.ResourceGroup -Tier $plan.Tier -NumberofWorkers $plan.NumberofWorkers -WorkerSize $plan.WorkerSize

            if ($plan)
            {
                $plan = [AutomatedLab.Azure.AzureRmServerFarmWithRichSku]::Create($plan)
                $existingPlan = Get-LabAzureAppServicePlan -Name $plan.Name
                $existingPlan.Merge($plan)

                if ($PassThru)
                {
                    $plan
                }
            }
        }
    }

    end
    {
        Export-Lab
        Write-LogFunctionExit
    }
}
#endregion New-LabAzureAppServicePlan

#region Set-LabAzureWebAppContent
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
#endregion Set-LabAzureWebAppContent

#region New-LabAzureWebApp
function New-LabAzureWebApp
{
    [OutputType([AutomatedLab.Azure.AzureRmService])]
    param (
        [Parameter(Position = 0, ParameterSetName = 'ByName', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Name,

        [switch]$PassThru
    )

    begin
    {
        Write-LogFunctionEntry

        $script:lab = Get-Lab
        if (-not $lab)
        {
            Write-Error 'No definitions imported, so there is nothing to do. Please use Import-Lab first'
            return
        }
    }

    process
    {
        foreach ($serviceName in $Name)
        {
            $app = Get-LabAzureWebApp -Name $serviceName

            if (-not (Get-LabAzureResourceGroup -ResourceGroupName $app.ResourceGroup))
            {
                New-LabAzureRmResourceGroup -ResourceGroupNames $app.ResourceGroup -LocationName $app.Location
            }

            if (-not (Get-LabAzureAppServicePlan -Name $app.ApplicationServicePlan))
            {
                New-LabAzureAppServicePlan -Name $app.ApplicationServicePlan
            }

            $webApp = New-AzWebApp -Name $app.Name -Location $app.Location -AppServicePlan $app.ApplicationServicePlan -ResourceGroupName $app.ResourceGroup

            if ($webApp)
            {
                $webApp = [AutomatedLab.Azure.AzureRmService]::Create($webApp)

                #Get app-level deployment credentials
                $xml = [xml](Get-AzWebAppPublishingProfile -Name $webApp.Name -ResourceGroupName $webApp.ResourceGroup -OutputFile null)

                $publishProfile = [AutomatedLab.Azure.PublishProfile]::Create($xml.publishData.publishProfile)
                $webApp.PublishProfiles = $publishProfile

                $existingWebApp = Get-LabAzureWebApp -Name $webApp.Name
                $existingWebApp.Merge($webApp)

				$existingWebApp | Set-LabAzureWebAppContent -LocalContentPath "$(Get-LabSourcesLocationInternal -Local)\PostInstallationActivities\WebSiteDefaultContent"

                if ($PassThru)
                {
                    $webApp
                }
            }
        }
    }

    end
    {
        Export-Lab
        Write-LogFunctionExit
    }
}
#endregion New-LabAzureWebApp

#region Get-LabAzureAppServicePlan
function Get-LabAzureAppServicePlan
{
    [CmdletBinding(DefaultParameterSetName = 'All')]
    [OutputType([AutomatedLab.Azure.AzureRmServerFarmWithRichSku])]
    param (
        [Parameter(Position = 0, ParameterSetName = 'ByName', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Name
    )

    begin
    {
        Write-LogFunctionEntry

        $lab = Get-Lab
        if (-not $lab)
        {
            Write-Error 'No definitions imported, so there is nothing to do. Please use Import-Lab first'
            break
        }

        $script:lab = & $MyInvocation.MyCommand.Module { $script:lab }
    }

    process
    {
        if (-not $Name) { return }

        $sp = $lab.AzureResources.ServicePlans | Where-Object Name -eq $Name

        if (-not $sp)
        {
            Write-Error "The Azure App Service Plan '$Name' does not exist."
        }
        else
        {
            $sp
        }
    }

    end
    {
        if ($PSCmdlet.ParameterSetName -eq 'All')
        {
            $lab.AzureResources.ServicePlans
        }

        Write-LogFunctionExit
    }
}
#endregion Get-LabAzureAppServicePlan

#region Get-LabAzureWebApp
function Get-LabAzureWebApp
{
    [CmdletBinding(DefaultParameterSetName = 'All')]
    [OutputType([AutomatedLab.Azure.AzureRmService])]
    param (
        [Parameter(Position = 0, ParameterSetName = 'ByName', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Name
    )

    begin
    {
        Write-LogFunctionEntry

        $script:lab = Get-Lab
    }

    process
    {
        if (-not $Name) { return }

        $sa = $lab.AzureResources.Services | Where-Object Name -eq $Name

        if (-not $sa)
        {
            Write-Error "The Azure App Service '$Name' does not exist."
        }
        else
        {
            $sa
        }
    }

    end
    {
        if ($PSCmdlet.ParameterSetName -eq 'All')
        {
            $lab.AzureResources.Services
        }

        Write-LogFunctionExit
    }
}
#endregion Get-LabAzureWebApp

#region Remove-LabAzureWebApp
function Remove-LabAzureWebApp
{
    param (
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'ByName', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Name,

        [Parameter(Mandatory, Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$ResourceGroup
    )

    begin
    {
        Write-LogFunctionEntry

        $script:lab = Get-Lab
    }

    process
    {
        $service = $lab.AzureResources.Services | Where-Object { $_.Name -eq $Name -and $_.ResourceGroup -eq $ResourceGroup }

        if (-not $service)
        {
            Write-Error "The Azure App Service '$Name' does not exist in the lab."
        }
        else
        {
            $s = Get-AzWebApp -Name $service.Name -ResourceGroupName $service.ResourceGroup -ErrorAction SilentlyContinue

            if ($s)
            {
                $s | Remove-AzWebApp -Force
            }

            $lab.AzureResources.Services.Remove($service)
        }
    }

    end
    {
        Export-Lab
        Write-LogFunctionExit
    }
}
#endregion Remove-LabAzureWebApp

#region Remove-LabAzureAppServicePlan
function Remove-LabAzureAppServicePlan
{
    param (
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'ByName', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Name,

        [Parameter(Mandatory, Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$ResourceGroup
    )

    begin
    {
        Write-LogFunctionEntry

        $script:lab = Get-Lab
    }

    process
    {
        $servicePlan = $lab.AzureResources.ServicePlans | Where-Object { $_.Name -eq $Name -and $_.ResourceGroup -eq $ResourceGroup }

        if (-not $servicePlan)
        {
            Write-Error "The Azure App Service Plan '$Name' does not exist."
        }
        else
        {
            $sp = Get-AzAppServicePlan -Name $servicePlan.Name -ResourceGroupName $servicePlan.ResourceGroup -ErrorAction SilentlyContinue

            if ($sp)
            {
                $sp | Remove-AzAppServicePlan -Force
            }
            $lab.AzureResources.ServicePlans.Remove($servicePlan)
        }
    }

    end
    {
        Export-Lab
        Write-LogFunctionExit
    }
}
#endregion Remove-LabAzureAppServicePlan

#region Start-LabAzureWebApp
function Start-LabAzureWebApp
{
    [OutputType([AutomatedLab.Azure.AzureRmService])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Name,

        [Parameter(Mandatory, Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$ResourceGroup,

        [switch]$PassThru
    )

    begin
    {
        Write-LogFunctionEntry
        $script:lab = Get-Lab
        if (-not $lab)
        {
            Write-Error 'No definitions imported, so there is nothing to do. Please use Import-Lab first'
            return
        }
    }

    process
    {
        if (-not $Name) { return }

        $service = $lab.AzureResources.Services | Where-Object { $_.Name -eq $Name -and $_.ResourceGroup -eq $ResourceGroup }

        if (-not $service)
        {
            Write-Error "The Azure App Service '$Name' does not exist."
        }
        else
        {
            try
            {
                $s = Start-AzWebApp -Name $service.Name -ResourceGroupName $service.ResourceGroup -ErrorAction Stop
                $service.Merge($s, 'PublishProfiles')

                if ($PassThru)
                {
                    $service
                }
            }
            catch
            {
                Write-Error "The Azure Web App '$($service.Name)' in resource group '$($service.ResourceGroup)' could not be started"
            }
        }
    }

    end
    {
        Export-Lab
        Write-LogFunctionExit
    }
}
#endregion Start-LabAzureWebApp

#region Stop-LabAzureWebApp
function Stop-LabAzureWebApp
{
    [OutputType([AutomatedLab.Azure.AzureRmService])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Name,

        [Parameter(Mandatory, Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$ResourceGroup,

        [switch]$PassThru
    )

    begin
    {
        Write-LogFunctionEntry
        $script:lab = Get-Lab
        if (-not $lab)
        {
            Write-Error 'No definitions imported, so there is nothing to do. Please use Import-Lab first'
            return
        }
    }

    process
    {
        if (-not $Name) { return }

        $service = $lab.AzureResources.Services | Where-Object { $_.Name -eq $Name -and $_.ResourceGroup -eq $ResourceGroup }

        if (-not $service)
        {
            Write-Error "The Azure App Service '$Name' does not exist in Resource Group '$ResourceGroup'."
        }
        else
        {
            try
            {
                $s = Stop-AzWebApp -Name $service.Name -ResourceGroupName $service.ResourceGroup -ErrorAction Stop
                $service.Merge($s, 'PublishProfiles')

                if ($PassThru)
                {
                    $service
                }
            }
            catch
            {
                Write-Error "The Azure Web App '$($service.Name)' in resource group '$($service.ResourceGroup)' could not be stopped"
            }
        }
    }

    end
    {
        Export-Lab
        Write-LogFunctionExit
    }
}
#endregion Stop-LabAzureWebApp

#region Get-LabAzureWebAppStatus
function Get-LabAzureWebAppStatus
{
    [CmdletBinding(DefaultParameterSetName = 'All')]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'ByName', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Name,

        [Parameter(Position = 1, ParameterSetName = 'ByName', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$ResourceGroup,

        [Parameter(ParameterSetName = 'All')]
        [switch]$All = $true,

        [switch]$AsHashTable
    )

    begin
    {
        Write-LogFunctionEntry
        $script:lab = Get-Lab
        if (-not $lab)
        {
            Write-Error 'No definitions imported, so there is nothing to do. Please use Import-Lab first'
            return
        }
        $allAzureWebApps = Get-AzWebApp
        if ($PSCmdlet.ParameterSetName -eq 'All')
        {
            $Name = $lab.AzureResources.Services.Name
            $ResourceGroup = $lab.AzureResources.Services.Name.ResourceGroup
        }
        $result = [ordered]@{}
    }

    process
    {
        $services = foreach ($n in $name)
        {
            if (-not $n -and -not $PSCmdlet.ParameterSetName -eq 'All') { return }

            $service = if ($ResourceGroup)
            {
                $lab.AzureResources.Services | Where-Object { $_.Name -eq $n -and $_.ResourceGroup -eq $ResourceGroup }
            }
            else
            {
                $lab.AzureResources.Services | Where-Object { $_.Name -eq $n }
            }

            if (-not $service)
            {
                Write-Error "The Azure App Service '$n' does not exist."
            }
            else
            {
                $service
            }
        }

        foreach ($service in $services)
        {
            $s = $allAzureWebApps | Where-Object { $_.Name -eq $service.Name -and $_.ResourceGroup -eq $service.ResourceGroup }
            if ($s)
            {
                $service.Merge($s, 'PublishProfiles')
                $result.Add($service, $s.State)
            }
            else
            {
                Write-Error "The Web App '$($service.Name)' does not exist in the Azure Resource Group $($service.ResourceGroup)."
            }
        }

    }

    end
    {
        Export-Lab
        if ($result.Count -eq 1 -and -not $AsHashTable)
        {
            $result[$result.Keys[0]]
        }
        else
        {
            $result
        }
        Write-LogFunctionExit
    }
}
#Get-LabAzureWebAppStatus

#region Send-LabAzureWebAppContent
function Send-LabAzureWebAppContent
{
    [OutputType([string])]
    param (
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'ByName', ValueFromPipelineByPropertyName)]
        [string]$Name,

        [Parameter(Position = 1, ParameterSetName = 'ByName', ValueFromPipelineByPropertyName)]
        [string]$ResourceGroup
    )

    begin
    {
        Write-LogFunctionEntry
        $script:lab = Get-Lab
        if (-not $lab)
        {
            Write-Error 'No definitions imported, so there is nothing to do. Please use Import-Lab first'
            return
        }
    }

    process
    {
        foreach ($n in $name)
        {
            $webApp = Get-LabAzureWebApp -Name $n | Where-Object ResourceGroup -eq $ResourceGroup

        }
    }

    end
    {
        Export-Lab
        if ($result.Count -eq 1 -and -not $AsHashTable)
        {
            $result[$result.Keys[0]]
        }
        else
        {
            $result
        }
        Write-LogFunctionExit
    }
}
#endregion Send-LabAzureWebAppContent

#region Send-FtpFolder
function Send-FtpFolder
{
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$DestinationPath,

        [Parameter(Mandatory)]
        [string]$HostUrl,

        [Parameter(Mandatory)]
        [System.Net.NetworkCredential]$Credential,

        [switch]$Recure
    )

    Add-Type -Path (Join-Path -Path (Get-Module AutomatedLab).ModuleBase -ChildPath 'Tools\FluentFTP.dll')
    $fileCount = 0

    if (-not (Test-Path -Path $Path -PathType Container))
    {
        Write-Error "The folder '$Path' does not exist or is not a directory."
        return
    }

    $client = New-Object FluentFTP.FtpClient("ftp://$HostUrl", $Credential)
    try
    {
        $client.DataConnectionType = [FluentFTP.FtpDataConnectionType]::PASV
        $client.Connect()
    }
    catch
    {
        Write-Error -Message "Could not connect to FTP server: $($_.Exception.Message)" -Exception $_.Exception
        return
    }

    if ($DestinationPath.Contains('\'))
    {
        Write-Error "The destination path cannot contain backslashes. Please use forward slashes to separate folder names."
        return
    }

    if (-not $DestinationPath.EndsWith('/'))
    {
        $DestinationPath += '/'
    }

    $files = Get-ChildItem -Path $Path -File -Recurse:$Recure
    Write-PSFMessage "Sending folder '$Path' with $($files.Count) files"

    foreach ($file in $files)
    {
        $fileCount++
        Write-PSFMessage "Sending file $($file.FullName) ($fileCount)"
        Write-Progress -Activity "Uploading file '$($file.FullName)'" -Status x -PercentComplete ($fileCount / $files.Count * 100)
        $relativeFullName = $file.FullName.Replace($path, '').Replace('\', '/')
        if ($relativeFullName.StartsWith('/')) { $relativeFullName = $relativeFullName.Substring(1) }
        $newDestinationPath = $DestinationPath + $relativeFullName

        try
        {
            $result = $client.UploadFile($file.FullName, $newDestinationPath, 'Overwrite', $true, 'Retry')
        }
        catch
        {
            Write-Error -Exception $_.Exception
            $client.Disconnect()
            return
        }
        if (-not $result)
        {
            Write-Error "There was an error uploading file '$($file.FullName)'. Canelling the upload process."
            $client.Disconnect()
            return
        }
    }

    Write-PSFMessage "Finsihed sending folder '$Path'"

    $client.Disconnect()
}
#endregion Send-FtpFolder
