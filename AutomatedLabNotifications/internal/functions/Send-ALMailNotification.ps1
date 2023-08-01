function Send-ALMailNotification
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

    $lab = Get-Lab

    $body = @"
    Dear recipient,

    Lab $($lab.Name) on $($Lab.DefaultVirtualizationEngine)logged activity "$Activity" with the following message:

    $Message
"@

    $mailParameters = @{
        SmtpServer =  Get-LabConfigurationItem -Name Notifications.NotificationProviders.Mail.SmtpServer
        From = Get-LabConfigurationItem -Name Notifications.NotificationProviders.Mail.From
        CC = Get-LabConfigurationItem -Name Notifications.NotificationProviders.Mail.CC
        To = Get-LabConfigurationItem -Name Notifications.NotificationProviders.Mail.To
        Priority = Get-LabConfigurationItem -Name Notifications.NotificationProviders.Mail.Priority
        Port = Get-LabConfigurationItem -Name Notifications.NotificationProviders.Mail.Port
        Body = $body
        Subject = "AutomatedLab notification: $($lab.Name) $Activity"
    }


    Send-MailMessage @mailParameters
}
