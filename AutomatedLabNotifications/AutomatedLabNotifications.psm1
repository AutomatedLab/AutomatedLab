#Get public and private function definition files.
$public = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

#Dot source the files
Foreach ($import in @($public + $private))
{
    Try
    {
        . $import.FullName
    }
    Catch
    {
        Write-Error -Message "Failed to import function $($import.FullName): $_"
    }
}

Export-ModuleMember -Function $public.Basename

<#
IDEE

NotificationHub lädt alle Provider. Jeder Provider nimmt Funktion Subscribe-<Prod>NotificationProvider und Unsubscribe-<Prod>NotificationProvider.
Jeder Provider hat Parameter Activity, Message, und LabName wird automatisch
Provider-Einstellungen in PSD1-Files (?)

NOtificationHub liefert Subscribe-ALNotifications -Provider Provider[], Unsubscribe -Provider, -All; Send-ALNotification

Install-Lab greift auf NotificationsHub zu -> Send-ALNotification -Activity -Status -Message


Subscriptions

#>