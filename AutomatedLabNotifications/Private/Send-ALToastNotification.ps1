function Send-ALToastNotification
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Activity,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Message
    )
    
    $isCoreOrNano = Get-ItemPropertyValue 'HKLM:\software\Microsoft\Windows NT\CurrentVersion\Server\ServerLevels' -Name ServerCore,ServerNano -ErrorAction SilentlyContinue

    if ($PSVersionTable.BuildVersion.Major -lt 10 -or $isCoreOrNano)
	{
        Write-Verbose -Message 'No toasts for OS version < 10 or Server Nano/Server Core'
    }
    
    $toastProvider = $PSCmdlet.MyInvocation.MyCommand.Module.PrivateData.Toast.Provider
    $lab = Get-Lab

    $template = "<toast><visual><binding template=`"ToastText02`"><text id=`"1`">$toastProvider</text><text id=`"2`">Deployment of {0} on {1}, current status '{2}'. Message {3}.</text></binding></visual></toast>" -f `
        $lab.Name, $lab.DefaultVirtualizationEngine, $Activity, $Message


    [void] ([Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime])
    [void] ([Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime])
    [void] ([Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications, ContentType = WindowsRuntime])
    $xml = New-Object Windows.Data.Xml.Dom.XmlDocument

    $xml.LoadXml($template)
    $toast = New-Object Windows.UI.Notifications.ToastNotification $xml
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("$toastProvider").Show($toast)
}
