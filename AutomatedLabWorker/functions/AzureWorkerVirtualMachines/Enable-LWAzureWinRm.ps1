function Enable-LWAzureWinRm
{
    param
    (
        [Parameter(Mandatory)]
        [AutomatedLab.Machine[]]
        $Machine,

        [switch]
        $PassThru,

        [switch]
        $Wait
    )

    Test-LabHostConnected -Throw -Quiet

    Write-LogFunctionEntry

    $azureRetryCount = Get-LabConfigurationItem -Name AzureRetryCount

    $lab = Get-Lab
    $jobs = @()

    $tempFileName = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath enableazurewinrm.labtempfile.ps1
    $customScriptContent = @'
$null = mkdir C:\DeployDebug -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path C:\ALAzure -ErrorAction SilentlyContinue
'Trying to enable Remoting and CredSSP' | Out-File C:\ALAzure\WinRmActivation.log -Append
try
{
Enable-PSRemoting -Force -ErrorAction Stop
"Successfully called Enable-PSRemoting" | Out-File C:\ALAzure\WinRmActivation.log -Append
}
catch
{
"Error calling Enable-PSRemoting. $($_.Exception.Message)" | Out-File C:\ALAzure\WinRmActivation.log -Append
}
try
{
Enable-WSManCredSSP -Role Server -Force | Out-Null
"Successfully enabled CredSSP" | Out-File C:\ALAzure\WinRmActivation.log -Append
}
catch
{
try
{
New-ItemProperty -Path HKLM:\software\Microsoft\Windows\CurrentVersion\WSMAN\Service -Name auth_credssp -Value 1 -PropertyType DWORD -Force -ErrorACtion Stop
New-ItemProperty -Path HKLM:\software\Microsoft\Windows\CurrentVersion\WSMAN\Service -Name allow_remote_requests -Value 1 -PropertyType DWORD -Force -ErrorAction Stop
"Enabled CredSSP via Registry" | Out-File C:\ALAzure\WinRmActivation.log -Append
}
catch
{
"Could not enable CredSSP via cmdlet or registry!" | Out-File C:\ALAzure\WinRmActivation.log -Append
}
}
'@
    $customScriptContent | Out-File $tempFileName -Force -Encoding utf8
    $rgName = Get-LabAzureDefaultResourceGroup

    $jobs = foreach ($m in $Machine)
    {
        if ($Lab.AzureSettings.IsAzureStack)
        {
            $sa = Get-AzStorageAccount -ResourceGroupName $lab.AzureSettings.DefaultResourceGroup.ResourceGroupName -ErrorAction SilentlyContinue
            if (-not $sa)
            {
                $sa = New-AzStorageAccount -Name "cse$(-join (1..10 | % {[char](Get-Random -Min 97 -Max 122)}))" -ResourceGroupName $lab.AzureSettings.DefaultResourceGroup.ResourceGroupName -SkuName Standard_LRS -Kind Storage -Location (Get-LabAzureDefaultLocation).Location
            }

            $co = $sa | Get-AzStorageContainer -Name customscriptextension -ErrorAction SilentlyContinue
            if (-not $co)
            {
                $co = $sa | New-AzStorageContainer -Name customscriptextension
            }

            $content = Set-AzStorageBlobContent -File $tempFileName -CloudBlobContainer $co.CloudBlobContainer -Blob $(Split-Path -Path $tempFileName -Leaf) -Context $sa.Context -Force -ErrorAction Stop
            $token = New-AzStorageBlobSASToken -CloudBlob $content.ICloudBlob -StartTime (Get-Date) -ExpiryTime $(Get-Date).AddHours(1) -Protocol HttpsOnly -Context $sa.Context -Permission r -ErrorAction Stop
            $uri = '{0}{1}/{2}{3}' -f $co.Context.BlobEndpoint, 'customscriptextension', $(Split-Path -Path $tempFileName -Leaf), $token
            [version] $typehandler = (Get-AzVMExtensionImage -PublisherName Microsoft.Compute -Type CustomScriptExtension -Location (Get-LabAzureDefaultLocation).Location | Sort-Object { [version]$_.Version } | Select-Object -Last 1).Version
            
            $extArg = @{
                ResourceGroupName  = $lab.AzureSettings.DefaultResourceGroup.ResourceGroupName
                VMName             = $m.ResourceName
                FileUri            = $uri
                TypeHandlerVersion = '{0}.{1}' -f $typehandler.Major, $typehandler.Minor
                Name               = 'initcustomizations'
                Location           = (Get-LabAzureDefaultLocation).Location
                Run                = Split-Path -Path $tempFileName -Leaf
                NoWait             = $true
            }
            $Null = Set-AzVMCustomScriptExtension @extArg
        }
        else
        {
            Invoke-AzVMRunCommand -ResourceGroupName $rgName -VMName $m.ResourceName -ScriptPath $tempFileName -CommandId 'RunPowerShellScript' -ErrorAction Stop -AsJob
        }
    }

    if ($Wait)
    {
        Wait-LWLabJob -Job $jobs

        $results = $jobs | Receive-Job -Keep -ErrorAction SilentlyContinue -ErrorVariable +AL_AzureWinrmActivationErrors
        $failedJobs = $jobs | Where-Object -Property Status -eq 'Failed'

        if ($failedJobs)
        {
            $machineNames = $($($failedJobs).Name -replace "'").ForEach( { $($_ -split '\s')[-1] })
            Write-ScreenInfo -Type Error -Message ('Enabling CredSSP on the following lab machines failed: {0}. Check the output of "Get-Job -Id {1} | Receive-Job -Keep" as well as the variable $AL_AzureWinrmActivationErrors' -f $($machineNames -join ','), $($failedJobs.Id -join ','))
        }
    }

    if ($PassThru)
    {
        $jobs
    }

    Remove-Item $tempFileName -Force -ErrorAction SilentlyContinue
    Write-LogFunctionExit
}
