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
    $voiceInfo = (Get-Module AutomatedLabNotifications)[0].PrivateData.Voice

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
        $synth.SelectVoiceByHints($voiceInfo.Gender, $voiceInfo.Age, $null, $voiceInfo.Culture)
    }
    catch {return}

    if (-not $synth.Voice)
    {
        Write-Warning -Message ('No voice installed for culture {0} and gender {1}' -f $voiceInfo.Culture, $voiceInfo.Gender)
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