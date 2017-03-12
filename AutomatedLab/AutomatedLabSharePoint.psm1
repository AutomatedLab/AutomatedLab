 $SP2013PrereqFiles = @("http://download.microsoft.com/download/9/1/3/9138773A-505D-43E2-AC08-9A77E1E0490B/1033/x64/sqlncli.msi", "http://download.microsoft.com/download/8/F/9/8F93DBBD-896B-4760-AC81-646F61363A6D/WcfDataServices.exe", `
    "http://download.microsoft.com/download/9/1/D/91DA8796-BE1D-46AF-8489-663AB7811517/setup_msipc_x64.msi", "http://download.microsoft.com/download/E/0/0/E0060D8F-2354-4871-9596-DC78538799CC/Synchronization.msi", `
    "http://download.microsoft.com/download/1/C/A/1CAA41C7-88B9-42D6-9E11-3C655656DAB1/WcfDataServices.exe", "http://download.microsoft.com/download/0/1/D/01D06854-CA0C-46F1-ADBA-EBF86010DCC6/r2/MicrosoftIdentityExtensions-64.msi", `
    "http://download.microsoft.com/download/D/7/2/D72FD747-69B6-40B7-875B-C2B40A6B2BDD/Windows6.1-KB974405-x64.msu", "http://download.microsoft.com/download/A/6/7/A678AB47-496B-4907-B3D4-0A2D280A13C0/WindowsServerAppFabricSetup_x64.exe", `
    "http://download.microsoft.com/download/7/B/5/7B51D8D1-20FD-4BF0-87C7-4714F5A1C313/AppFabric1.1-RTM-KB2671763-x64-ENU.exe")

$setupConfigFileContent = '<Configuration>
	<Package Id="sts">
		<Setting Id="LAUNCHEDFROMSETUPSTS" Value="Yes"/>
	</Package>

	<Package Id="spswfe">
		<Setting Id="SETUPCALLED" Value="1"/>
	</Package>

	<Logging Type="verbose" Path="%temp%" Template="SharePoint Server Setup(*).log"/>
	<PIDKEY Value="N3MDM-DXR3H-JD7QH-QKKCR-BY2Y7" />
	<Display Level="none" CompletionNotice="no" />
	<Setting Id="SERVERROLE" Value="APPLICATION"/>
	<Setting Id="USINGUIINSTALLMODE" Value="0"/>
	<Setting Id="SETUP_REBOOT" Value="Never" />
	<Setting Id="SETUPTYPE" Value="CLEAN_INSTALL"/>
</Configuration>'

#region Install-LabSharePoint2013
function Install-LabSharePoint2013
{
	# .ExternalHelp AutomatedLab.Help.xml
	[cmdletBinding()]
	param ([switch]$CreateCheckPoints)
    	
	$isoSharePoint2013sp1msdnHash = "9C29CF62E151D362FB02FBF07AEB0440C52DF555"
	
    Write-LogFunctionEntry
	
	$roleName = [AutomatedLab.Roles]::SharePoint2013
    $lab = Get-Lab
	
	if (-not (Get-LabMachine))
	{
		Write-LogFunctionExitWithError -Message 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first'
		return
	}
	
	$machines = Get-LabMachine | Where-Object { $roleName -in $_.Roles.Name }
	if (-not $machines)
	{
		Write-Warning -Message "There is no machine with the role '$roleName'"
		Write-LogFunctionExit
		return
	}

	$hypervMachines = @($machines | Where-Object HostType -eq HyperV)
	if ($hypervMachines)
    {	
    	Write-ScreenInfo -Message 'Waiting for machines with SharePoint 2013 role to start up' -NoNewline
	    Start-LabVM -ComputerName $hypervMachines -Wait -ProgressIndicator 15
        
        # Mount OS ISO for Windows Feature Installation
        Mount-LabIsoImage -ComputerName $hypervMachines -IsoPath $hypervMachines.OperatingSystem.IsoPath -SupressOutput

        Invoke-LabCommand -ComputerName $hypervMachines -ActivityName "Install Windows Features" -ScriptBlock {
            Import-Module ServerManager
            Add-WindowsFeature Net-Framework-Features,Web-Server,Web-WebServer,Web-Common-Http,Web-Static-Content,Web-Default-Doc,Web-Dir-Browsing,Web-Http-Errors,Web-App-Dev,Web-Asp-Net,Web-Net-Ext,Web-ISAPI-Ext,Web-ISAPI-Filter,Web-Health,Web-Http-Logging,Web-Log-Libraries,Web-Request-Monitor,Web-Http-Tracing,Web-Security,Web-Basic-Auth,Web-Windows-Auth,Web-Filtering,Web-Digest-Auth,Web-Performance,Web-Stat-Compression,Web-Dyn-Compression,Web-Mgmt-Tools,Web-Mgmt-Console,Web-Mgmt-Compat,Web-Metabase,Application-Server,AS-Web-Support,AS-TCP-Port-Sharing,AS-WAS-Support, AS-HTTP-Activation,AS-TCP-Activation,AS-Named-Pipes,AS-Net-Framework,WAS,WAS-Process-Model,WAS-NET-Environment,WAS-Config-APIs,Web-Lgcy-Scripting,Windows-Identity-Foundation,Server-Media-Foundation,Xps-Viewer –Source D:\sources\sxs
        }

        Write-ScreenInfo -Message "Restaring server to complete Windows Features installation"
        Restart-LabVM $hypervMachines
        Dismount-LabIsoImage -ComputerName $hypervMachines

        # Mount SharePoint ISO
	    $isoImageSharePoint2013 = $lab.Sources.ISOs | Where-Object { $_.Name -eq $roleName }
        if (-not $isoImageSharePoint2013)
        {
	        Write-LogFunctionExitWithError -Message "There is no ISO image available to install the role '$roleName'. Please add the required ISO to the lab and name it '$roleName'"
	        return
        }
        Mount-LabIsoImage -ComputerName $hypervMachines -IsoPath $isoImageSharePoint2013.Path -SupressOutput

        Write-ScreenInfo -Message "Copying installation files for SharePoint 2013 to server"
        Invoke-LabCommand -ComputerName $hypervMachines -ActivityName "Copy SharePoint 2013 Installation Files" -ScriptBlock {
            Copy-Item -Path "D:\" -Destination "C:\SPInstall\" -Recurse
        } 
       
      

        # Download and copy Prerequisite Files to server
        Write-ScreenInfo -Message "Downloading and copying prerequisite files for SharePoint 2013 to server"
        $client = New-Object System.Net.WebClient
        foreach ($prereqFile in $SP2013PrereqFiles)
        {
            $prereqUri = New-Object System.Uri($prereqFile)
            $prereqFileName = $prereqUri.Segments[$prereqUri.Segments.Count-1]
            if ($prereqFile -like "*1CAA41C7-88B9-42D6-9E11-3C655656DAB1*")
            {
                $prereqFileName = "WcfDataServices56.exe"
    
            }
            
            $client.DownloadFile($prereqUri, "$tempPrereqsFolderName\$prereqFileName")
            Copy-LabFileItem -Path "$tempPrereqsFolderName\$prereqFileName" -DestinationFolder "C:\SPInstall\prerequisiteinstallerfiles" -ComputerName $vm
        }

        # Installing Prereqs
        Write-ScreenInfo -Message "Installing prerequisite files for SharePoint 2013 on server"
        Invoke-LabCommand -PassThru -ComputerName $hypervMachines -ActivityName "Install SharePoint 2013 Prerequisites" -ScriptBlock {    
            Start-Process -Wait "C:\SPInstall\PrerequisiteInstaller.exe" –ArgumentList "/unattended /SQLNCli:C:\SPInstall\PrerequisiteInstallerFiles\sqlncli.msi `
               /IDFX:C:\SPInstall\PrerequisiteInstallerFiles\Windows6.1-KB974405-x64.msu  `
               /IDFX11:C:\SPInstall\PrerequisiteInstallerFiles\MicrosoftIdentityExtensions-64.msi ` 
               /Sync:C:\SPInstall\PrerequisiteInstallerFiles\Synchronization.msi  `
               /AppFabric:C:\SPInstall\PrerequisiteInstallerFiles\WindowsServerAppFabricSetup_x64.exe  `
               /KB2671763:C:\SPInstall\PrerequisiteInstallerFiles\AppFabric1.1-RTM-KB2671763-x64-ENU.exe  `
               /MSIPCClient:C:\SPInstall\PrerequisiteInstallerFiles\setup_msipc_x64.msi  `
               /WCFDataServices:C:\SPInstall\PrerequisiteInstallerFiles\WcfDataServices.exe  `
               /WCFDataServices56:C:\SPInstall\PrerequisiteInstallerFiles\WcfDataServices56.exe"
        } 

        Write-ScreenInfo -Message "Restaring server to complete prerequisites installation"
        Restart-LabVM $hypervMachines

        # Install SharePoint 2013 binaries
        Write-ScreenInfo -Message "Installing SharePoint 2013 binaries on server"
        $setupConfigFilePath = "$tempPrereqsFolderName\al-config.xml"
        $setupConfigFile = Get-Item $setupConfigFilePath -ErrorAction SilentlyContinue
        if ($setupConfigFile)
        {
            Remove-Item $setupConfigFilePath
        }
        New-Item -Path $tempPrereqsFolderName -Name 'al-config.xml' -ItemType File -Value $setupConfigFileContent
        Copy-LabFileItem -Path $setupConfigFilePath -DestinationFolder "C:\SPInstall\files" -ComputerName $vm

        Invoke-LabCommand -ComputerName $hypervMachines -ActivityName "Install SharePoint 2013" -ScriptBlock {
            Start-Process -Wait "C:\SPInstall\setup.exe" –ArgumentList "/config C:\SPInstall\files\al-config.xml"            
        }
	}
    Write-ScreenInfo -Message "Waiting for SharePoint 2013 role to complete installation" -NoNewLine
}
#endregion Install-LabSharePoint2013
