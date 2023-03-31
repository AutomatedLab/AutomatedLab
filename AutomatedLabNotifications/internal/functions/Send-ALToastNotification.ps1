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

    $isFullGui = $true # Client

    if (Get-Item 'HKLM:\software\Microsoft\Windows NT\CurrentVersion\Server\ServerLevels' -ErrorAction SilentlyContinue)
    {
        [bool]$core = [int](Get-ItemProperty 'HKLM:\software\Microsoft\Windows NT\CurrentVersion\Server\ServerLevels' -Name ServerCore -ErrorAction SilentlyContinue).ServerCore
        [bool]$guimgmt = [int](Get-ItemProperty 'HKLM:\software\Microsoft\Windows NT\CurrentVersion\Server\ServerLevels' -Name Server-Gui-Mgmt -ErrorAction SilentlyContinue).'Server-Gui-Mgmt'
        [bool]$guimgmtshell = [int](Get-ItemProperty 'HKLM:\software\Microsoft\Windows NT\CurrentVersion\Server\ServerLevels' -Name Server-Gui-Shell -ErrorAction SilentlyContinue).'Server-Gui-Shell'

        $isFullGui = $core -and $guimgmt -and $guimgmtshell
    }

    if ($PSVersionTable.BuildVersion -lt 6.3 -or -not $isFullGui)
    {
        Write-PSFMessage -Message 'No toasts for OS version < 6.3 or Server Core'
        return
    }

    # Hardcoded toaster from PowerShell - no custom Toast providers after 1709
    $toastProvider = "{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe"
    $imageLocation = Get-LabConfigurationItem -Name Notifications.NotificationProviders.Toast.Image
    $imagePath = "$((Get-LabConfigurationItem -Name LabAppDataRoot))\Assets"
    $imageFilePath = Join-Path $imagePath -ChildPath (Split-Path $imageLocation -Leaf)

    if (-not (Test-Path -Path $imagePath))
    {
        [void](New-Item -ItemType Directory -Path $imagePath)
    }

    if (-not (Test-Path -Path $imageFilePath))
    {
        $file = Get-LabInternetFile -Uri $imageLocation -Path $imagePath -PassThru
    }

    $lab = Get-Lab

    $template = "<?xml version=`"1.0`" encoding=`"utf-8`"?><toast><visual><binding template=`"ToastGeneric`"><text>{2}</text><text>Deployment of {0} on {1}, current status '{2}'. Message {3}.</text><image src=`"{4}`" placement=`"appLogoOverride`" hint-crop=`"circle`" /></binding></visual></toast>" -f `
        $lab.Name, $lab.DefaultVirtualizationEngine, $Activity, $Message, $imageFilePath

    try
    {
        [void]([Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime])
        [void]([Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime])
        [void]([Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications, ContentType = WindowsRuntime])
        $xml = New-Object Windows.Data.Xml.Dom.XmlDocument

        $xml.LoadXml($template)
        $toast = New-Object Windows.UI.Notifications.ToastNotification $xml
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($toastProvider).Show($toast)
    }
    catch
    {
        Write-PSFMessage "Error sending toast notification: $($_.Exception.Message)"
    }
}
