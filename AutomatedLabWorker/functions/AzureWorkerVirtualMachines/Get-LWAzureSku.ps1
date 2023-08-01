function Get-LWAzureSku
{
    [Cmdletbinding()]
    param
    (
        [Parameter(Mandatory)]
        [AutomatedLab.Machine]$Machine
    )

    $lab = Get-Lab

    #if this machine has a SQL Server role
    foreach ($role in $Machine.Roles)
    {
        if ($role.Name -match 'SQLServer(?<SqlVersion>\d{4})')
        {
            #get the SQL Server version defined in the role
            $sqlServerRoleName = $Matches[0]
            $sqlServerVersion = $Matches.SqlVersion

            if ($role.Properties.Keys | Where-Object { $_ -ne 'InstallSampleDatabase' })
            {
                $useStandardVm = $true
            }
        }

        if ($role.Name -match 'VisualStudio(?<Version>\d{4})')
        {
            $visualStudioRoleName = $Matches[0]
            $visualStudioVersion = $Matches.Version
        }
    }

    if ($sqlServerRoleName -and -not $useStandardVm)
    {
        Write-PSFMessage -Message 'This is going to be a SQL Server VM'
        $pattern = 'SQL(?<SqlVersion>\d{4})(?<SqlIsR2>R2)??(?<SqlServicePack>SP\d)?-(?<OS>WS\d{4}(R2)?)'

        #get all SQL images matching the RegEx pattern and then get only the latest one
        $sqlServerImages = $lab.AzureSettings.VmImages | Where-Object Offer -notlike "*BYOL*"

        if ([System.Convert]::ToBoolean($Machine.AzureProperties['UseByolImage']))
        {
            $sqlServerImages = $lab.AzureSettings.VmImages | Where-Object Offer -like '*-BYOL'
        }

        $sqlServerImages = $sqlServerImages |
        Where-Object Offer -Match $pattern |
        Group-Object -Property Sku, Offer |
        ForEach-Object {
            $_.Group | Sort-Object -Property PublishedDate -Descending | Select-Object -First 1
        }

        #add the version, SP Level and OS from the ImageFamily field to the image object
        foreach ($sqlServerImage in $sqlServerImages)
        {
            $sqlServerImage.Offer -match $pattern | Out-Null

            $sqlServerImage | Add-Member -Name SqlVersion -Value $Matches.SqlVersion -MemberType NoteProperty -Force
            $sqlServerImage | Add-Member -Name SqlIsR2 -Value $Matches.SqlIsR2 -MemberType NoteProperty -Force
            $sqlServerImage | Add-Member -Name SqlServicePack -Value $Matches.SqlServicePack -MemberType NoteProperty -Force

            $sqlServerImage | Add-Member -Name OS -Value (New-Object AutomatedLab.OperatingSystem($Matches.OS)) -MemberType NoteProperty -Force
        }

        #get the image that matches the OS and SQL server version
        $machineOs = New-Object AutomatedLab.OperatingSystem($machine.OperatingSystem)
        $vmImage = $sqlServerImages | Where-Object { $_.SqlVersion -eq $sqlServerVersion -and $_.OS.Version -eq $machineOs.Version } |
        Sort-Object -Property SqlServicePack -Descending | Select-Object -First 1
        $offerName = $vmImageName = $vmImage.Offer
        $publisherName = $vmImage.PublisherName
        $skusName = $vmImage.Skus

        if (-not $vmImageName)
        {
            Write-ScreenInfo 'SQL Server image could not be found. The following combinations are currently supported by Azure:' -Type Warning
            foreach ($sqlServerImage in $sqlServerImages)
            {
                Write-PSFMessage -Level Host $sqlServerImage.Offer
            }

            throw "There is no Azure VM image for '$sqlServerRoleName' on operating system '$($machine.OperatingSystem)'. The machine cannot be created. Cancelling lab setup. Please find the available images above."
        }
    }
    elseif ($visualStudioRoleName)
    {
        Write-PSFMessage -Message 'This is going to be a Visual Studio VM'

        $pattern = 'VS-(?<Version>\d{4})-(?<Edition>\w+)-VSU(?<Update>\d)-AzureSDK-\d{2,3}-((?<OS>WIN\d{2})|(?<OS>WS\d{4,6}))'

        #get all SQL images machting the RegEx pattern and then get only the latest one
        $visualStudioImages = $lab.AzureSettings.VmImages |
        Where-Object Offer -EQ VisualStudio

        #add the version, SP Level and OS from the ImageFamily field to the image object
        foreach ($visualStudioImage in $visualStudioImages)
        {
            $visualStudioImage.Skus -match $pattern | Out-Null

            $visualStudioImage | Add-Member -Name Version -Value $Matches.Version -MemberType NoteProperty -Force
            $visualStudioImage | Add-Member -Name Update -Value $Matches.Update -MemberType NoteProperty -Force

            $visualStudioImage | Add-Member -Name OS -Value (New-Object AutomatedLab.OperatingSystem($Matches.OS)) -MemberType NoteProperty -Force
        }

        #get the image that matches the OS and SQL server version
        $machineOs = New-Object AutomatedLab.OperatingSystem($machine.OperatingSystem)
        $vmImage = $visualStudioImages | Where-Object { $_.Version -eq $visualStudioVersion -and $_.OS.Version.Major -eq $machineOs.Version.Major } |
        Sort-Object -Property Update -Descending | Select-Object -First 1
        $offerName = $vmImageName = ($vmImage).Offer
        $publisherName = ($vmImage).PublisherName
        $skusName = ($vmImage).Skus

        if (-not $vmImageName)
        {
            Write-ScreenInfo 'Visual Studio image could not be found. The following combinations are currently supported by Azure:' -Type Warning
            foreach ($visualStudioImage in $visualStudioImages)
            {
                Write-ScreenInfo ('{0} - {1} - {2}' -f $visualStudioImage.Offer, $visualStudioImage.Skus, $visualStudioImage.Id)
            }

            throw "There is no Azure VM image for '$visualStudioRoleName' on operating system '$($machine.OperatingSystem)'. The machine cannot be created. Cancelling lab setup. Please find the available images above."
        }
    }
    else
    {
        $vmImageName = (New-Object AutomatedLab.OperatingSystem($machine.OperatingSystem)).AzureImageName
        if (-not $vmImageName)
        {
            throw "There is no Azure VM image for the operating system '$($Machine.OperatingSystem)'. The machine cannot be created. Cancelling lab setup."
        }

        $vmImage = $lab.AzureSettings.VmImages |
        Where-Object { "$($_.Skus)_$($_.PublisherName)" -eq $vmImageName } |
        Select-Object -First 1

        $offerName = $vmImageName = ($vmImage).Offer
        $publisherName = ($vmImage).PublisherName
        $skusName = ($vmImage).Skus
    }

    Write-PSFMessage -Message "We selected the SKUs $skusName from offer $offerName by publisher $publisherName"
    @{
        offer     = $offerName
        publisher = $publisherName
        sku       = $skusName
        version   = 'latest'
    }
}
