﻿function Get-LabImageOnWindows
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [char]
        $DriveLetter,

        [IO.FileInfo]
        $IsoFile
    )

    $dismPattern = 'Index : (?<Index>\d{1,2})(\r)?\nName : (?<Name>.+)'
    $standardImagePath = "$DriveLetter`:\Sources\Install.wim"
    $doNotSkipNonNonEnglishIso = Get-LabConfigurationItem -Name DoNotSkipNonNonEnglishIso
    
    if (Test-Path -Path $standardImagePath)
    {
        $dismOutput = Dism.exe /English /Get-WimInfo /WimFile:$standardImagePath
        $dismOutput = $dismOutput -join "`n"
        $dismMatches = $dismOutput | Select-String -Pattern $dismPattern -AllMatches
        Write-PSFMessage "The Windows Image list contains $($dismMatches.Matches.Count) items"

        foreach ($dismMatch in $dismMatches.Matches)
        {
            Write-ProgressIndicator
            $index = $dismMatch.Groups['Index'].Value
            $imageInfo = Get-WindowsImage -ImagePath $standardImagePath -Index $index

            if (($imageInfo.Languages -notlike '*en-us*') -and -not $doNotSkipNonNonEnglishIso)
            {
                Write-ScreenInfo "The windows image '$($imageInfo.ImageName)' in the ISO '$($IsoFile.Name)' has the language(s) '$($imageInfo.Languages -join ', ')'. AutomatedLab does only support images with the language 'en-us' hence this image will be skipped." -Type Warning
                continue
            }

            $os = New-Object -TypeName AutomatedLab.OperatingSystem($imageInfo.ImageName, $IsoFile.FullName)
            $os.OperatingSystemImageName = $dismMatch.Groups['Name'].Value
            $os.OperatingSystemName = $dismMatch.Groups['Name'].Value
            $os.Size = $imageInfo.Imagesize
            $os.Version = $imageInfo.Version
            $os.PublishedDate = $imageInfo.CreatedTime
            $os.Edition = $imageInfo.EditionId
            $os.Installation = $imageInfo.InstallationType
            $os.ImageIndex = $imageInfo.ImageIndex

            $os
        }
    }

    # SuSE, openSuSE et al
    $susePath = "$DriveLetter`:\content"
    if (Test-Path -Path $susePath -PathType Leaf)
    {
        $content = Get-Content -Path $susePath -Raw
        [void] ($content -match 'DISTRO\s+.+,(?<Distro>[a-zA-Z 0-9.]+)\n.*LINGUAS\s+(?<Lang>.*)\n(?:REGISTERPRODUCT.+\n){0,1}REPOID\s+.+((?<CreationTime>\d{8})|(?<Version>\d{2}\.\d{1}))\/(?<Edition>\w+)\/.*\nVENDOR\s+(?<Vendor>[a-zA-z ]+)')

        $os = New-Object -TypeName AutomatedLab.OperatingSystem($Matches.Distro, $IsoFile.FullName)
        $os.OperatingSystemImageName = $Matches.Distro
        $os.OperatingSystemName = $Matches.Distro
        $os.Size = $IsoFile.Length
        if ($Matches.Version -like '*.*')
        {
            $os.Version = $Matches.Version
        }
        elseif ($Matches.Version)
        {
            $os.Version = [AutomatedLab.Version]::new($Matches.Version, 0)
        }
        else
        {
            $os.Version = [AutomatedLab.Version]::new(0, 0)
        }

        $os.PublishedDate = if ($Matches.CreationTime)
        {
            [datetime]::ParseExact($Matches.CreationTime, 'yyyyMMdd', ([cultureinfo]'en-us'))
        }
        else
        {
            (Get-Item -Path $susePath).CreationTime
        }
        $os.Edition = $Matches.Edition

        $packages = Get-ChildItem "$DriveLetter`:\suse" -Filter pattern*.rpm -File -Recurse | ForEach-Object {
            if ( $_.Name -match '.*patterns-(openSUSE|SLE|sles)-(?<name>.*(32bit)?)-\d*-\d*\.\d*\.x86')
            {
                $Matches.name
            }
        }

        $os.LinuxPackageGroup = $packages

        $os
    }

    # RHEL, CentOS, Fedora et al
    $rhelPath = "$DriveLetter`:\.treeinfo" # TreeInfo Syntax https://release-engineering.github.io/productmd/treeinfo-1.0.html
    $rhelPackageInfo = "$DriveLetter`:\repodata"
    if (Test-Path -Path $rhelPath -PathType Leaf)
    {
        $generalInfo = (Get-Content -Path $rhelPath | Select-String '\[general\]' -Context 7).Context.PostContext| Where-Object -FilterScript { $_ -match '^\w+\s*=\s*\w+' }  | ConvertFrom-StringData -ErrorAction SilentlyContinue
        $versionInfo = if ($generalInfo.version.Contains('.')) { $generalInfo.version -as [Version] } else {[Version]::new($generalInfo.Version, 0)}

        $os = New-Object -TypeName AutomatedLab.OperatingSystem(('{0} {1}' -f $content.Family, $os.Version), $IsoFile.FullName)
        $os.OperatingSystemImageName = $content.Name
        $os.Size = $IsoFile.Length

        $packageXml = (Get-ChildItem -Path $rhelPackageInfo -Filter *comps*.xml | Select-Object -First 1).FullName
        if (-not $packageXml)
        {
            # CentOS ISO for some reason contained only GUIDs
            $packageXml = Get-ChildItem -Path $rhelPackageInfo -PipelineVariable file -File |
            Get-Content -TotalCount 10 |
            Where-Object { $_ -like "*<comps>*" } |
            ForEach-Object { $file.FullName } |
            Select-Object -First 1
        }

        if ($null -ne $packageXml)
        {
            [xml]$packageInfo = Get-Content -Path $packageXml -Raw
            $os.LinuxPackageGroup = (Select-Xml -XPath "/comps/group/id" -Xml $packageInfo).Node.InnerText
        }

        if ($generalInfo.version.Contains('.'))
        {
            $os.Version = $generalInfo.version
        }
        else
        {
            $os.Version = [AutomatedLab.Version]::new($generalInfo.version, 0)
        }

        $os.OperatingSystemName = $generalInfo.name

        # Unix time stamp...
        $os.PublishedDate = (Get-Item -Path $rhelPath).CreationTime
        $os.Edition = if ($generalInfo.Variant)
        {
            $content.Variant
        }
        else
        {
            'Server'
        }

        $os
    }
}
