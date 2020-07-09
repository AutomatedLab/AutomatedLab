Mounting ISO files on Azure is as simple as calling the existing cmdlet ``Mount-LabIsoImage``. The only difference is, that the ISO image file path lies on Azure. To find out which images are accessible in your AutomatedLab storage account you can do the following:  
``
    Login-AzureRmAccount
    (Get-LabAzureLabSourcesContent -RegexFilter \.iso).FullName
``

When mounting the ISO file, be sure to specify -PassThru to be able to use the drive letter that was used to mount the ISO in later commands:  

    $mountedVolume = Mount-LabIsoImage -IsoPath https://some/azure/path.iso -ComputerName DC1 -PassThru
    
    Invoke-LabCommand DC1 -ScriptBlock {
    param
    (
        $DriveLetter
    )

        Start-Process (Join-Path $DriveLetter "Path\To\My\Setup.exe")
    } -ArgumentList $mountedVolume.DriveLetter
