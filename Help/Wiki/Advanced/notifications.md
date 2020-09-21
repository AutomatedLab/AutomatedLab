Getting lab notifications from the AutomatedLab notification hub is very easy. The default notification method on Windows 10/Server 2016 is a toast notification in the notification center. Install-Lab already makes use of the notification hub to send a notification each time a lab starts and finishes installing.  
The current providers that can be used to send notifications are Toast, IFTTT and Mail. All provider-related settings can be accessed from the module manifest of the module AutomatedLabNotifications. To subscribe to one or more providers, simply add them to the NotificationProviders key of the AutomatedLab module manifest.  
To use the notification hub in your own scripts, you can use the function:  
```powershell
Send-ALNotification -Activity 'Your activity' -Message 'Your detailed message here' -Provider Toast,Ifttt
```  
The module AutomatedLabNotification knows all it's providers by looking at it's module manifest. To add your own, custom provider, you only need to add it to this list as well as create a PowerShell script called Send-AL<YourProviderName>Notification in the modules Private subfolder. This script needs to contain the function Send-AL<YourProviderName>Notification and this function needs to implement the Parameters Activity and Message.  
Example:  
```powershell
function Send-ALCustomProviderNotification
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
}
```
To store user-specific settings like keys, ports, ... make use of the PrivateData hashtable inside the module manifest of AutomatedLabNotification:  
```powershell
PrivateData            = @{

        Ifttt = @{
            
            Key       = "Your IFTTT key here"
            EventName = "The name of your IFTTT event"
        }

        Mail  = @{
            To         = "Your recipient array here"
            CC         = "Your CC array here"
            SmtpServer = "Your SMTP server here"
            From       = "Your sender here"
            Priority   = "Normal"
            Port       = 25
        }

        Toast = @{
            Provider = 'AutomatedLab'
        }

    }
```  
To work with IFTTT, simply create a Webhook applet (https://ifttt.com/maker_webhooks). You can find your key here: https://ifttt.com/services/maker_webhooks/settings. You also need the event name of your applet.  

Last but not least: If you think of a cool provider, just develop it and send us your pull request!