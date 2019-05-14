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

        [Parameter(Mandatory = $true)]
        [System.String]
        $Provider
    )

    begin
    {
        $lab = Get-Lab -ErrorAction SilentlyContinue
        if (-not $lab)
        {
            Write-Verbose -Message "No lab data available. Skipping notification."
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
            Write-Verbose $functionName

            &$functionName -Activity $Activity -Message $Message
        }
    }

}
