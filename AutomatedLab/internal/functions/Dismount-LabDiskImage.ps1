function Dismount-LabDiskImage
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "")]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string]
        $ImagePath
    )

    if (Get-Command -Name Dismount-DiskImage -ErrorAction SilentlyContinue)
    {
        Dismount-DiskImage -ImagePath $ImagePath
    }
    elseif ($IsLinux)
    {
        $image = Get-Item -Path $ImagePath
        $null = umount /mnt/automatedlab/$($image.BaseName)
    }
    else
    {
        throw 'Neither Dismount-DiskImage exists, nor is this a Linux system.'
    }
}
