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
        SmtpServer =  $PSCmdlet.MyInvocation.MyCommand.Module.PrivateData.Mail.SmtpServer
        From = $module.PrivateDate.From
        CC = $PSCmdlet.MyInvocation.MyCommand.Module.PrivateData.Mail.CC
        To = $PSCmdlet.MyInvocation.MyCommand.Module.PrivateData.Mail.To
        Priority = $PSCmdlet.MyInvocation.MyCommand.Module.PrivateData.Mail.Priority
        Port = $PSCmdlet.MyInvocation.MyCommand.Module.PrivateData.Mail.Port
        Body = $body
        Subject = "AutomatedLab notification: $($lab.Name) $Activity"
    }

    
    Send-MailMessage @mailParameters
}
