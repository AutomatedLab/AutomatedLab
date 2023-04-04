function Mount-LabDiskImage
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingCmdletAliases", "")]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string]
        $ImagePath,

        [ValidateSet('ISO','VHD','VHDSet','VHDx','Unknown')]
        $StorageType,

        [switch]
        $PassThru
    )

    if (Get-Command -Name Mount-DiskImage -ErrorAction SilentlyContinue)
    {
        $diskImage = Mount-DiskImage -ImagePath $ImagePath -StorageType $StorageType -PassThru

        if ($PassThru.IsPresent)
        {
            $diskImage | Add-Member -MemberType NoteProperty -Name DriveLetter -Value ($diskImage | Get-Volume).DriveLetter -PassThru
        }
    }
    elseif ($IsLinux)
    {
        if (-not (Test-Path -Path /mnt/automatedlab))
        {
            $null = New-Item -Path /mnt/automatedlab -Force -ItemType Directory
        }

        $image = Get-Item -Path $ImagePath
        $null = mount -o loop $ImagePath /mnt/automatedlab/$($image.BaseName)
        [PSCustomObject]@{
            ImagePath   = $ImagePath
            FileSize    = $image.Length
            Size        = $image.Length
            DriveLetter = "/mnt/automatedlab/$($image.BaseName)"
        }
    }
    else
    {
        throw 'Neither Mount-DiskImage exists, nor is this a Linux system.'
    }
}
