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
    $standardImagePath = Get-Item -Path "$DriveLetter`:\Sources\install.*" -ErrorAction SilentlyContinue | Where-Object Name -Match '.*\.(esd|wim)'
    $doNotSkipNonNonEnglishIso = Get-LabConfigurationItem -Name DoNotSkipNonNonEnglishIso
    
    if ($standardImagePath -and (Test-Path -Path $standardImagePath))
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
            try 
            {
                $os.Architecture = $imageInfo.Architecture
            }
            catch
            {
                $os.Architecture = 'Unknown'
            }

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

    # RHEL, CentOS, Fedora, OpenSuse Tumbleweed et al
    $rhelPath = "$DriveLetter`:\.treeinfo" # TreeInfo Syntax https://release-engineering.github.io/productmd/treeinfo-1.0.html
    $rhelPackageInfo = "$DriveLetter`:{0}\*\repodata"
    if (Test-Path -Path $rhelPath -PathType Leaf)
    {
        $contentMatch = (Get-Content -Path $rhelPath -Raw) -match '(?s)(?<=\[general\]).*?(?=\[)'
        if (-not $contentMatch)
        {
            throw "Unknown structure of $rhelPath. Cannot add ISO"
        }

        $generalInfo = $Matches.0 -replace ';.*' -split "`n" | ConvertFrom-String -Delimiter '=' -PropertyNames Name, Value
        $version = ([string]$generalInfo.Where({ $_.Name.Trim() -eq 'version' }).Value).Trim()
        $name = ([string]$generalInfo.Where({ $_.Name.Trim() -eq 'name' }).Value).Trim()
        $variant = ([string]$generalInfo.Where({ $_.Name.Trim() -eq 'variant' }).Value).Trim()
        $versionInfo = if (-not $version) { [Version]::new(1, 0, 0, 0) } elseif ($version.Contains('.')) { $version -as [Version] } else { [Version]::new($Version, 0) }
        $arch = if (([string]$generalInfo.Where({ $_.Name.Trim() -eq 'arch' }).Value).Trim() -eq 'x86_64') { 'x64' } else { 'x86' }

        if ($variant -and $versionInfo -ge '8.0')
        {
            $rhelPackageInfo = $rhelPackageInfo -f "\$variant"
        }
        else
        {
            $rhelPackageInfo = $rhelPackageInfo -f $null
        }

        $os = New-Object -TypeName AutomatedLab.OperatingSystem($name, $IsoFile.FullName)
        $os.OperatingSystemImageName = $name
        $os.Size = $IsoFile.Length
        $os.Architecture = $arch

        $packageXml = (Get-ChildItem -Path $rhelPackageInfo -Filter *comps*.xml -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
        if (-not $packageXml)
        {
            # CentOS ISO for some reason contained only GUIDs
            $packageXml = Get-ChildItem -Path $rhelPackageInfo -ErrorAction SilentlyContinue -PipelineVariable file -File |
            Get-Content -TotalCount 10 |
            Where-Object { $_ -like "*<comps>*" } |
            ForEach-Object { $file.FullName } |
            Select-Object -First 1
        }

        if ($packageXml)
        {
            [xml]$packageInfo = Get-Content -Path $packageXml -Raw
            $os.LinuxPackageGroup.AddRange([string[]]((Select-Xml -XPath "/comps/group/id" -Xml $packageInfo).Node.InnerText | ForEach-Object { "@$_" }) )
            $os.LinuxPackageGroup.AddRange([string[]]((Select-Xml -XPath "/comps/environment/id" -Xml $packageInfo).Node.InnerText | ForEach-Object { "@^$_" }) )
        }

        $os.Version = $versionInfo
        $os.OperatingSystemName = $name

        # Unix time stamp...
        $os.PublishedDate = (Get-Item -Path $rhelPath).CreationTime
        $os.Edition = if ($variant)
        {
            $variant
        }
        else
        {
            'Server'
        }

        $os
    }

    # Ubuntu 2004+, Kali
    $ubuntuPath = "$DriveLetter`:\.disk\info"
    $ubuntuPackageInfo = "$DriveLetter`:\pool\main"
    if (Test-Path -Path $ubuntuPath -PathType Leaf)
    {
        $infoContent = Get-Content -Path $ubuntuPath -TotalCount 1
        if ($infoContent -like 'Kali*')
        {
            $null = $infoContent -match '(?:Kali GNU\/Linux)?\s+(?<Version>\d\d\d\d\.\d).*\s+"(?<Name>[\w-]+)".*Official\s(?<Arch>i386|amd64).*(?<ReleaseDate>\d{8})'
            $osversion = $Matches.Version
            $name = 'Kali Linux {0}' -f $osversion
        }
        else
        {
            $null = $infoContent -match '(?:Ubuntu)(?:-Server)?\s+(?<Version>\d\d\.\d\d).*Release\s(?<Arch>i386|amd64)\s\((?<ReleaseDate>\d{8})'
            $osversion = $Matches.Version
            $name = ($infoContent -split '\s-\s')[0]
            if (([version]$osversion) -lt '20.4')
            {
                Write-ScreenInfo -Type Error -Message "Skipping $IsoFile, AutomatedLab was only tested with 20.04 and newer."
            }
        }

        $osDate = $Matches.ReleaseDate

        $os = New-Object -TypeName AutomatedLab.OperatingSystem($name, $IsoFile.FullName)
        if ($Matches.Arch -eq 'i386')
        {
            $os.Architecture = 'x86'
        }
        else
        {
            $os.Architecture = 'x64'
        }
        $os.OperatingSystemImageName = $name
        $os.Size = $IsoFile.Length
        $os.Version = $osversion
        $os.PublishedDate = [datetime]::ParseExact($osDate, 'yyyyMMdd', [cultureinfo]::CurrentCulture)
        $os.Edition = if ($infoContent -match '-Server') { 'Server' } else { 'Desktop' }

        foreach ($package in (Get-ChildItem -Directory -Recurse -Path $ubuntuPackageInfo))
        {
            if ($package.Parent.Name -eq 'main') { continue }

            $null = $os.LinuxPackageGroup.Add($package.Name)
        }

        $os
    }
}
