function Send-ALVoiceNotification
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
    $culture = Get-LabConfigurationItem -Name Notifications.NotificationProviders.Voice.Culture
    $gender = Get-LabConfigurationItem -Name Notifications.NotificationProviders.Voice.Gender

    try
    {
        Add-Type -AssemblyName System.Speech -ErrorAction Stop
    }
    catch
    {
        return
    }

    $synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
    try
    {
        $synth.SelectVoiceByHints($gender, 30, $null, $culture)
    }
    catch {return}

    if (-not $synth.Voice)
    {
        Write-PSFMessage -Level Warning -Message ('No voice installed for culture {0} and gender {1}' -f $culture, $gender)
        return;
    }
    $synth.SetOutputToDefaultAudioDevice()

    $text = "
        Hi {4}!
        AutomatedLab has a new message for you!
        Deployment of {0} on {1} entered status {2}. Message {3}.
        Live long and prosper.
        " -f $lab.Name, $lab.DefaultVirtualizationEngine, $Activity, $Message, $env:USERNAME
    $synth.Speak($Text)
    $synth.Dispose()
}