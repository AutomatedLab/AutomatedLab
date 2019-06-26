---
Module Name: AutomatedLabNotifications
Module Guid: 35afbbac-f3d2-49a1-ad6e-abb89aac4349
Download Help Link: {{ Update Download Link }}
Help Version: 1.0.0.0
Locale: en-US
---

# AutomatedLabNotifications Module
## Description
The purpose of the notifications module is to enable a pluggable notification system.
Currently, there are some providers implemented:
Toast notifications on Windows 10
Ifttt - Trigger a Webhook on If This Then That
Mail - Send an email
Voice - Let the computer to the talking on Windows 10

Notifications are automatically sent to all subscribed providers whenever a lab deployment
is started or has finished.

To configure the subscribed providers, simply execute:
```powershell
Set-PSFConfig -Module 'AutomatedLab' -Name 'Notifications.SubscribedProviders' -Value @('Toast', 'Voice') -PassThru | Register-PSFConfig
```

The other configurations can be found with a short description with `get-psfconfig -Module AutomatedLab -Name Notifications*`.

To add your own providers (happy to receive pull requests!) simply add a file called Send-AL<PROVIDERNAME>Notification.ps1 to the
private directory of AutomatedLabNotifications. All custom providers must implement the parameters:
```powershell
param
(
    [Parameter(Mandatory = $true)]
    [System.String]
    $Activity,

    [Parameter(Mandatory = $true)]
    [System.String]
    $Message
)
```

## AutomatedLabNotifications Cmdlets
### [Send-ALNotification](Send-ALNotification.md)
Send-ALNotification is the only exported cmdlet and internally calls the provider script, e.g. Send-ALToastNotification.ps1.

