param
(
    [Parameter(Mandatory)]
    [string]
    $ComputerName,
    
    [Parameter(ParameterSetName = 'PackageList')]
    [string[]]
    $Package,
    
    [Parameter(ParameterSetName = 'PackagePath')]
    [string]
    $PackagePath,
    
    [Parameter(ParameterSetName = 'PackageList')]
    [string]
    $SourceRepositoryName = 'PSGallery',
    
    [Parameter()]
    [string]
    $ApiKey,
    
    [Parameter()]
    [uint16]
    $Port,
    
    [Parameter()]
    [ValidateSet('false', 'true')]
    [string]
    $UseSsl = 'false'
)

Import-Lab -Name $data.Name -NoValidation -NoDisplay
$nugetHost = Get-LabVM -ComputerName $ComputerName

if (-not $nugetHost)
{
    Write-ScreenInfo -Type Error -Message "No host $ComputerName is known - will not deploy NuGet"
    return
}

if (-not $ApiKey)
{
    $ApiKey = (Get-Lab).DefaultInstallationCredential.Password
}

if (-not $Port)
{
    $Port = if (Get-LabVM -Role CaRoot, CaSubordinate)
    {
        $UseSsl = 'true'
        443 
    }
    else
    {
        $UseSsl = 'false'
        80
    }
}

if ([Convert]::ToBoolean($UseSsl) -and -not (Get-LabVM -Role CaRoot, CaSubordinate))
{
    Write-ScreenInfo -Type Error -Message 'No CA found in your lab, but you selected UseSsl. NuGet server will not be deployed'
    return
}

$cert = 'Unencrypted'
if ([Convert]::ToBoolean($UseSsl))
{
    Write-ScreenInfo -Type Verbose -Message 'Requesting certificate'
    $cert = Request-LabCertificate -Computer $ComputerName -Subject "CN=$ComputerName" -SAN $nugetHost.FQDN, 'localhost' -Template WebServer -PassThru
}

Write-ScreenInfo -Type Verbose -Message 'Building NuGet server deployment package'
$buildScript = Join-Path -Path $PSScriptRoot -ChildPath '.build\build.ps1'
$buildParam = @{
    ProjectPath = $PSScriptRoot    
}

if ($PSCmdlet.ParameterSetName -eq 'PackageList')
{
    $buildParam['Packages'] = $Package
    $buildParam['Repository'] = $SourceRepositoryName
}
else
{
    $buildParam['PackageSourcePath'] = $PackagePath
}

& $buildScript @buildParam

Copy-LabFileItem -Path $PSScriptRoot\publish\BuildOutput.zip -ComputerName $ComputerName

$result = Invoke-LabCommand -ComputerName $ComputerName -ScriptBlock {
    
    $scriptParam = @{
        ApiKey  = [pscredential]::new('blorb', ($ApiKey | ConvertTo-SecureString -AsPlainText -Force))
        Port    = $Port
        UseSsl = [Convert]::ToBoolean($UseSsl)
    }

    if ([Convert]::ToBoolean($UseSsl))
    {
        $scriptParam['CertificateThumbprint'] = $cert.Thumbprint
    }

    $null = New-Item -Path C:\buildtemp -ItemType Directory -Force -ErrorAction SilentlyContinue
    Expand-Archive -Path C:\BuildOutput.zip -DestinationPath C:\buildtemp -Force
    & C:\buildtemp\Deploy.ps1 @scriptParam
} -Variable (Get-Variable ApiKey, cert, Port, UseSsl) -PassThru

if ($result.FailedCount -eq 0)
{
    Write-ScreenInfo "Successfully deployed NuGet feed on $ComputerName"
}
else
{
    Write-ScreenInfo -Message "NuGet deployment seems to have failed on $ComputerName. Pester reports $($result.FailedCount)/$($result.TotalCount) failed tests"
}

$prefix = if ($UseSsl) { 'https' } else { 'http' }
Write-ScreenInfo ("Use your new feed:
Register-PSRepository -Name AutomatedLabFeed -SourceLocation '{0}://{1}:{2}/nuget' -PublishLocation '{0}://{1}:{2}/nuget' -InstallationPolicy Trusted
" -f $prefix,$nugetHost.FQDN,$Port)