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
        SmtpServer =  (Get-LabConfigurationItem -Name NotificationProviders).Mail.SmtpServer
        From = (Get-LabConfigurationItem -Name NotificationProviders).Mail.From
        CC = (Get-LabConfigurationItem -Name NotificationProviders).Mail.CC
        To = (Get-LabConfigurationItem -Name NotificationProviders).Mail.To
        Priority = (Get-LabConfigurationItem -Name NotificationProviders).Mail.Priority
        Port = (Get-LabConfigurationItem -Name NotificationProviders).Mail.Port
        Body = $body
        Subject = "AutomatedLab notification: $($lab.Name) $Activity"
    }

    
    Send-MailMessage @mailParameters
}
