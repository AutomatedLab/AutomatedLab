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
    
    if (Get-Item 'HKLM:\software\Microsoft\Windows NT\CurrentVersion\Server\ServerLevels' -ErrorAction SilentlyContinue)
    {
        [bool]$core = [int](Get-ItemProperty 'HKLM:\software\Microsoft\Windows NT\CurrentVersion\Server\ServerLevels' -Name ServerCore -ErrorAction SilentlyContinue).ServerCore
        [bool]$guimgmt = [int](Get-ItemProperty 'HKLM:\software\Microsoft\Windows NT\CurrentVersion\Server\ServerLevels' -Name Server-Gui-Mgmt -ErrorAction SilentlyContinue).'Server-Gui-Mgmt'
        [bool]$guimgmtshell = [int](Get-ItemProperty 'HKLM:\software\Microsoft\Windows NT\CurrentVersion\Server\ServerLevels' -Name Server-Gui-Shell -ErrorAction SilentlyContinue).'Server-Gui-Shell'

        $isFullGui = $core -and $guimgmt -and $guimgmtshell
    }    

    if ($PSVersionTable.BuildVersion -lt 6.3 -or -not $isFullGui)
	{
        Write-Verbose -Message 'No toasts for OS version < 6.3 or Server Core'
        return
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
