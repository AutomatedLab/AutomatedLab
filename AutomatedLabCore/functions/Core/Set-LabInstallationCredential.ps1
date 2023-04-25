function Set-LabInstallationCredential
{
    [OutputType([System.Int32])]
    [CmdletBinding(DefaultParameterSetName = 'All')]
    Param (
        [Parameter(Mandatory, ParameterSetName = 'All')]
        [Parameter(Mandatory=$false, ParameterSetName = 'Prompt')]
        [ValidatePattern('^([\w\.-]){2,15}$')]
        [string]$Username,

        [Parameter(Mandatory, ParameterSetName = 'All')]
        [Parameter(Mandatory=$false, ParameterSetName = 'Prompt')]
        [string]$Password,

        [Parameter(Mandatory, ParameterSetName = 'Prompt')]
        [switch]$Prompt
    )

    # https://docs.microsoft.com/en-us/azure/virtual-machines/windows/faq#what-are-the-password-requirements-when-creating-a-vm
    $azurePasswordBlacklist = @(
        'abc@123'
        'iloveyou!'
        'P@$$w0rd'
        'P@ssw0rd'
        'P@ssword123'
        'Pa$$word'
        'pass@word1'
        'Password!'
        'Password1'
        'Password22'
    )

    if (-not (Get-LabDefinition))
    {
        throw 'No lab defined. Please call New-LabDefinition first before calling Set-LabInstallationCredential.'
    }

    if ((Get-LabDefinition).DefaultVirtualizationEngine -eq 'Azure')
    {
        if ($Password -and $azurePasswordBlacklist -contains $Password)
        {
            throw "Password '$Password' is in the list of forbidden passwords for Azure VMs: $($azurePasswordBlacklist -join ', ')"
        }

        if ($Username -eq 'Administrator')
        {
            throw 'Username may not be Administrator for Azure VMs.'
        }

        $checks = @(
            $Password -match '[A-Z]'
            $Password -match '[a-z]'
            $Password -match '\d'
            $Password.Length -ge 8
        )

        if ($Password -and $checks -contains $false)
        {
            throw "Passwords for Azure VM administrator have to:
                Be at least 8 characters long
                Have lower characters
                Have upper characters
                Have a digit
            "
        }
    }

    if ($PSCmdlet.ParameterSetName -eq 'All')
    {
        $user = New-Object AutomatedLab.User($Username, $Password)
        (Get-LabDefinition).DefaultInstallationCredential = $user
    }
    else
    {
        $promptUser = Read-Host "Type desired username for admin user (or leave blank for 'Install'. Username cannot be 'Administrator' if deploying in Azure)"

        if (-not $promptUser)
        {
            $promptUser = 'Install'
        }
        do
        {
            $promptPassword = Read-Host "Type password for admin user (leave blank for 'Somepass1' or type 'x' to cancel )"

            if (-not $promptPassword)
            {
                $promptPassword = 'Somepass1'
                $checks = 5
                break
            }

            [int]$minLength  = 8
            [int]$numUpper   = 1
            [int]$numLower   = 1
            [int]$numNumbers = 1
            [int]$numSpecial = 1

            $upper   = [regex]'[A-Z]'
            $lower   = [regex]'[a-z]'
            $number  = [regex]'[0-9]'
            $special = [regex]'[^a-zA-Z0-9]'

            $checks = 0

            if ($promptPassword.length -ge 8)                            { $checks++ }
            if ($upper.Matches($promptPassword).Count -ge $numUpper )    { $checks++ }
            if ($lower.Matches($promptPassword).Count -ge $numLower )    { $checks++ }
            if ($number.Matches($promptPassword).Count -ge $numNumbers ) { $checks++ }

            if ($checks -lt 4)
            {
                if ($special.Matches($promptPassword).Count -ge $numSpecial )  { $checks }
            }

            if ($checks -lt 4)
            {
                Write-PSFMessage -Level Host 'Password must be have minimum length of 8'
                Write-PSFMessage -Level Host 'Password must contain minimum one upper case character'
                Write-PSFMessage -Level Host 'Password must contain minimum one lower case character'
                Write-PSFMessage -Level Host 'Password must contain minimum one special character'
            }
        }
        until ($checks -ge 4 -or (-not $promptUser) -or (-not $promptPassword) -or $promptPassword -eq 'x')

        if ($checks -ge 4 -and $promptPassword -ne 'x')
        {
            $user = New-Object AutomatedLab.User($promptUser, $promptPassword)
        }
    }
}
