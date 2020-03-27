function Install-NetFramework35
{
    <#
        .SYNOPSIS
            Install-OSCNetFx3 is an advanced function which can be used to install .NET Framework 3.5 in Windows 8.
        .DESCRIPTION
            Install-OSCNetFx3 is an advanced function which can be used to install .NET Framework 3.5 in Windows 8.
        .PARAMETER  Online
	        It will download .NET Framework 3.5 online and install it.
        .PARAMETER 	LocalSource
	        The path of local source which includes .NET Framework 3.5 source.
        .PARAMETER	TemplateID
	        The ID of the template in the template group
        .EXAMPLE
            C:\PS> Install-OSCNetFx3 -Online

	        This command shows how to download .NET Framework 3.5 online and install it.
        .EXAMPLE
            C:\PS> Install-OSCNetFx3 -LocalSource G:\sources\sxs

	        This command shows how to use local source to install .NET Framework 3.5.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Local')]
    Param
    (
	    [Parameter(Mandatory=$true, ParameterSetName = 'Online')]
        [Switch]$Online,
	    [Parameter(Mandatory=$true, ParameterSetName = 'Local')]
        [String]$LocalSource
    )

    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
    {
	    Write-Error "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"
	    return
    }

    $osName = (Get-CimInstance "win32_operatingsystem" | Select-Object caption).Caption
    if ($osName -notlike '*Microsoft Windows 8*')
    {
        Write-Error 'This script only runs on Windows 8'
        return
    }

    $result = Dism /online /get-featureinfo /featurename:NetFx3
    if($result -contains 'State : Enabled')
    {
        Write-ScreenInfo ".Net Framework 3.5 has been already installed and enabled." -Type Warning
        return
    }

    if($LocalSource)
    {
	    Write-Host "Installing .Net Framework 3.5, do not close this prompt..."
	    DISM /Online /Enable-Feature /FeatureName:NetFx3 /All /LimitAccess /Source:$LocalSource | Out-Null
	    $result = Dism /online /Get-featureinfo /featurename:NetFx3
	    if($result -contains "State : Enabled")
	    {
		    Write-Host "Install .Net Framework 3.5 successfully."
	    }
	    else
	    {
		    Write-Host "Failed to install Install .Net Framework 3.5,please make sure the local source is correct."
	    }
    }
    Else
    {
	    Write-Host "Installing .Net Framework 3.5, do not close this prompt..." |
	    Dism /online /Enable-feature /featurename:NetFx3 /All | Out-Null
	    $result = Dism /online /Get-featureinfo /featurename:NetFx3
	    if($result -contains "State : Enabled")
	    {
		    Write-Host "Install .Net Framework 3.5 successfully."
	    }
	    else
	    {
		    Write-Host "Failed to install Install .Net Framework 3.5, you can use local source to try again."
	    }
    }
}

$drive = (Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType = 5").DeviceID
$sourcePath = "$drive\sources\sxs"
Install-NetFramework35 -LocalSource $sourcePath