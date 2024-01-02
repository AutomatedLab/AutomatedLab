Param (

    [Parameter(Mandatory)]
    [String]$ComputerName,

    [Parameter(Mandatory)]
    [String]$LogViewer

)

#region Define functions
function New-Shortcut {
    Param (
        [Parameter(Mandatory=$true)]
        [String]$Target,
        [Parameter(Mandatory=$false)]
        [String]$TargetArguments,
        [Parameter(Mandatory=$true)]
        [String]$ShortcutName
    )
    $Path = "{0}\{1}" -f [System.Environment]::GetFolderPath("Desktop"), $ShortcutName
    switch ($ShortcutName.EndsWith(".lnk")) {
        $false {
            $ShortcutName = $ShortcutName + ".lnk"
        }
    }
    switch (Test-Path -LiteralPath $Path) {
        $true {
            Write-Warning ("Shortcut already exists: {0}" -f (Split-Path $Path -Leaf))
        }
        $false {
            $WshShell = New-Object -comObject WScript.Shell
            $Shortcut = $WshShell.CreateShortcut($Path)
            $Shortcut.TargetPath = $Target
            If ($null -ne $TargetArguments) {
                $Shortcut.Arguments = $TargetArguments
            }
            $Shortcut.Save()
        }
    }
}

function Add-FileAssociation {
    <#
            .SYNOPSIS
            Set user file associations
            .DESCRIPTION
            Define a program to open a file extension
            .PARAMETER Extension
            The file extension to modify
            .PARAMETER TargetExecutable
            The program to use to open the file extension
            .PARAMETER ftypeName
            Non mandatory parameter used to override the created file type handler value
            .EXAMPLE
            $HT = @{
            Extension = '.txt'
            TargetExecutable = "C:\Program Files\Notepad++\notepad++.exe"
            }
            Add-FileAssociation @HT
            .EXAMPLE
            $HT = @{
            Extension = '.xml'
            TargetExecutable = "C:\Program Files\Microsoft VS Code\Code.exe"
            FtypeName = 'vscode'
            }
            Add-FileAssociation @HT
            .NOTES
            Found here: https://gist.github.com/p0w3rsh3ll/c64d365d15f6f39116dba1a26981dc68#file-add-fileassociation-ps1 https://p0w3rsh3ll.wordpress.com/2018/11/08/about-file-associations/
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^\.[a-zA-Z0-9]{1,3}')]
        $Extension,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
                    Test-Path -Path $_ -PathType Leaf
        })]
        [String]$TargetExecutable,
        [String]$ftypeName
    )
    Begin {
        $ext = [Management.Automation.Language.CodeGeneration]::EscapeSingleQuotedStringContent($Extension)
        $exec = [Management.Automation.Language.CodeGeneration]::EscapeSingleQuotedStringContent($TargetExecutable)
    
        # 2. Create a ftype
        if (-not($PSBoundParameters['ftypeName'])) {
            $ftypeName = '{0}{1}File'-f $($ext -replace '\.',''),
            $((Get-Item -Path "$($exec)").BaseName)
            $ftypeName = [Management.Automation.Language.CodeGeneration]::EscapeFormatStringContent($ftypeName)
        } else {
            $ftypeName = [Management.Automation.Language.CodeGeneration]::EscapeSingleQuotedStringContent($ftypeName)
        }
        Write-Verbose -Message "Ftype name set to $($ftypeName)"
    }
    Process {
        # 1. remove anti-tampering protection if required
        if (Test-Path -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$($ext)") {
            $ParentACL = Get-Acl -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$($ext)"
            if (Test-Path -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$($ext)\UserChoice") {
                $k = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey("Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$($ext)\UserChoice",'ReadWriteSubTree','TakeOwnership')
                $acl  = $k.GetAccessControl()
                $null = $acl.SetAccessRuleProtection($false,$true)
                $rule = New-Object System.Security.AccessControl.RegistryAccessRule ($ParentACL.Owner,'FullControl','Allow')
                $null = $acl.SetAccessRule($rule)
                $rule = New-Object System.Security.AccessControl.RegistryAccessRule ($ParentACL.Owner,'SetValue','Deny')
                $null = $acl.RemoveAccessRule($rule)
                $null = $k.SetAccessControl($acl)
                Write-Verbose -Message 'Removed anti-tampering protection'
            }
        }
        # 2. add a ftype
        $null = & (Get-Command "$($env:systemroot)\system32\reg.exe") @(
            'add',
            "HKCU\Software\Classes\$($ftypeName)\shell\open\command"
            '/ve','/d',"$('\"{0}\" \"%1\"'-f $($exec))",
            '/f','/reg:64'
        )
        Write-Verbose -Message "Adding command under HKCU\Software\Classes\$($ftypeName)\shell\open\command"
        # 3. Update user file association

        # Reg2CI (c) 2019 by Roger Zander
        Remove-Item -LiteralPath ("HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\{0}\OpenWithList" -f $ext) -ErrorAction "SilentlyContinue" -Force
        if((Test-Path -LiteralPath ("HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\{0}\OpenWithList" -f $ext)) -ne $true) { 
            New-Item ("HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\{0}\OpenWithList" -f $ext) -Force -ErrorAction "SilentlyContinue" | Out-Null
        }
        Remove-Item -LiteralPath ("HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\{0}\OpenWithProgids" -f $ext) -ErrorAction "SilentlyContinue" -Force
        if((Test-Path -LiteralPath ("HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\{0}\OpenWithProgids" -f $ext)) -ne $true) { 
            New-Item ("HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\{0}\OpenWithProgids" -f $ext) -Force -ErrorAction "SilentlyContinue" | Out-Null
        }
        if((Test-Path -LiteralPath ("HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\{0}\UserChoice" -f $ext)) -ne $true) {
            New-Item ("HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\{0}\UserChoice" -f $ext) -Force -ErrorAction "SilentlyContinue" | Out-Null
        }
        New-ItemProperty -LiteralPath ("HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\{0}\OpenWithList" -f $ext) -Name "MRUList" -Value "a" -PropertyType String -Force -ErrorAction "SilentlyContinue" | Out-Null
        New-ItemProperty -LiteralPath ("HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\{0}\OpenWithList" -f $ext) -Name "a" -Value ("{0}" -f (Get-Item -Path $exec | Select-Object -ExpandProperty Name)) -PropertyType String -Force -ErrorAction "SilentlyContinue" | Out-Null
        New-ItemProperty -LiteralPath ("HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\{0}\OpenWithProgids" -f $ext) -Name $ftypeName -Value (New-Object Byte[] 0) -PropertyType None -Force -ErrorAction "SilentlyContinue" | Out-Null
        Remove-ItemProperty -LiteralPath ("HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\{0}\UserChoice" -f $ext) -Name "Hash" -Force -ErrorAction "SilentlyContinue"
        Remove-ItemProperty -LiteralPath ("HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\{0}\UserChoice" -f $ext) -Name "Progid" -Force  -ErrorAction "SilentlyContinue"
    }
}

function Set-CMCustomisations {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)]
        [String]$CMServerName,

        [Parameter(Mandatory)]
        [String]$LogViewer
    )

    #region Initialise
    $PSDefaultParameterValues = @{
        "Invoke-LabCommand:ComputerName"            = $CMServerName
        "Invoke-LabCommand:AsJob"                   = $true
        "Invoke-LabCommand:PassThru"                = $true
        "Invoke-LabCommand:NoDisplay"               = $true
        "Invoke-LabCommand:Retries"                 = 1
        "Wait-LWLabJob:NoDisplay"                   = $true
    }
    #endregion

    #region Install SupportCenter
    # Did try using Install-LabSoftwarePackage but msiexec hung, no install attempt made according to event viewer nor log file created
    # Almost as if there's a syntax error with msiexec and you get that pop up dialogue with usage, but syntax was fine
    Write-ScreenInfo -Message "Installing SupportCenter" -TaskStart
    $job = Invoke-LabCommand -ActivityName "Installing SupportCenter" -ScriptBlock {
        Start-Process -FilePath "C:\Program Files\Microsoft Configuration Manager\cd.latest\SMSSETUP\Tools\SupportCenter\SupportCenterInstaller.msi" -ArgumentList "/qn","/norestart" -Wait -ErrorAction "Stop"
    }
    Wait-LWLabJob -Job $job
    try {
        $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
    }
    catch {
        Write-ScreenInfo -Message ("Failed to install SupportCenter ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -Type "Warning"
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion

    #region Setting file associations and desktop shortcut for log files
    Write-ScreenInfo -Message "Setting file associations and desktop shortcut for log files" -TaskStart
    $job = Invoke-LabCommand -ActivityName "Setting file associations for CMTrace and creating desktop shortcuts" -Function (Get-Command "Add-FileAssociation", "New-Shortcut") -Variable (Get-Variable -Name "LogViewer") -ScriptBlock {
        switch ($LogViewer) {
            "OneTrace" {
                if (Test-Path "C:\Program Files (x86)\Configuration Manager Support Center\CMPowerLogViewer.exe") {
                    $LogApplication = "C:\Program Files (x86)\Configuration Manager Support Center\CMPowerLogViewer.exe"
                }
                else {
                    $LogApplication = "C:\Program Files\Microsoft Configuration Manager\tools\cmtrace.exe"
                }
            }
            default {
                $LogApplication = "C:\Program Files\Microsoft Configuration Manager\tools\cmtrace.exe"
            }
        }
        Add-FileAssociation -Extension ".log" -TargetExecutable $LogApplication
        Add-FileAssociation -Extension ".lo_" -TargetExecutable $LogApplication
        New-Shortcut -Target "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\Microsoft.ConfigurationManagement.exe" -ShortcutName "Configuration Manager Console.lnk"
        New-Shortcut -Target "C:\Program Files\Microsoft Configuration Manager\Logs" -ShortcutName "Logs.lnk"
        if (Test-Path "C:\Program Files (x86)\Configuration Manager Support Center\ConfigMgrSupportCenter.exe") { New-Shortcut -Target "C:\Program Files (x86)\Configuration Manager Support Center\ConfigMgrSupportCenter.exe" -ShortcutName "Support Center.lnk" }
        if (Test-Path "C:\Tools") { New-Shortcut -Target "C:\Tools" -ShortcutName "Tools.lnk" }
    }
    Wait-LWLabJob -Job $job
    try {
        $result = $job | Receive-Job -ErrorAction "Stop" -ErrorVariable "ReceiveJobErr"
    }
    catch {
        Write-ScreenInfo -Message ("Failed to create file associations and desktop shortcut for log files ({0})" -f $ReceiveJobErr.ErrorRecord.Exception.Message) -Type "Warning"
    }
    Write-ScreenInfo -Message "Activity done" -TaskEnd
    #endregion
}
#endregion

Write-ScreenInfo -Message "Applying customisations" -TaskStart
Import-Lab -Name $LabName -NoValidation -NoDisplay
Set-CMCustomisations -CMServerName $ComputerName -LogViewer $LogViewer
Write-ScreenInfo -Message "Finished applying customisations" -TaskEnd
