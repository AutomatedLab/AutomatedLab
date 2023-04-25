function Remove-LabDeploymentFiles
{

    Invoke-LabCommand -ComputerName (Get-LabVM) -ActivityName 'Remove deployment files (files used during deployment)' -AsJob -NoDisplay -ScriptBlock `
    {
        $paths = 'C:\Unattend.xml',
            'C:\WSManRegKey.reg',
            'C:\AdditionalDisksOnline.ps1',
            'C:\WinRmCustomization.ps1',
            'C:\DeployDebug',
            'C:\ALLibraries',
            "C:\$($env:COMPUTERNAME).cer"
            
        $paths | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    }
}
