function Send-ALNotification
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Activity,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Message,

        [ValidateSet('Toast','Ifttt','Mail','Voice')]
        [string[]]
        $Provider
    )

    begin
    {
        $lab = Get-Lab -ErrorAction SilentlyContinue
        if (-not $lab)
        {
            Write-PSFMessage -Message "No lab data available. Skipping notification."
        }
    }

    process
    {
        if (-not $lab)
        {
            return
        }

        foreach ($selectedProvider in $Provider)
        {
            $functionName = "Send-AL$($selectedProvider)Notification"
            Write-PSFMessage $functionName

            &$functionName -Activity $Activity -Message $Message
        }
    }

}
