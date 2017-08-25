function Send-ALNotification
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
    DynamicParam {
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        $ParameterName = 'Provider'        
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $AttributeCollection.Add($ParameterAttribute)
        $arrSet = @($PSCmdlet.MyInvocation.MyCommand.Module.PrivateData.Keys)
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)
        $AttributeCollection.Add($ValidateSetAttribute)
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string[]], $AttributeCollection)

        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
        return $RuntimeParameterDictionary
}

begin
{
    $Provider = $PsBoundParameters['Provider']

    if (-not (Get-Lab))
    {
        Write-Verbose -Message "No lab data available. Skipping notification."
        return
    }
}

process
{
    foreach ($selectedProvider in $Provider)
    {
        $functionName = "Send-AL$($selectedProvider)Notification"
        Write-Verbose $functionName

        &$functionName -Activity $Activity -Message $Message
    }
}

}
