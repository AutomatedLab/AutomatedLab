#region Internals
$script:RedHatPackage = New-Object -TypeName System.Collections.Generic.HashSet[string]
$script:SusePackage = New-Object -TypeName System.Collections.Generic.HashSet[string]
$unattendedXmlDefaultContent2012 = @'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
  <settings pass="generalize">
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <DoNotCleanTaskBar>true</DoNotCleanTaskBar>
    </component>
    <component name="Microsoft-Windows-Security-SPP" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <SkipRearm>1</SkipRearm>
    </component>
  </settings>
  <settings pass="specialize">
    <component name="Microsoft-Windows-UnattendedJoin" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
      <Identification>
        <JoinWorkgroup xmlns="">NET</JoinWorkgroup>
      </Identification>
    </component>
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
      <ComputerName>SERVER</ComputerName>
      <RegisteredOrganization>vm.net</RegisteredOrganization>
      <RegisteredOwner>NA</RegisteredOwner>
      <DoNotCleanTaskBar>true</DoNotCleanTaskBar>
      <TimeZone>UTC</TimeZone>
    </component>
    <component name="Microsoft-Windows-IE-InternetExplorer" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <Home_Page>about:blank</Home_Page>
      <DisableFirstRunWizard>true</DisableFirstRunWizard>
      <DisableOOBAccelerators>true</DisableOOBAccelerators>
      <DisableDevTools>true</DisableDevTools>
      <LocalIntranetSites></LocalIntranetSites>
      <TrustedSites></TrustedSites>
    </component>
    <component name="Microsoft-Windows-TerminalServices-RDP-WinStationExtensions" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <UserAuthentication>0</UserAuthentication>
    </component>
    <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <RunSynchronous>
        <RunSynchronousCommand wcm:action="add">
          <Description>EnableAdmin</Description>
          <Order>1</Order>
          <Path>cmd /c net user Administrator /active:yes</Path>
        </RunSynchronousCommand>
        <RunSynchronousCommand wcm:action="add">
          <Description>UnfilterAdministratorToken</Description>
          <Order>2</Order>
          <Path>cmd /c reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v FilterAdministratorToken /t REG_DWORD /d 0 /f</Path>
        </RunSynchronousCommand>
        <RunSynchronousCommand wcm:action="add">
          <Description>Remove First Logon Animation</Description>
          <Order>3</Order>
          <Path>cmd /c reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v EnableFirstLogonAnimation /d 0 /t REG_DWORD /f</Path>
        </RunSynchronousCommand>
        <RunSynchronousCommand wcm:action="add">
          <Description>Do Not Open Server Manager At Logon</Description>
          <Order>4</Order>
          <Path>cmd /c reg add "HKLM\SOFTWARE\Microsoft\ServerManager" /v "DoNotOpenServerManagerAtLogon" /d 1 /t REG_DWORD /f</Path>
        </RunSynchronousCommand>
        <RunSynchronousCommand wcm:action="add">
            <Description>Do not Open Initial Configuration Tasks At Logon</Description>
            <Order>5</Order>
            <Path>cmd /c reg add "HKLM\SOFTWARE\Microsoft\ServerManager\oobe" /v "DoNotOpenInitialConfigurationTasksAtLogon" /d 1 /t REG_DWORD /f</Path>
        </RunSynchronousCommand>
        <RunSynchronousCommand wcm:action="add">
            <Description>Set Power Scheme to High Performance</Description>
            <Order>6</Order>
            <Path>cmd /c powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c</Path>
        </RunSynchronousCommand>
        <RunSynchronousCommand wcm:action="add">
            <Description>Don't require password when console wakes up</Description>
            <Order>7</Order>
            <Path>cmd /c powercfg -setacvalueindex 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c fea3413e-7e05-4911-9a71-700331f1c294 0e796bdb-100d-47d6-a2d5-f7d2daa51f51 0</Path>
        </RunSynchronousCommand>
        <RunSynchronousCommand wcm:action="add">
            <Description>Sleep timeout</Description>
            <Order>8</Order>
            <Path>cmd /c powercfg -setacvalueindex 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 238c9fa8-0aad-41ed-83f4-97be242c8f20 29f6c1db-86da-48c5-9fdb-f2b67b1f44da 0</Path>
        </RunSynchronousCommand>
        <RunSynchronousCommand wcm:action="add">
            <Description>monitor timeout</Description>
            <Order>9</Order>
            <Path>cmd /c powercfg -setacvalueindex 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e 0</Path>
        </RunSynchronousCommand>
        <RunSynchronousCommand wcm:action="add">
            <Description>Enable PowerShell Remoting 1</Description>
            <Order>10</Order>
            <Path>cmd /c winrm quickconfig -quiet</Path>
        </RunSynchronousCommand>
        <RunSynchronousCommand wcm:action="add">
            <Description>Enable PowerShell Remoting 2</Description>
            <Order>11</Order>
            <Path>cmd /c winrm quickconfig -quiet -force</Path>
        </RunSynchronousCommand>
        <RunSynchronousCommand wcm:action="add">
            <Description>Enable PowerShell Remoting 3</Description>
            <Order>12</Order>
            <Path>cmd /c reg add HKLM\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell /v ExecutionPolicy /t REG_SZ /d Unrestricted /f</Path>
        </RunSynchronousCommand>
        <RunSynchronousCommand wcm:action="add">
            <Description>Disable UAC</Description>
            <Order>13</Order>
            <Path>cmd /c reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\policies\system /v EnableLUA /t REG_DWORD /d 0 /f</Path>
        </RunSynchronousCommand>
        <RunSynchronousCommand wcm:action="add">
            <Description>Configure BgInfo to start automatically</Description>
            <Order>14</Order>
            <Path>cmd /c reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run /v BgInfo /t REG_SZ /d "C:\Windows\BgInfo.exe C:\Windows\BgInfo.bgi /Timer:0 /nolicprompt" /f</Path>
        </RunSynchronousCommand>
        <RunSynchronousCommand wcm:action="add">
            <Description>Enable Remote Desktop firewall rules</Description>
            <Order>15</Order>
            <Path>cmd /c netsh advfirewall Firewall set rule group="Remote Desktop" new enable=yes</Path>
        </RunSynchronousCommand>
      </RunSynchronous>
    </component>
    <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <InputLocale>0409:00000409</InputLocale>
      <SystemLocale>EN-US</SystemLocale>
      <UILanguage>EN-US</UILanguage>
      <UserLocale>EN-US</UserLocale>
    </component>
    <component name="Microsoft-Windows-TapiSetup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <TapiConfigured>0</TapiConfigured>
      <TapiUnattendLocation>
        <AreaCode>""</AreaCode>
        <CountryOrRegion>1</CountryOrRegion>
        <LongDistanceAccess>9</LongDistanceAccess>
        <OutsideAccess>9</OutsideAccess>
        <PulseOrToneDialing>1</PulseOrToneDialing>
        <DisableCallWaiting>""</DisableCallWaiting>
        <InternationalCarrierCode>""</InternationalCarrierCode>
        <LongDistanceCarrierCode>""</LongDistanceCarrierCode>
        <Name>Default</Name>
      </TapiUnattendLocation>
    </component>
    <component name="Microsoft-Windows-IE-ESC" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <IEHardenAdmin>false</IEHardenAdmin>
      <IEHardenUser>false</IEHardenUser>
    </component>
    <component name="Microsoft-Windows-TerminalServices-LocalSessionManager" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <fDenyTSConnections>false</fDenyTSConnections>
    </component>
    <component name="Networking-MPSSVC-Svc" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" />
    <component name="Microsoft-Windows-TCPIP" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" />
    <component name="Microsoft-Windows-DNS-Client" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" />
    <component name="Microsoft-Windows-NetBT" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" />
  </settings>
  <settings pass="oobeSystem">
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
      <FirstLogonCommands>
        <SynchronousCommand wcm:action="add">
            <CommandLine>winrm quickconfig -quiet</CommandLine>
            <Description>Enable Windows Remoting</Description>
            <Order>1</Order>
        </SynchronousCommand>
        <SynchronousCommand wcm:action="add">
            <CommandLine>winrm quickconfig -quiet -force</CommandLine>
            <Description>Enable Windows Remoting</Description>
            <Order>2</Order>
        </SynchronousCommand>
        <SynchronousCommand wcm:action="add">
            <CommandLine>winrm set winrm/config/service/auth @{CredSSP="true"}</CommandLine>
            <Description>Enable Windows Remoting CredSSP</Description>
            <Order>3</Order>
        </SynchronousCommand>
        <SynchronousCommand wcm:action="add">
            <Description>Bring all additional disks online</Description>
            <Order>4</Order>
            <CommandLine>PowerShell -File C:\AdditionalDisksOnline.ps1</CommandLine>
        </SynchronousCommand>
		<SynchronousCommand wcm:action="add">
            <Description>Disable .net Optimization</Description>
            <Order>5</Order>
            <CommandLine>PowerShell -Command "schtasks.exe /query /FO CSV | ConvertFrom-Csv | Where-Object { $_.TaskName -like '*NGEN*' } | ForEach-Object { schtasks.exe /Change /TN $_.TaskName /Disable }"</CommandLine>
        </SynchronousCommand>
      </FirstLogonCommands>
      <UserAccounts>
        <AdministratorPassword>
          <Value>Password1</Value>
          <PlainText>true</PlainText>
        </AdministratorPassword>
        <LocalAccounts>
          <LocalAccount wcm:action="add">
            <Password>
              <Value>Password1</Value>
              <PlainText>true</PlainText>
            </Password>
            <Group>Administrators</Group>
            <DisplayName>AL</DisplayName>
            <Name>AL</Name>
          </LocalAccount>
        </LocalAccounts>
      </UserAccounts>
      <OOBE>
        <HideEULAPage>true</HideEULAPage>
        <NetworkLocation>Work</NetworkLocation>
        <ProtectYourPC>3</ProtectYourPC>
        <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
        <HideLocalAccountScreen>true</HideLocalAccountScreen>
        <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
      </OOBE>
      <RegisteredOrganization>vm.net</RegisteredOrganization>
      <RegisteredOwner>NA</RegisteredOwner>
    </component>
    <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <InputLocale>0409:00000409</InputLocale>
      <SystemLocale>En-US</SystemLocale>
      <UILanguage>EN-US</UILanguage>
      <UserLocale>EN-Us</UserLocale>
    </component>
  </settings>
</unattend>
'@

$unattendedXmlDefaultContent2008 = @'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
  <settings pass="generalize">
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <DoNotCleanTaskBar>true</DoNotCleanTaskBar>
    </component>
    <component name="Microsoft-Windows-Security-SPP" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <SkipRearm>1</SkipRearm>
    </component>
  </settings>
  <settings pass="specialize">
    <component name="Microsoft-Windows-UnattendedJoin" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
      <Identification>
        <JoinWorkgroup xmlns="">NET</JoinWorkgroup>
      </Identification>
    </component>
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
      <ComputerName>SERVER</ComputerName>
      <RegisteredOrganization>vm.net</RegisteredOrganization>
      <RegisteredOwner>NA</RegisteredOwner>
      <DoNotCleanTaskBar>true</DoNotCleanTaskBar>
      <TimeZone>UTC</TimeZone>
    </component>
    <component name="Microsoft-Windows-IE-InternetExplorer" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <Home_Page>about:blank</Home_Page>
      <DisableFirstRunWizard>true</DisableFirstRunWizard>
      <DisableOOBAccelerators>true</DisableOOBAccelerators>
      <DisableDevTools>true</DisableDevTools>
      <LocalIntranetSites>http://*.vm.net;https://*.vm.net</LocalIntranetSites>
      <TrustedSites>https://*.vm.net</TrustedSites>
    </component>
    <component name="Microsoft-Windows-TerminalServices-RDP-WinStationExtensions" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <UserAuthentication>0</UserAuthentication>
    </component>
    <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <RunSynchronous>
        <RunSynchronousCommand wcm:action="add">
            <Description>Disable and stop Windows Firewall 1</Description>
            <Order>1</Order>
            <Path>cmd /c sc config MpsSvc start=disabled</Path>
        </RunSynchronousCommand>
        <RunSynchronousCommand wcm:action="add">
            <Description>Disable and stop Windows Firewall 2</Description>
            <Order>2</Order>
            <Path>cmd /c sc stop MpsSvc</Path>
        </RunSynchronousCommand>
        <RunSynchronousCommand wcm:action="add">
            <Description>EnableAdmin</Description>
            <Order>3</Order>
            <Path>cmd /c net user Administrator /active:yes</Path>
        </RunSynchronousCommand>
        <RunSynchronousCommand wcm:action="add">
            <Description>UnfilterAdministratorToken</Description>
            <Order>4</Order>
            <Path>cmd /c reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v FilterAdministratorToken /t REG_DWORD /d 0 /f</Path>
        </RunSynchronousCommand>
        <RunSynchronousCommand wcm:action="add">
            <Description>Remove First Logon Animation</Description>
            <Order>5</Order>
            <Path>cmd /c reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v EnableFirstLogonAnimation /d 0 /t REG_DWORD /f</Path>
        </RunSynchronousCommand>
        <RunSynchronousCommand wcm:action="add">
            <Description>Do Not Open Server Manager At Logon</Description>
            <Order>6</Order>
            <Path>cmd /c reg add "HKLM\SOFTWARE\Microsoft\ServerManager" /v "DoNotOpenServerManagerAtLogon" /d 1 /t REG_DWORD /f</Path>
        </RunSynchronousCommand>
        <RunSynchronousCommand wcm:action="add">
            <Description>Do not Open Initial Configuration Tasks At Logon</Description>
            <Order>7</Order>
            <Path>cmd /c reg add "HKLM\SOFTWARE\Microsoft\ServerManager\oobe" /v "DoNotOpenInitialConfigurationTasksAtLogon" /d 1 /t REG_DWORD /f</Path>
        </RunSynchronousCommand>
        <RunSynchronousCommand wcm:action="add">
            <Description>Set Power Scheme to High Performance</Description>
            <Order>8</Order>
            <Path>cmd /c powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c</Path>
        </RunSynchronousCommand>
        <RunSynchronousCommand wcm:action="add">
            <Description>Don't require password when console wakes up</Description>
            <Order>9</Order>
            <Path>cmd /c powercfg -setacvalueindex 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c fea3413e-7e05-4911-9a71-700331f1c294 0e796bdb-100d-47d6-a2d5-f7d2daa51f51 0</Path>
        </RunSynchronousCommand>
        <RunSynchronousCommand wcm:action="add">
            <Description>Sleep timeout</Description>
            <Order>10</Order>
            <Path>cmd /c powercfg -setacvalueindex 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 238c9fa8-0aad-41ed-83f4-97be242c8f20 29f6c1db-86da-48c5-9fdb-f2b67b1f44da 0</Path>
        </RunSynchronousCommand>
        <RunSynchronousCommand wcm:action="add">
            <Description>monitor timeout</Description>
            <Order>11</Order>
            <Path>cmd /c powercfg -setacvalueindex 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e 0</Path>
        </RunSynchronousCommand>
        <RunSynchronousCommand wcm:action="add">
            <Description>Enable PowerShell Remoting 1</Description>
            <Order>12</Order>
            <Path>cmd /c winrm quickconfig -quiet</Path>
        </RunSynchronousCommand>
        <RunSynchronousCommand wcm:action="add">
            <Description>Enable PowerShell Remoting 2</Description>
            <Order>13</Order>
            <Path>cmd /c winrm quickconfig -quiet -force</Path>
        </RunSynchronousCommand>
        <RunSynchronousCommand wcm:action="add">
            <Description>Enable PowerShell Remoting 2</Description>
            <Order>14</Order>
            <Path>cmd /c reg add HKLM\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell /v ExecutionPolicy /t REG_SZ /d Unrestricted /f</Path>
        </RunSynchronousCommand>
        <RunSynchronousCommand wcm:action="add">
            <Description>Disable UAC</Description>
            <Order>15</Order>
            <Path>cmd /c reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\policies\system /v EnableLUA /t REG_DWORD /d 0 /f</Path>
        </RunSynchronousCommand>
        <RunSynchronousCommand wcm:action="add">
            <Description>Configure BgInfo to start automatically</Description>
            <Order>16</Order>
            <Path>cmd /c reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run /v BgInfo /t REG_SZ /d "C:\Windows\BgInfo.exe C:\Windows\BgInfo.bgi /Timer:0 /nolicprompt" /f</Path>
        </RunSynchronousCommand>
        <RunSynchronousCommand wcm:action="add">
            <Description>Enable Remote Desktop firewall rules</Description>
            <Order>17</Order>
            <Path>cmd /c netsh advfirewall Firewall set rule group="Remote Desktop" new enable=yes</Path>
        </RunSynchronousCommand>
      </RunSynchronous>
    </component>
    <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <InputLocale>0409:00000409</InputLocale>
      <SystemLocale>EN-US</SystemLocale>
      <UILanguage>EN-US</UILanguage>
      <UserLocale>EN-US</UserLocale>
    </component>
    <component name="Microsoft-Windows-TapiSetup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <TapiConfigured>0</TapiConfigured>
      <TapiUnattendLocation>
        <AreaCode>""</AreaCode>
        <CountryOrRegion>1</CountryOrRegion>
        <LongDistanceAccess>9</LongDistanceAccess>
        <OutsideAccess>9</OutsideAccess>
        <PulseOrToneDialing>1</PulseOrToneDialing>
        <DisableCallWaiting>""</DisableCallWaiting>
        <InternationalCarrierCode>""</InternationalCarrierCode>
        <LongDistanceCarrierCode>""</LongDistanceCarrierCode>
        <Name>Default</Name>
      </TapiUnattendLocation>
    </component>
    <component name="Microsoft-Windows-IE-ESC" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <IEHardenAdmin>false</IEHardenAdmin>
      <IEHardenUser>false</IEHardenUser>
    </component>
    <component name="Microsoft-Windows-TerminalServices-LocalSessionManager" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <fDenyTSConnections>false</fDenyTSConnections>
    </component>
    <component name="Networking-MPSSVC-Svc" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" />
    <component name="Microsoft-Windows-TCPIP" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" />
    <component name="Microsoft-Windows-DNS-Client" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" />
    <component name="Microsoft-Windows-NetBT" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" />
  </settings>
  <settings pass="oobeSystem">
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
      <FirstLogonCommands>
      <SynchronousCommand wcm:action="add">
            <CommandLine>cmd /c sc config MpsSvc start=disabled</CommandLine>
            <Description>1</Description>
            <Order>1</Order>
        </SynchronousCommand>
        <SynchronousCommand wcm:action="add">
            <CommandLine>cmd /c sc stop MpsSvc</CommandLine>
            <Description>2</Description>
            <Order>2</Order>
        </SynchronousCommand>
        <SynchronousCommand wcm:action="add">
            <CommandLine>winrm quickconfig -quiet</CommandLine>
            <Description>Enable Windows Remoting</Description>
            <Order>3</Order>
        </SynchronousCommand>
        <SynchronousCommand wcm:action="add">
            <CommandLine>winrm quickconfig -quiet -force</CommandLine>
            <Description>Enable Windows Remoting</Description>
            <Order>4</Order>
        </SynchronousCommand>
        <SynchronousCommand wcm:action="add">
            <CommandLine>winrm set winrm/config/service/auth @{CredSSP="true"}</CommandLine>
            <Description>Enable Windows Remoting CredSSP</Description>
            <Order>5</Order>
        </SynchronousCommand>
        <SynchronousCommand wcm:action="add">
            <Description>Bring all additional disks online</Description>
            <Order>6</Order>
            <CommandLine>PowerShell -File C:\AdditionalDisksOnline.ps1</CommandLine>
        </SynchronousCommand>
		<SynchronousCommand wcm:action="add">
            <Description>Disable .net Optimization</Description>
            <Order>7</Order>
            <CommandLine>PowerShell -Command "schtasks.exe /query /FO CSV | ConvertFrom-Csv | Where-Object { $_.TaskName -like '*NGEN*' } | ForEach-Object { schtasks.exe /Change /TN $_.TaskName /Disable }"</CommandLine>
        </SynchronousCommand>
      </FirstLogonCommands>
      <UserAccounts>
        <AdministratorPassword>
          <Value>Password1</Value>
          <PlainText>true</PlainText>
        </AdministratorPassword>
        <LocalAccounts>
          <LocalAccount wcm:action="add">
            <Password>
              <Value>Password1</Value>
              <PlainText>true</PlainText>
            </Password>
            <Group>Administrators</Group>
            <DisplayName>AL</DisplayName>
            <Name>AL</Name>
          </LocalAccount>
        </LocalAccounts>
      </UserAccounts>
      <OOBE>
        <HideEULAPage>true</HideEULAPage>
        <NetworkLocation>Work</NetworkLocation>
        <ProtectYourPC>3</ProtectYourPC>
      </OOBE>
      <RegisteredOrganization>vm.net</RegisteredOrganization>
      <RegisteredOwner>NA</RegisteredOwner>
    </component>
    <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <InputLocale>0409:00000409</InputLocale>
      <SystemLocale>En-US</SystemLocale>
      <UILanguage>EN-US</UILanguage>
      <UserLocale>EN-Us</UserLocale>
    </component>
  </settings>
</unattend>
'@

$kickstartContent = @"
install
cdrom
text
firstboot --disable
reboot
bootloader --append="biosdevname=0 net.ifnames=0"
zerombr
clearpart --all
autopart
"@

$autoyastContent = @"
<?xml version="1.0"?>
<!DOCTYPE profile>
<profile
  xmlns="http://www.suse.com/1.0/yast2ns"
  xmlns:config="http://www.suse.com/1.0/configns">
  <general>
  <signature-handling>
    <accept_unsigned_file config:type="boolean">true</accept_unsigned_file>
    <accept_file_without_checksum config:type="boolean">true</accept_file_without_checksum>
    <accept_verification_failed config:type="boolean">true</accept_verification_failed>
    <accept_unknown_gpg_key config:type="boolean">true</accept_unknown_gpg_key>
    <import_gpg_key config:type="boolean">true</import_gpg_key>
    <accept_non_trusted_gpg_key config:type="boolean">true</accept_non_trusted_gpg_key>
    </signature-handling>
    <self_update config:type="boolean">false</self_update>
  <mode>
    <halt config:type="boolean">false</halt>
    <forceboot config:type="boolean">false</forceboot>
    <final_reboot config:type="boolean">true</final_reboot>
    <final_halt config:type="boolean">false</final_halt>
    <confirm_base_product_license config:type="boolean">false</confirm_base_product_license>
    <confirm config:type="boolean">false</confirm>
    <second_stage config:type="boolean">true</second_stage>
  </mode>
  </general>
  <partitioning config:type="list">
    <drive>
        <disklabel>gpt</disklabel>
        <device>/dev/sda</device>
        <use>free</use>
        <partitions config:type="list">
            <partition>
                <filesystem config:type="symbol">vfat</filesystem>
                <mount>/boot</mount>
                <size>1G</size>
            </partition>
            <partition>
                <filesystem config:type="symbol">vfat</filesystem>
                <mount>/boot/efi</mount>
                <size>1G</size>
            </partition>
            <partition>
                <filesystem config:type="symbol">swap</filesystem>
                <mount>/swap</mount>
                <size>auto</size>
            </partition>
            <partition>
                <filesystem config:type="symbol">ext4</filesystem>
                <mount>/</mount>
                <size>auto</size>
            </partition>
        </partitions>
    </drive>
</partitioning>
<bootloader>
  <loader_type>grub2-efi</loader_type>
  <global>
    <activate config:type="boolean">true</activate>
    <boot_boot>true</boot_boot>
  </global>
 </bootloader>
<language>
    <language>en_US</language>
</language>
<timezone>
<!-- https://raw.githubusercontent.com/yast/yast-country/master/timezone/src/data/timezone_raw.ycp -->
    <hwclock>UTC</hwclock>
    <timezone>ETC/GMT</timezone>
</timezone>
<keyboard>
<!-- https://raw.githubusercontent.com/yast/yast-country/master/keyboard/src/data/keyboard_raw.ycp -->
    <keymap>english-us</keymap>
</keyboard>
<software>
    <patterns config:type="list">
    <pattern>base</pattern>
    <pattern>enhanced_base</pattern>
  </patterns>
  <install_recommended config:type="boolean">true</install_recommended>
  <packages config:type="list">
    <package>iputils</package>
    <package>vim</package>
    <package>less</package>
  </packages>
</software>
<services-manager>
  <default_target>multi-user</default_target>
  <services>
    <enable config:type="list">
      <service>sshd</service>
    </enable>
  </services>
</services-manager>
<networking>
<interfaces config:type="list">
</interfaces>
<dns>
    <nameservers config:type="list">
    </nameservers>
</dns>
<routing>
<routes config:type="list">
</routes>
</routing>
</networking>
<users config:type="list">
  <user>
    <username>root</username>
    <user_password>Password1</user_password>
    <encrypted config:type="boolean">false</encrypted>
  </user>
  </users>
<firewall>
  <enable_firewall config:type="boolean">true</enable_firewall>
  <start_firewall config:type="boolean">true</start_firewall>
</firewall>
<scripts>
    <init-scripts config:type="list">
      <script>
        <source>
        <![CDATA[
            rpm --import https://packages.microsoft.com/keys/microsoft.asc
            rpm -Uvh https://packages.microsoft.com/config/sles/12/packages-microsoft-prod.rpm
            zypper update
            zypper -f -v install powershell omi openssl
            systemctl enable omid
            echo "Subsystem powershell /usr/bin/pwsh -sshs -NoLogo" >> /etc/ssh/sshd_config
            systemctl restart sshd
        ]]>
        </source>
      </script>
    </init-scripts>
  </scripts>
</profile>
"@

#region Get-LabVolumesOnPhysicalDisks

function Get-LabVolumesOnPhysicalDisks
{
    [CmdletBinding()]

    $physicalDisks = Get-PhysicalDisk
    $disks = Get-CimInstance -Class Win32_DiskDrive

    $labVolumes = foreach ($disk in $disks)
    {
        $query = 'ASSOCIATORS OF {{Win32_DiskDrive.DeviceID="{0}"}} WHERE AssocClass=Win32_DiskDriveToDiskPartition' -f $disk.DeviceID.Replace('\', '\\')

        $partitions = Get-CimInstance -Query $query
        foreach ($partition in $partitions)
        {
            $query = 'ASSOCIATORS OF {{Win32_DiskPartition.DeviceID="{0}"}} WHERE AssocClass=Win32_LogicalDiskToPartition' -f $partition.DeviceID
            $volumes = Get-CimInstance -Query $query

            foreach ($volume in $volumes)
            {
                Get-Volume -DriveLetter $volume.DeviceId[0] |
                Add-Member -Name Serial -MemberType NoteProperty -Value $disk.SerialNumber -PassThru |
                Add-Member -Name Signature -MemberType NoteProperty -Value $disk.Signature -PassThru
            }
        }
    }

    $labVolumes |
    Select-Object -ExpandProperty DriveLetter |
    Sort-Object |
    ForEach-Object {
        $localDisk = New-Object AutomatedLab.LocalDisk($_)
        $localDisk.Serial = $_.Serial
        $localDisk.Signature = $_.Signature
        $localDisk
    }
}
#endregion Get-LabVolumesOnPhysicalDisks

#region Get-LabFreeDiskSpace
function Get-LabFreeDiskSpace
{
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $type = @'
using System;
using System.Runtime.InteropServices;

namespace AutomatedLab
{
    public class DiskSpaceWin32
    {
        [DllImport("kernel32.dll", SetLastError=true, CharSet=CharSet.Auto)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool GetDiskFreeSpaceEx(string lpDirectoryName,
           out ulong lpFreeBytesAvailable,
           out ulong lpTotalNumberOfBytes,
           out ulong lpTotalNumberOfFreeBytes);
    }
}
'@

    Add-Type -TypeDefinition $type

    [uint64]$freeBytesAvailable = 0
    [uint64]$totalNumberOfBytes = 0
    [uint64]$totalNumberOfFreeBytes = 0

    $success = [AutomatedLab.DiskSpaceWin32]::GetDiskFreeSpaceEx($Path, [ref]$freeBytesAvailable, [ref]$totalNumberOfBytes, [ref]$totalNumberOfFreeBytes)
    if (-not $success)
    {
        Write-Error "Could not determine free disk space of path '$Path'"
    }

    New-Object -TypeName PSObject -Property @{
        TotalNumberOfBytes     = $totalNumberOfBytes
        FreeBytesAvailable     = $freeBytesAvailable
        TotalNumberOfFreeBytes = $totalNumberOfFreeBytes
    }
}
#endregion Internals

#region Lab Definition Functions
#region New-LabDefinition
function New-LabDefinition
{
    [CmdletBinding()]
    param (
        [string]$Name,

        [string]$VmPath,

        [int]$ReferenceDiskSizeInGB = 50,

        [long]$MaxMemory = 0,

        [hashtable]$Notes,

        [switch]$UseAllMemory = $false,

        [switch]$UseStaticMemory = $false,

        [ValidateSet('Azure', 'HyperV', 'VMWare')]
        [string]$DefaultVirtualizationEngine,

        [string]$AzureSubscriptionName,

        [switch]$Passthru
    )

    Write-LogFunctionEntry
    $global:PSLog_Indent = 0

    $hostOSVersion = ([Environment]::OSVersion).Version
    if (-Not $IsLinux -and (($hostOSVersion -lt [System.Version]'6.2') -or (($hostOSVersion -ge [System.Version]'6.4') -and ($hostOSVersion.Build -lt '14393'))))
    {
        $osName = $(([Environment]::OSVersion).VersionString.PadRight(10))
        $osBuild = $(([Environment]::OSVersion).Version.ToString().PadRight(11))
        Write-PSFMessage -Level Host '***************************************************************************'
        Write-PSFMessage -Level Host ' THIS HOST MACHINE IS NOT RUNNING AN OS SUPPORTED BY AUTOMATEDLAB!'
        Write-PSFMessage -Level Host ''
        Write-PSFMessage -Level Host '   Operating System detected as:'
        Write-PSFMessage -Level Host "     Name:  $osName"
        Write-PSFMessage -Level Host "     Build: $osBuild"
        Write-PSFMessage -Level Host ''
        Write-PSFMessage -Level Host ' AutomatedLab is supported on the following virtualization platforms'
        Write-PSFMessage -Level Host ''
        Write-PSFMessage -Level Host ' - Microsoft Azure'
        Write-PSFMessage -Level Host ' - Windows 2016 1607 or newer'
        Write-PSFMessage -Level Host ' - Windows 10 1607 or newer'
        Write-PSFMessage -Level Host ' - Windows 8.1 Professional or Enterprise'
        Write-PSFMessage -Level Host ' - Windows 2012 R2'

        Write-PSFMessage -Level Host '***************************************************************************'
    }

    if ($DefaultVirtualizationEngine -eq 'Azure')
    {
        $null = Test-LabAzureModuleAvailability -ErrorAction Stop
    }

    #settings for a new log

    #reset the log and its format
    $Global:AL_DeploymentStart = $null
    $Global:taskStart = @()
    $Global:indent = 0
    $global:AL_CurrentLab = $null

    $Global:labDeploymentNoNewLine = $false

    $Script:reservedAddressSpaces = $null

    Write-ScreenInfo -Message 'Initialization' -TimeDelta ([timespan]0) -TimeDelta2 ([timespan]0) -TaskStart

    $hostOsName = if (($IsLinux -or $IsMacOs) -and (Get-Command -Name lsb_release -ErrorAction SilentlyContinue)) 
    {
        lsb_release -d -s
    }
    elseif (-not ($IsLinux -or $IsMacOs)) # easier than IsWindows, which does not exist in Windows PowerShell...
    {
        (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
    }
    else
    {
        'Unknown'
    }

    Write-ScreenInfo -Message "Host operating system version: '$hostOsName, $($hostOSVersion.ToString())'"

    if (-not $Name)
    {
        $reservedMacAddresses = @()

        #Microsoft
        $reservedMacAddresses += '00:03:FF'
        $reservedMacAddresses += '00:0D:3A'
        $reservedMacAddresses += '00:12:5A'
        $reservedMacAddresses += '00:15:5D'
        $reservedMacAddresses += '00:17:FA'
        $reservedMacAddresses += '00:50:F2'
        $reservedMacAddresses += '00:1D:D8'

        #VMware
        $reservedMacAddresses += '00:05:69'
        $reservedMacAddresses += '00:0C:29'
        $reservedMacAddresses += '00:1C:14'
        $reservedMacAddresses += '00:50:56'

        #Citrix
        $reservedMacAddresses += '00:16:3E'

        $macAddress = Get-OnlineAdapterHardwareAddress |
        Where-Object { $_.SubString(0, 8) -notin $reservedMacAddresses } |
        Select-Object -Unique

        $Name = "$($env:COMPUTERNAME)$($macAddress.SubString(12,2))$($macAddress.SubString(15,2))"
        Write-ScreenInfo -Message "Lab name and network name has automatically been generated as '$Name' (if not overridden)"
    }

    Write-ScreenInfo -Message "Creating new lab definition with name '$Name'"

    #remove the current lab from memory
    if (Get-Lab -ErrorAction SilentlyContinue)
    {
        Clear-Lab
    }

    $global:labExported = $false

    $global:firstAzureVMCreated = $false
    $global:existingAzureNetworks = @()

    $global:cacheVMs = $null

    $script:existingHyperVVirtualSwitches = $null

    #cleanup $PSDefaultParameterValues for entries for AL functions
    $automatedLabPSDefaultParameterValues = $global:PSDefaultParameterValues.GetEnumerator() | Where-Object { (Get-Command ($_.Name).Split(':')[0]).Module -like 'Automated*' }
    if ($automatedLabPSDefaultParameterValues)
    {
        foreach ($entry in $automatedLabPSDefaultParameterValues)
        {
            $global:PSDefaultParameterValues.Remove($entry.Name)
            Write-ScreenInfo -Message "Entry '$($entry.Name)' with value '$($entry.Value)' was removed from `$PSDefaultParameterValues. If needed, modify `$PSDefaultParameterValues after calling New-LabDefinition'" -Type Warning
        }
    }

    if (Get-Variable -Name 'autoIPAddress' -Scope Script -ErrorAction SilentlyContinue)
    {
        Remove-Variable -Name 'AutoIPAddress' -Scope Script
    }

    if ($global:labNamePrefix)
    {
        $Name = "$global:labNamePrefix$Name" 
    }

    $script:labPath = "$((Get-LabConfigurationItem -Name LabAppDataRoot))/Labs/$Name"
    Write-ScreenInfo -Message "Location of lab definition files will be '$($script:labpath)'"

    $script:lab = New-Object AutomatedLab.Lab

    $script:lab.Name = $Name

    Update-LabSysinternalsTools

    while (Get-LabVirtualNetworkDefinition)
    {
        Remove-LabVirtualNetworkDefinition -Name (Get-LabVirtualNetworkDefinition)[0].Name
    }

    $machineDefinitionFilePath = Join-Path -Path $script:labPath -ChildPath (Get-LabConfigurationItem MachineFileName)
    $machineDefinitionFile = New-Object AutomatedLab.MachineDefinitionFile
    $machineDefinitionFile.Path = $machineDefinitionFilePath
    $script:lab.MachineDefinitionFiles.Add($machineDefinitionFile)

    $diskDefinitionFilePath = Join-Path -Path $script:labPath -ChildPath (Get-LabConfigurationItem DiskFileName)
    $diskDefinitionFile = New-Object AutomatedLab.DiskDefinitionFile
    $diskDefinitionFile.Path = $diskDefinitionFilePath
    $script:lab.DiskDefinitionFiles.Add($diskDefinitionFile)

    $sourcesPath = $labSources
    if (-not $sourcesPath)
    {
        $sourcesPath = New-LabSourcesFolder
    }

    Write-ScreenInfo -Message "Location of LabSources folder is '$sourcesPath'"

    if (-not (Get-LabIsoImageDefinition) -and $DefaultVirtualizationEngine -ne 'Azure')
    {
        if (-not (Get-ChildItem -Path "$(Get-LabSourcesLocation)\ISOs" -Filter *.iso -Recurse))
        {
            Write-ScreenInfo -Message "No ISO files found in $(Get-LabSourcesLocation)\ISOs folder. If using Hyper-V for lab machines, please add ISO files manually using 'Add-LabIsoImageDefinition'" -Type Warning
        }

        Write-ScreenInfo -Message 'Auto-adding ISO files' -TaskStart
        Get-LabAvailableOperatingSystem -Path "$(Get-LabSourcesLocation)\ISOs" | Out-Null #for updating the cache if necessary
        Add-LabIsoImageDefinition -Path "$(Get-LabSourcesLocation)\ISOs"
        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if ($DefaultVirtualizationEngine)
    {
        $script:lab.DefaultVirtualizationEngine = $DefaultVirtualizationEngine
    }

    if ($MaxMemory -ne 0)
    {
        $script:lab.MaxMemory = $MaxMemory
    }
    if ($UseAllMemory)
    {
        $script:lab.MaxMemory = 4TB
    }

    $script:lab.UseStaticMemory = $UseStaticMemory

    $script:lab.Sources.UnattendedXml = $script:labPath
    if ($VmPath)
    {
        $Script:lab.target.Path = $vmPath
        Write-ScreenInfo -Message "Path for VMs specified as '$($script:lab.Target.Path)'" -Type Info
    }

    $script:lab.Target.ReferenceDiskSizeInGB = $ReferenceDiskSizeInGB

    $type = Get-Type -GenericType AutomatedLab.ListXmlStore -T AutomatedLab.Machine
    $script:machines = New-Object $type
    $type = Get-Type -GenericType AutomatedLab.ListXmlStore -T AutomatedLab.Disk
    $script:disks = New-Object $type

    $script:lab.Notes = $Notes

    if ($Passthru)
    {
        $script:lab
    }

    $global:AL_CurrentLab = $script:lab

    Register-LabArgumentCompleters

    Write-LogFunctionExit
}
#endregion New-LabDefinition

#region Get-LabDefinition
function Get-LabDefinition
{
    [CmdletBinding()]
    [OutputType([AutomatedLab.Lab])]
    param ()

    Write-LogFunctionEntry

    return $script:lab

    Write-LogFunctionExit
}
#endregion Get-LabDefinition

#region Set-LabDefinition
function Set-LabDefinition
{
    param
    (
        [AutomatedLab.Lab]
        $Lab,

        [AutomatedLab.Machine[]]
        $Machines,

        [AutomatedLab.Disk[]]
        $Disks
    )

    if ($Lab)
    {
        $script:lab = $Lab
    }

    if ($Machines)
    {
        if (-not $script:machines)
        {
            $script:machines = New-Object 'AutomatedLab.SerializableList[AutomatedLab.Machine]'
        }

        $script:machines.Clear()
        $Machines | ForEach-Object { $script:Machines.Add($_) }
    }

    if ($Disks)
    {
        $script:Disks.Clear()
        $Disks | ForEach-Object { $script:Disks.Add($_) }
    }
}
#endregion

#region Export-LabDefinition
function Export-LabDefinition
{
    [CmdletBinding()]
    param (
        [switch]
        $Force,

        [switch]
        $ExportDefaultUnattendedXml = $true,

        [switch]
        $Silent
    )

    Write-LogFunctionEntry

    if (Get-LabMachineDefinition | Where-Object HostType -eq 'HyperV')
    {
        $osesCount = (Get-LabAvailableOperatingSystem -NoDisplay).Count
    }

    #Automatic DNS configuration in Azure if no DNS server is specified and an AD is being deployed
    foreach ($network in (Get-LabVirtualNetworkDefinition))
    {
        if ($network.HostType -eq 'Azure' -and (Get-LabMachineDefinition -Role RootDC))
        {
            $rootDCs = Get-LabMachineDefinition -Role RootDC
            $dnsServerIP = ''
            if ($rootDCs | Where-Object Network -eq $network)
            {
                $dnsServerIP = ($rootDCs)[0].IpV4Address
            }
            elseif ($rootDCs | Where-Object Network -eq $network)
            {
                $dnsServerIP = ($rootDCs | Where-Object Network -eq $network)[0].IpV4Address
            }
            if (-not ((Get-LabVirtualNetworkDefinition)[0].DnsServers) -and $dnsServerIP)
            {
                (Get-LabVirtualNetworkDefinition)[0].DnsServers = $dnsServerIP
                $dnsServerName = (Get-LabMachineDefinition | Where-Object { $_.IpV4Address -eq $dnsServerIP }).Name

                if (-not $Silent)
                {
                    Write-ScreenInfo -Message "No DNS server was defined for Azure virtual network while AD is being deployed. Setting DNS server to IP address of '$dnsServerName'" -Type Warning
                }
            }
        }
    }

    #Automatic DNS (client) configuration of machines
    $firstRootDc = Get-LabMachineDefinition -Role RootDC | Select-Object -First 1
    $firstRouter = Get-LabMachineDefinition -Role Routing | Select-Object -First 1
    $firstRouterExternalSwitch = $firstRouter.NetworkAdapters | Where-Object { $_.VirtualSwitch.SwitchType -eq 'External' }

    if ($firstRootDc -or $firstRouter)
    {
        foreach ($machine in (Get-LabMachineDefinition))
        {
            if ($firstRouter)
            {
                $mappingNetworks = Compare-Object -ReferenceObject $firstRouter.NetworkAdapters.VirtualSwitch.Name `
                    -DifferenceObject $machine.NetworkAdapters.VirtualSwitch.Name -ExcludeDifferent -IncludeEqual
            }

            foreach ($networkAdapter in $machine.NetworkAdapters)
            {
                if ($networkAdapter.IPv4DnsServers -contains '0.0.0.0')
                {
                    if (-not $machine.IsDomainJoined) #machine is not domain joined, the 1st network adapter's IP of the 1st root DC is used as DNS server
                    {
                        if ($firstRootDc)
                        {
                            $networkAdapter.IPv4DnsServers = $firstRootDc.NetworkAdapters[0].Ipv4Address[0].IpAddress
                        }
                        elseif ($firstRouter)
                        {
                            if ($networkAdapter.VirtualSwitch.Name -in $mappingNetworks.InputObject)
                            {
                                $networkAdapter.IPv4DnsServers = ($firstRouter.NetworkAdapters | Where-Object { $_.VirtualSwitch.Name -eq $networkAdapter.VirtualSwitch.Name }).Ipv4Address.IpAddress
                            }
                        }

                    }
                    elseif ($machine.Roles.Name -contains 'RootDC') #if the machine is RootDC, its 1st network adapter's IP is used for DNS
                    {
                        $networkAdapter.IPv4DnsServers = $machine.NetworkAdapters[0].Ipv4Address[0].IpAddress
                    }
                    elseif ($machine.Roles.Name -contains 'FirstChildDC') #if it is a FirstChildDc, the 1st network adapter's IP of the corresponsing RootDC is used
                    {
                        $firstChildDcRole = $machine.Roles | Where-Object Name -eq 'FirstChildDC'
                        $roleParentDomain = $firstChildDcRole.Properties.ParentDomain
                        $rootDc = Get-LabMachineDefinition -Role RootDC | Where-Object DomainName -eq $roleParentDomain

                        $networkAdapter.IPv4DnsServers = $rootDc.NetworkAdapters[0].Ipv4Address[0].IpAddress
                    }
                    else #machine is domain joined and not a RootDC or FirstChildDC
                    {
                        Write-PSFMessage "Looking for a root DC in the machine's domain '$($machine.DomainName)'"
                        $rootDc = Get-LabMachineDefinition -Role RootDC | Where-Object DomainName -eq $machine.DomainName
                        if ($rootDc)
                        {
                            Write-PSFMessage "RootDC found, using the IP address of '$rootDc' for DNS: "
                            $networkAdapter.IPv4DnsServers = $rootDc.NetworkAdapters[0].Ipv4Address[0].IpAddress
                        }
                        else
                        {
                            Write-PSFMessage "No RootDC found, looking for FirstChildDC in the machine's domain"
                            $firstChildDC = Get-LabMachineDefinition -Role FirstChildDC | Where-Object DomainName -eq $machine.DomainName

                            if ($firstChildDC)
                            {
                                $networkAdapter.IPv4DnsServers = $firstChildDC.NetworkAdapters[0].Ipv4Address[0].IpAddress
                            }
                            else
                            {
                                Write-ScreenInfo "Automatic assignment of DNS server did not work for machine '$machine'. No domain controller could be found for domain '$($machine.DomainName)'" -Type Warning
                            }
                        }
                    }
                }

                #if there is a router in the network and no gateways defined, we try to set the gateway automatically. This does not
                #apply to network adapters that have a gateway manually configured or set to DHCP, any network adapter on a router,
                #or if there is there wasn't found an external network adapter on the router ($firstRouterExternalSwitch)
                if ($networkAdapter.Ipv4Gateway.Count -eq 0 -and
                    $firstRouterExternalSwitch -and
                    $machine.Roles.Name -notcontains 'Routing' -and
                    -not $networkAdapter.UseDhcp
                )
                {
                    if ($networkAdapter.VirtualSwitch.Name -in $mappingNetworks.InputObject)
                    {
                        $networkAdapter.Ipv4Gateway.Add(($firstRouter.NetworkAdapters | Where-Object { $_.VirtualSwitch.Name -eq $networkAdapter.VirtualSwitch.Name } | Select-Object -First 1).Ipv4Address.IpAddress)
                    }
                }
            }
        }
    }

    if (Get-LabMachineDefinition | Where-Object HostType -eq HyperV)
    {
        $hypervMachines = Get-LabMachineDefinition | Where-Object HostType -eq HyperV
        $hypervUsedOperatingSystems = Get-LabAvailableOperatingSystem -NoDisplay | Where-Object OperatingSystemImageName -in $hypervMachines.OperatingSystem.OperatingSystemName

        $spaceNeededBaseDisks = ($hypervUsedOperatingSystems | Measure-Object -Property Size -Sum).Sum
        $spaceBaseDisksAlreadyClaimed = ($hypervUsedOperatingSystems | Measure-Object -Property size -Sum).Sum
        $spaceNeededData = ($hypervMachines | Where-Object { -not (Get-VM -Name $_.ResourceName -ErrorAction SilentlyContinue) }).Count * 2GB

        $spaceNeeded = $spaceNeededBaseDisks + $spaceNeededData - $spaceBaseDisksAlreadyClaimed

        Write-PSFMessage -Message "Space needed by HyperV base disks:                     $([int]($spaceNeededBaseDisks / 1GB))"
        Write-PSFMessage -Message "Space needed by HyperV base disks but already claimed: $([int]($spaceBaseDisksAlreadyClaimed / 1GB * -1))"
        Write-PSFMessage -Message "Space estimated for HyperV data:                       $([int]($spaceNeededData / 1GB))"
        if (-not $Silent)
        {
            Write-ScreenInfo -Message "Estimated (additional) local drive space needed for all machines: $([System.Math]::Round(($spaceNeeded / 1GB),2)) GB" -Type Info
        }

        $labTargetPath = (Get-LabDefinition).Target.Path
        if ($labTargetPath)
        {
            if (-not (Test-Path -Path $labTargetPath))
            {
                try
                {
                    Write-PSFMessage "Creating new folder '$labTargetPath'"
                    New-Item -ItemType Directory -Path $labTargetPath -ErrorAction Stop | Out-Null
                }
                catch
                {
                    Write-Error -Message "Could not create folder '$labTargetPath'. Please make sure that the folder is accessibe and you have permission to write."
                    return
                }
            }

            Write-PSFMessage "Calling 'Get-LabFreeDiskSpace' targeting path '$labTargetPath'"
            $freeSpace = (Get-LabFreeDiskSpace -Path $labTargetPath).FreeBytesAvailable
            Write-PSFMessage "Free disk space is '$([Math]::Round($freeSpace / 1GB, 2))GB'"
            if ($freeSpace -lt $spaceNeeded)
            {
                throw "VmPath parameter is specified for the lab and contains: '$labTargetPath'. However, estimated needed space be $([int]($spaceNeeded / 1GB))GB but drive has only $([System.Math]::Round($freeSpace / 1GB)) GB of free space"
            }
        }
        else
        {
            Set-LabLocalVirtualMachineDiskAuto
            $labTargetPath = (Get-LabDefinition).Target.Path
            if (-not $labTargetPath)
            {
                Throw 'No local drive found matching requirements for free space'
            }
        }

        if (-not $Silent)
        {
            Write-ScreenInfo -Message "Location of Hyper-V machines will be '$labTargetPath'"
        }
    }


    $lab.LabFilePath = Join-Path -Path $script:labPath -ChildPath (Get-LabConfigurationItem LabFileName)
    $script:lab | Add-Member -Name Path -MemberType NoteProperty -Value $labFilePath -Force

    if (-not (Test-Path $script:labPath))
    {
        New-Item -Path $script:labPath -ItemType Directory | Out-Null
    }

    if (Test-Path -Path $lab.LabFilePath)
    {
        if ($Force)
        {
            Remove-Item -Path $lab.LabFilePath
        }
        else
        {
            Write-Error 'The file does already exist' -TargetObject $lab.LabFilePath
            return
        }
    }

    try
    {
        $script:lab.Export($lab.LabFilePath)
    }
    catch
    {
        throw $_
    }

    $machineFilePath = $script:lab.MachineDefinitionFiles[0].Path
    $diskFilePath = $script:lab.DiskDefinitionFiles[0].Path

    if (Test-Path -Path $machineFilePath)
    {
        if ($Force)
        {
            Remove-Item -Path $machineFilePath
        }
        else
        {
            Write-Error 'The file does already exist' -TargetObject $machineFilePath
            return
        }
    }

    $script:machines.Export($machineFilePath)
    $script:disks.Export($diskFilePath)

    if ($ExportDefaultUnattendedXml)
    {
        if ($script:machines.Count -eq 0)
        {
            Write-ScreenInfo 'There are no machines defined, nothing to export' -Type Warning
        }
        else
        {
            if ($Script:machines.OperatingSystem | Where-Object Version -lt '6.2')
            {
                $unattendedXmlDefaultContent2008 | Out-File -FilePath (Join-Path -Path $script:lab.Sources.UnattendedXml.Value -ChildPath Unattended2008.xml) -Encoding unicode
            }
            if ($Script:machines.OperatingSystem | Where-Object Version -ge '6.2')
            {
                $unattendedXmlDefaultContent2012 | Out-File -FilePath (Join-Path -Path $script:lab.Sources.UnattendedXml.Value -ChildPath Unattended2012.xml) -Encoding unicode
            }
            if ($Script:machines | Where-Object LinuxType -eq 'RedHat')
            {
                $kickstartContent | Out-File -FilePath (Join-Path -Path $script:lab.Sources.UnattendedXml.Value -ChildPath ks_default.cfg) -Encoding unicode
            }
            if ($Script:machines | Where-Object LinuxType -eq 'Suse')
            {
                $autoyastContent | Out-File -FilePath (Join-Path -Path $script:lab.Sources.UnattendedXml.Value -ChildPath autoinst_default.xml) -Encoding unicode
            }
        }
    }

    $Global:labExported = $true

    Write-LogFunctionExit
}
#endregion Export-LabDefinition

#region Test-LabDefinition
function Test-LabDefinition
{
    [CmdletBinding()]
    param (
        [string]$Path,

        [switch]$Quiet
    )

    Write-LogFunctionEntry

    $lab = Get-LabDefinition
    if (-not $lab)
    {
        $lab = Get-Lab -ErrorAction SilentlyContinue
    }

    if (-not $lab -and -not $Path)
    {
        Write-Error 'There is no lab loaded and no path specified. Please either import a lab using Import-Lab or point to a lab.xml document using the path parameter'
        return $false
    }

    if (-not $Path)
    {
        $Path = Join-Path -Path $lab.LabPath -ChildPath (Get-LabConfigurationItem LabFileName)
    }

    #we need to get the machine config files as well
    try
    {
        $machineDefinitionFiles = ([xml](Get-Content -Path $Path -Encoding UTF8) | Select-Xml -XPath '//MachineDefinitionFile' -ErrorAction Stop).Node.Path
    }
    catch
    {
        Write-Error -Message 'Cannot read lab file'
        return $false
    }

    Write-PSFMessage "There are $($machineDefinitionFiles.Count) machine XML file referenced in the lab xml file"
    foreach ($machineDefinitionFile in $machineDefinitionFiles)
    {
        if (-not (Test-Path -Path $machineDefinitionFile))
        {
            throw 'Error importing the machines. Verify the paths in the section <MachineDefinitionFiles> of the lab definition XML file.'
        }
    }

    $Script:ValidationPass = $true

    Write-PSFMessage 'Starting validation against all xml files'
    try
    {
        [AutomatedLab.XmlValidatorArgs]::XmlPath = $Path

        $summaryMessageContainer = New-Object AutomatedLab.ValidationMessageContainer

        $assembly = [System.Reflection.Assembly]::GetAssembly([AutomatedLab.ValidatorBase])

        $validatorCount = 0
        foreach ($t in $assembly.GetTypes())
        {
            if ($t.IsSubclassOf([AutomatedLab.ValidatorBase]))
            {
                try
                {
                    $validator = [AutomatedLab.ValidatorBase][System.Activator]::CreateInstance($t)
                    Write-Debug "Validator '$($validator.MessageContainer.ValidatorName)' took $($validator.Runtime.TotalMilliseconds) milliseconds"

                    $summaryMessageContainer += $validator.MessageContainer
                    $validatorCount++
                }
                catch
                {
                    Write-ScreenInfo "Could not invoke validator $t" -Type Warning
                }
            }
        }

        $summaryMessageContainer.AddSummary()
    }
    catch
    {
        throw $_
    }

    Write-PSFMessage -Message "Lab Validation complete, overvall runtime was $($summaryMessageContainer.Runtime)"

    $messages = $summaryMessageContainer | ForEach-Object { $_.GetFilteredMessages('All') }
    if (-not $Quiet)
    {
        Write-ScreenInfo ($messages | Where-Object { $_.Type -band [AutomatedLab.MessageType]::Default } | Out-String)

        if ($VerbosePreference -eq 'Continue')
        {
            Write-PSFMessage ($messages | Where-Object { $_.Type -band [AutomatedLab.MessageType]::VerboseDebug } | Out-String)
        }
    }
    else
    {
        if ($messages | Where-Object { $_.Type -band [AutomatedLab.MessageType]::Warning })
        {
            $messages | Where-Object { $_.Type -band [AutomatedLab.MessageType]::Warning } | ForEach-Object `
            {
                Write-ScreenInfo -Message "Issue: '$($_.TargetObject)'. Cause: $($_.Message)" -Type Warning
            }
        }

        if ($messages | Where-Object { $_.Type -band [AutomatedLab.MessageType]::Error })
        {
            $messages | Where-Object { $_.Type -band [AutomatedLab.MessageType]::Error } | ForEach-Object `
            {
                Write-ScreenInfo -Message "Issue: '$($_.TargetObject)'. Cause: $($_.Message)" -Type Error
            }
        }
    }

    if ($messages | Where-Object Type -eq ([AutomatedLab.MessageType]::Error))
    {
        $Script:ValidationPass = $false
        $false
    }
    else
    {
        $Script:ValidationPass = $true
        $true
    }

    Write-LogFunctionExit
}
#endregion Test-LabDefinition
#endregion Lab Definition Functions

#region Domain Definition Functions
#region Add-LabDomainDefinition
function Add-LabDomainDefinition
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$AdminUser,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$AdminPassword,

        [switch]$PassThru
    )

    Write-LogFunctionEntry

    if ($script:lab.Domains | Where-Object { $_.Name -eq $Name })
    {
        $errorMessage = "A domain with the name '$Name' is already defined"
        Write-Error $errorMessage
        Write-LogFunctionExitWithError -Message $errorMessage
        return
    }

    $domain = New-Object -TypeName AutomatedLab.Domain
    $domain.Name = $Name

    $user = New-Object -TypeName AutomatedLab.User
    $user.UserName = $AdminUser
    $user.Password = $AdminPassword

    $domain.Administrator = $user

    $script:lab.Domains.Add($domain)
    Write-PSFMessage "Added domain '$Name'. Lab now has $($Script:lab.Domains.Count) domain(s) defined"

    if ($PassThru)
    {
        $network
    }

    Write-LogFunctionExit
}
#endregion Add-LabDomainDefinition

#region Get-LabDomainDefinition
function Get-LabDomainDefinition
{
    Write-LogFunctionEntry

    return $script:lab.Domains

    Write-LogFunctionExit
}
#endregion Get-LabDomainDefinition

#region Remove-LabDomainDefinition
function Remove-LabDomainDefinition
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Name
    )

    Write-LogFunctionEntry

    $domain = $script:lab.Domains | Where-Object { $_.Name -eq $Name }

    if (-not $domain)
    {
        Write-ScreenInfo "There is no domain defined with the name '$Name'" -Type Warning
    }
    else
    {
        [Void]$script:lab.Domains.Remove($domain)
        Write-PSFMessage "Domain '$Name' removed. Lab has $($Script:lab.Domains.Count) domain(s) defined"
    }

    Write-LogFunctionExit
}
#endregion Remove-LabDomainDefinition
#endregion Domain Definition Functions

#region Iso Image Definition Functions
#region Add-LabIsoImageDefinition
function Add-LabIsoImageDefinition
{
    [CmdletBinding()]
    param (

        [string]$Name,

        [string]$Path,

        [Switch]$IsOperatingSystem,

        [switch]$NoDisplay
    )

    Write-LogFunctionEntry

    if ($IsOperatingSystem)
    {
        Write-ScreenInfo -Message 'The -IsOperatingSystem switch parameter is obsolete and thereby ignored' -Type Warning
    }

    if (-not $script:lab)
    {
        throw 'Please create a lab before using this cmdlet. To create a new lab, call New-LabDefinition'
    }

    $type = Get-Type -GenericType AutomatedLab.ListXmlStore -T AutomatedLab.IsoImage
    #read the cache
    try
    {
        if ($IsLinux -or $IsMacOs) {
            $cachedIsos = $type::Import((Join-Path -Path (Get-LabConfigurationItem -Name LabAppDataRoot) -ChildPath 'Stores/LocalIsoImages.xml'))
        }
        else
        {
            $cachedIsos = $type::ImportFromRegistry('Cache', 'LocalIsoImages')
        }

        Write-PSFMessage "Read $($cachedIsos.Count) ISO images from the cache"
    }
    catch
    {
        Write-PSFMessage 'Could not read ISO images info from the cache'
        $cachedIsos = New-Object $type
    }

    $lab = try { Get-Lab -ErrorAction Stop } catch { Get-LabDefinition -ErrorAction Stop }
    if ($lab.DefaultVirtualizationEngine -eq 'Azure')
    {
        if (Test-LabPathIsOnLabAzureLabSourcesStorage -Path $Path)
        {
            $isoFiles = Get-LabAzureLabSourcesContent -RegexFilter '\.iso' -File -ErrorAction SilentlyContinue

            if ( -not $IsLinux -and [System.IO.Path]::HasExtension($Path) -or $IsLinux -and $Path -match '\.iso$')
            {
                $isoFiles = $isoFiles | Where-Object {$_.Name -eq (Split-Path -Path $Path -Leaf)}

                if (-not $isoFiles -and $Name)
                {
                    $filterPath = Split-Path -Path $Path -Leaf
                    Write-PSFMessage -Message "Syncing $filterPath with Azure lab sources storage in case it does not already exist"
                    Sync-LabAzureLabSources -Filter $filterPath

                    $isoFiles = Get-LabAzureLabSourcesContent -RegexFilter '\.iso' -File -ErrorAction SilentlyContinue | Where-Object {$_.Name -eq (Split-Path -Path $Path -Leaf)}
                }
            }
        }
    }
    else
    {
        $isoFiles = Get-ChildItem -Path $Path -Filter *.iso -Recurse -ErrorAction SilentlyContinue
    }

    if (-not $isoFiles)
    {
        throw "The specified iso file could not be found or no ISO file could be found in the given folder: $Path"
    }

    $isos = @()
    foreach ($isoFile in $isoFiles)
    {
        if (-not $PSBoundParameters.ContainsKey('Name'))
        {
            $Name = [guid]::NewGuid()
        }
        else
        {
            $cachedIsos.Remove(($cachedIsos | Where-Object Name -eq $name)) | Out-Null
        }

        $iso = New-Object -TypeName AutomatedLab.IsoImage
        $iso.Name = $Name
        $iso.Path = $isoFile.FullName
        $iso.Size = $isoFile.Length

        if ($cachedIsos -contains $iso)
        {
            Write-PSFMessage "The ISO '$($iso.Path)' with a size '$($iso.Size)' is already in the cache."
            $cachedIso = ($cachedIsos -eq $iso)[0]
            if ($PSBoundParameters.ContainsKey('Name'))
            {
                $cachedIso.Name = $Name
            }
            $isos += $cachedIso
        }
        else
        {
            if (-not $script:lab.DefaultVirtualizationEngine -eq 'Azure')
            {
                Write-PSFMessage "The ISO '$($iso.Path)' with a size '$($iso.Size)' is not in the cache. Reading the operating systems from ISO."
                [void] (Mount-DiskImage -ImagePath $isoFile.FullName -StorageType ISO)
                Get-PSDrive | Out-Null #This is just to refresh the drives. Somehow if this cmdlet is not called, PowerShell does not see the new drives.
                $letter = (Get-DiskImage -ImagePath $isoFile.FullName | Get-Volume).DriveLetter
                $isOperatingSystem = (Test-Path "$letter`:\Sources\Install.wim") -or (Test-Path "$letter`:\.discinfo") -or (Test-Path "$letter`:\isolinux") -or (Test-Path "$letter`:\suse")
                [void] (Dismount-DiskImage -ImagePath $isoFile.FullName)
            }

            if ($isOperatingSystem)
            {
                $oses = Get-LabAvailableOperatingSystem -Path $isoFile.FullName
                if ($oses)
                {
                    foreach ($os in $oses)
                    {
                        if ($isos.OperatingSystems -contains $os)
                        {
                            Write-ScreenInfo "The operating system '$($os.OperatingSystemName)' with version '$($os.Version)' is already added to the lab. If this is an issue with cached information, use Clear-LabCache to solve the issue." -Type Warning
                        }
                        $iso.OperatingSystems.Add($os) | Out-Null
                    }
                }
                $cachedIsos.Add($iso) #the new ISO goes into the cache
                $isos += $iso
            }
            else
            {
                $cachedIsos.Add($iso) #ISO is not an OS. Add only if 'Name' is specified. Hence, ISO is manually added
                $isos += $iso
            }
        }
    }

    $duplicateOperatingSystems = $isos | Where-Object { $_.OperatingSystems } |
    Group-Object -Property { "$($_.OperatingSystems.OperatingSystemName) $($_.OperatingSystems.Version)" } |
    Where-Object Count -gt 1

    if ($duplicateOperatingSystems)
    {
        $duplicateOperatingSystems.Group |
        ForEach-Object { $_ } -PipelineVariable iso |
        ForEach-Object { $_.OperatingSystems } |
        ForEach-Object { Write-ScreenInfo "The operating system $($_.OperatingSystemName) version $($_.Version) defined more than once in '$($iso.Path)'" -Type Warning }
    }

    if ($IsLinux -or $IsMacOs)
    {
        $cachedIsos.Export((Join-Path -Path (Get-LabConfigurationItem -Name LabAppDataRoot) -ChildPath 'Stores/LocalIsoImages.xml'))
    }
    else
    {
        $cachedIsos.ExportToRegistry('Cache', 'LocalIsoImages')
    }

    foreach ($iso in $isos)
    {
        if ($iso.IsOperatingSystem -and $iso.OperatingSystems.OperatingSystemType -contains 'Linux')
        {
            Set-LinuxPackage -Package $iso.OperatingSystems[0].LinuxPackageGroup -LinuxType ($iso.OperatingSystems.LinuxType)[0]
        }

        $isosToRemove = $script:lab.Sources.ISOs | Where-Object { $_.Name -eq $iso.Name -or $_.Path -eq $iso.Path }
        foreach ($isoToRemove in $isosToRemove)
        {
            $script:lab.Sources.ISOs.Remove($isoToRemove) | Out-Null
        }

        #$script:lab.Sources.ISOs.Remove($iso) | Out-Null
        $script:lab.Sources.ISOs.Add($iso)
        Write-ScreenInfo -Message "Added '$($iso.Path)'"
    }
    Write-PSFMessage "Final Lab ISO count: $($script:lab.Sources.ISOs.Count)"

    Write-LogFunctionExit
}
#endregion Add-LabIsoImageDefinition

#region Get-LabIsoImageDefinition
function Get-LabIsoImageDefinition
{
    Write-LogFunctionEntry

    $script:lab.Sources.ISOs

    Write-LogFunctionExit
}
#endregion Get-LabIsoImageDefinition

#region Remove-LabIsoImageDefinition
function Remove-LabIsoImageDefinition
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$Name
    )

    Write-LogFunctionEntry

    $iso = $script:lab.Sources.ISOs | Where-Object -FilterScript {
        $_.Name -eq $Name
    }

    if (-not $iso)
    {
        Write-ScreenInfo "There is no Iso Image defined with the name '$Name'" -Type Warning
    }
    else
    {
        [Void]$script:lab.Sources.ISOs.Remove($iso)
        Write-PSFMessage "Iso Image '$Name' removed. Lab has $($Script:lab.Sources.ISOs.Count) Iso Image(s) defined"
    }

    Write-LogFunctionExit
}
#endregion Remove-LabIsoImageDefinition
#endregion Iso Image Definition Functions

#region Machine Definition Functions
#region Add-LabDiskDefinition
function Add-LabDiskDefinition
{
    [CmdletBinding()]
    [OutputType([AutomatedLab.Disk])]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateScript( {
                $doesAlreadyExist = Test-Path -Path $_
                if ($doesAlreadyExist)
                {
                    Write-ScreenInfo 'The disk does already exist' -Type Warning
                    return $false
                }
                else
                {
                    return $true
                }
            }
        )]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [int]$DiskSizeInGb = 60,

        [string]$Label,

        [char]$DriveLetter,

        [switch]$UseLargeFRS,

        [long]$AllocationUnitSize = 4KB,

        [switch]$SkipInitialize,

        [switch]$PassThru
    )

    Write-LogFunctionEntry

    if ($null -eq $script:disks)
    {
        $errorMessage = "Create a new lab first using 'New-LabDefinition' before adding disks"
        Write-Error $errorMessage
        Write-LogFunctionExitWithError -Message $errorMessage
        return
    }

    if ($Name)
    {
        if ($script:disks | Where-Object Name -eq $Name)
        {
            $errorMessage = "A disk with the name '$Name' does already exist"
            Write-Error $errorMessage
            Write-LogFunctionExitWithError -Message $errorMessage
            return
        }
    }

    $disk = New-Object -TypeName AutomatedLab.Disk
    $disk.Name = $Name
    $disk.DiskSize = $DiskSizeInGb
    $disk.SkipInitialization = [bool]$SkipInitialize
    $disk.AllocationUnitSize = $AllocationUnitSize
    $disk.UseLargeFRS = $UseLargeFRS
    $disk.DriveLetter = $DriveLetter
    $disk.Label = if ($Label)
    {
        $Label
    }
    else
    {
        'ALData'
    }

    $script:disks.Add($disk)

    Write-PSFMessage "Added disk '$Name' with path '$Path'. Lab now has $($Script:disks.Count) disk(s) defined"

    if ($PassThru)
    {
        $disk
    }

    Write-LogFunctionExit
}
#endregion Add-LabDiskDefinition

#region Add-LabMachineDefinition
function Add-LabMachineDefinition
{
    [CmdletBinding(DefaultParameterSetName = 'Network')]
    [OutputType([AutomatedLab.Machine])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidatePattern("^([\'\""a-zA-Z0-9-]){1,15}$")]
        [string]$Name,

        [ValidateRange(128MB, 128GB)]
        [double]$Memory,

        [ValidateRange(128MB, 128GB)]
        [double]$MinMemory,

        [ValidateRange(128MB, 128GB)]
        [double]$MaxMemory,

        [ValidateRange(1, 64)]
        [ValidateNotNullOrEmpty()]
        [int]$Processors = 0,

        [ValidatePattern('^([a-zA-Z0-9-_]){2,30}$')]
        [string[]]$DiskName,

        [Alias('OS')]
        [AutomatedLab.OperatingSystem]$OperatingSystem = (Get-LabDefinition).DefaultOperatingSystem,

        [string]$OperatingSystemVersion,

        [Parameter(ParameterSetName = 'Network')]
        [ValidatePattern('^([a-zA-Z0-9])|([ ]){2,244}$')]
        [string]$Network,

        [Parameter(ParameterSetName = 'Network')]
        [ValidatePattern('^(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9])[.]){3}(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9]))$')]
        [string]$IpAddress,

        [Parameter(ParameterSetName = 'Network')]
        [ValidatePattern('^(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9])[.]){3}(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9]))$')]
        [string]$Gateway,

        [Parameter(ParameterSetName = 'Network')]
        [ValidatePattern('^(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9])[.]){3}(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9]))$')]
        [string]$DnsServer1,

        [Parameter(ParameterSetName = 'Network')]
        [ValidatePattern('^(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9])[.]){3}(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9]))$')]
        [string]$DnsServer2,

        [Parameter(ParameterSetName = 'NetworkAdapter')]
        [AutomatedLab.NetworkAdapter[]]$NetworkAdapter,

        [switch]$IsDomainJoined,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]$DefaultDomain,

        [System.Management.Automation.PSCredential]$InstallationUserCredential,

        [ValidatePattern("(?=^.{1,254}$)|([\'\""])(^(?:(?!\d+\.|-)[a-zA-Z0-9_\-]{1,63}(?<!-)\.)+(?:[a-zA-Z]{2,})$)")]
        [string]$DomainName,

        [AutomatedLab.Role[]]$Roles,

        #Created ValidateSet using: "'" + ([System.Globalization.CultureInfo]::GetCultures([System.Globalization.CultureTypes]::InstalledWin32Cultures).Name -join "', '") + "'" | clip
        [ValidateScript( { $_ -in @([System.Globalization.CultureInfo]::GetCultures([System.Globalization.CultureTypes]::AllCultures).Name) })]
        [string]$UserLocale,

        [AutomatedLab.PostInstallationActivity[]]$PostInstallationActivity,

        [string]$ToolsPath,

        [string]$ToolsPathDestination,

        [AutomatedLab.VirtualizationHost]$VirtualizationHost = 'HyperV',

        [switch]$EnableWindowsFirewall,

        [string]$AutoLogonDomainName,

        [string]$AutoLogonUserName,

        [string]$AutoLogonPassword,

        [hashtable]$AzureProperties,

        [hashtable]$HypervProperties,

        [hashtable]$Notes,

        [switch]$PassThru,

        [string]$ResourceName,

        [switch]$SkipDeployment
    )
    DynamicParam
    {
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        #Parameter 'AzureRoleSize'
        $ParameterName = 'AzureRoleSize'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $AttributeCollection.Add($ParameterAttribute)
        $defaultLocation = (Get-LabAzureDefaultLocation -ErrorAction SilentlyContinue).Location
        if ($defaultLocation)
        {
            $vmSizes = Get-AzVMSize -Location $defaultLocation -ErrorAction SilentlyContinue | Where-Object -Property Name -notlike *basic* | Sort-Object -Property Name
            $validateSetValues = $vmSizes | Select-Object -ExpandProperty Name
            $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($validateSetValues)
            $AttributeCollection.Add($ValidateSetAttribute)
        }
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)

        #Parameter 'TimeZone'
        $ParameterName = 'TimeZone'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $AttributeCollection.Add($ParameterAttribute)
        $validateSetValues = ([System.TimeZoneInfo]::GetSystemTimeZones().Id | Sort-Object)
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($validateSetValues)
        $AttributeCollection.Add($ValidateSetAttribute)
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)

        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)

        #Parameter 'RhelPackage'
        $ParameterName = 'RhelPackage'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $AttributeCollection.Add($ParameterAttribute)
        if ($script:RedHatPackage.Count -gt 0)
        {
            $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute(([string[]]$script:RedHatPackage))
            $AttributeCollection.Add($ValidateSetAttribute)
        }
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string[]], $AttributeCollection)

        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)

        #Parameter 'SusePackage'
        $ParameterName = 'SusePackage'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $AttributeCollection.Add($ParameterAttribute)
        if ($script:SusePackage.Count -gt 0)
        {
            $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute(([string[]]$script:SusePackage))
            $AttributeCollection.Add($ValidateSetAttribute)
        }

        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string[]], $AttributeCollection)

        return $RuntimeParameterDictionary
    }

    begin
    {
        Write-LogFunctionEntry
        $AzureRoleSize = $PsBoundParameters['AzureRoleSize']
        $TimeZone = $PsBoundParameters['TimeZone']
        $SusePackage = $PsBoundParameters['SusePackage']
        $RhelPackage = $PsBoundParameters['RhelPackage']
    }

    process
    {
        $machineRoles = ''
        if ($Roles)
        {
            $machineRoles = " (Roles: $($Roles.Name -join ', '))" 
        }

        $azurePropertiesValidKeys = 'ResourceGroupName', 'UseAllRoleSizes', 'RoleSize', 'LoadBalancerRdpPort', 'LoadBalancerWinRmHttpPort', 'LoadBalancerWinRmHttpsPort', 'LoadBalancerAllowedIp', 'SubnetName', 'UseByolImage', 'AutoshutdownTime', 'AutoshutdownTimezoneId', 'StorageSku'
        $hypervPropertiesValidKeys = 'AutomaticStartAction', 'AutomaticStartDelay', 'AutomaticStopAction'

        if (-not $VirtualizationHost -and -not (Get-LabDefinition).DefaultVirtualizationEngine)
        {
            Throw "Parameter 'VirtualizationHost' is mandatory when calling 'Add-LabMachineDefinition' if no default virtualization engine is specified"
        }

        if (-not $PSBoundParameters.ContainsKey('VirtualizationHost') -and (Get-LabDefinition).DefaultVirtualizationEngine)
        {
            $VirtualizationHost = (Get-LabDefinition).DefaultVirtualizationEngine
        }

        Write-ScreenInfo -Message (("Adding $($VirtualizationHost.ToString().Replace('HyperV', 'Hyper-V')) machine definition '$Name'").PadRight(47) + $machineRoles) -TaskStart

        if (-not (Get-LabDefinition))
        {
            throw 'Please create a lab definition by calling New-LabDefinition before adding machines'
        }

        $script:lab = Get-LabDefinition
        if (($script:lab.DefaultVirtualizationEngine -eq 'Azure' -or $VirtualizationHost -eq 'Azure') -and -not $script:lab.AzureSettings)
        {
            try
            {
                Add-LabAzureSubscription
            }
            catch
            {
                throw "No Azure subscription added yet. Please run 'Add-LabAzureSubscription' first."
            }
        }

        if ($Global:labExported)
        {
            throw 'Lab is already exported. Please create a new lab definition by calling New-LabDefinition before adding machines'
        }

        if (Get-Lab -ErrorAction SilentlyContinue)
        {
            throw 'Lab is already imported. Please create a new lab definition by calling New-LabDefinition before adding machines'
        }

        if (-not $OperatingSystem)
        {
            $os = Get-LabAvailableOperatingSystem -UseOnlyCache -NoDisplay | Where-Object -Property OperatingSystemType -eq 'Windows' | Sort-Object Version | Select-Object -Last 1

            if ($null -ne $os)
            {
                Write-ScreenInfo -Message "No operating system specified. Assuming you want $os ($(Split-Path -Leaf -Path $os.IsoPath))."
                $OperatingSystem = $os
            }
            else
            {
                throw "No operating system was defined for machine '$Name' and no default operating system defined. Please define either of these and retry. Call 'Get-LabAvailableOperatingSystem' to get a list of operating systems added to the lab."
            }
        }

        if ($AzureProperties)
        {
            $illegalKeys = Compare-Object -ReferenceObject $azurePropertiesValidKeys -DifferenceObject ($AzureProperties.Keys | Sort-Object -Unique) |
            Where-Object SideIndicator -eq '=>' |
            Select-Object -ExpandProperty InputObject

            if ($AzureProperties.ContainsKey('StorageSku') -and ($AzureProperties['StorageSku'] -notin (Get-LabConfigurationItem -Name AzureDiskSkus)))
            {
                throw "$($AzureProperties['StorageSku']) is not in $(Get-LabConfigurationItem -Name AzureDiskSkus)"
            }

            if ($illegalKeys)
            {
                throw "The key(s) '$($illegalKeys -join ', ')' are not supported in AzureProperties. Valid keys are '$($azurePropertiesValidKeys -join ', ')'"
            }
        }
        if ($HypervProperties)
        {
            $illegalKeys = Compare-Object -ReferenceObject $hypervPropertiesValidKeys -DifferenceObject ($HypervProperties.Keys | Sort-Object -Unique) |
            Where-Object SideIndicator -eq '=>' |
            Select-Object -ExpandProperty InputObject

            if ($illegalKeys)
            {
                throw "The key(s) '$($illegalKeys -join ', ')' are not supported in HypervProperties. Valid keys are '$($hypervPropertiesValidKeys -join ', ')'"
            }
        }

        if ($global:labNamePrefix)
        {
            $Name = "$global:labNamePrefix$Name" 
        }

        if ($null -eq $script:machines)
        {
            $errorMessage = "Create a new lab first using 'New-LabDefinition' before adding machines"
            Write-Error $errorMessage
            Write-LogFunctionExitWithError -Message $errorMessage
            return
        }

        if ($script:machines | Where-Object Name -eq $Name)
        {
            $errorMessage = "A machine with the name '$Name' does already exist"
            Write-Error $errorMessage
            Write-LogFunctionExitWithError -Message $errorMessage
            return
        }

        if ($script:machines | Where-Object IpAddress.IpAddress -eq $IpAddress)
        {
            $errorMessage = "A machine with the IP address '$IpAddress' does already exist"
            Write-Error $errorMessage
            Write-LogFunctionExitWithError -Message $errorMessage
            return
        }

        $machine = New-Object AutomatedLab.Machine
        $machine.Name = $Name
        $machine.FriendlyName = $ResourceName
        $script:machines.Add($machine)

        if ((Get-LabDefinition).DefaultVirtualizationEngine -and (-not $PSBoundParameters.ContainsKey('VirtualizationHost')))
        {
            $VirtualizationHost = (Get-LabDefinition).DefaultVirtualizationEngine
        }

        if ($VirtualizationHost -eq 'Azure')
        {
            $script:lab.AzureSettings.LoadBalancerPortCounter++
            $machine.LoadBalancerRdpPort = $script:lab.AzureSettings.LoadBalancerPortCounter
            $script:lab.AzureSettings.LoadBalancerPortCounter++
            $machine.LoadBalancerWinRmHttpPort = $script:lab.AzureSettings.LoadBalancerPortCounter
            $script:lab.AzureSettings.LoadBalancerPortCounter++
            $machine.LoadBalancerWinrmHttpsPort = $script:lab.AzureSettings.LoadBalancerPortCounter
        }

        if ($InstallationUserCredential)
        {
            $installationUser = New-Object AutomatedLab.User($InstallationUserCredential.UserName, $InstallationUserCredential.GetNetworkCredential().Password)
        }
        else
        {
            if ((Get-LabDefinition).DefaultInstallationCredential)
            {
                $installationUser = New-Object AutomatedLab.User((Get-LabDefinition).DefaultInstallationCredential.UserName, (Get-LabDefinition).DefaultInstallationCredential.Password)
            }
            else
            {
                switch ($VirtualizationHost)
                {
                    'HyperV'
                    {
                        $installationUser = New-Object AutomatedLab.User('Administrator', 'Somepass1') 
                    }
                    'Azure'
                    {
                        $installationUser = New-Object AutomatedLab.User('Install', 'Somepass1') 
                    }
                    Default
                    {
                        $installationUser = New-Object AutomatedLab.User('Administrator', 'Somepass1') 
                    }
                }
            }
        }
        $machine.InstallationUser = $installationUser

        $machine.IsDomainJoined = $false

        if ($PSBoundParameters.ContainsKey('DefaultDomain') -and $DefaultDomain)
        {
            if (-not (Get-LabDomainDefinition))
            {
                if ($VirtualizationHost -eq 'Azure')
                {
                    Add-LabDomainDefinition -Name 'contoso.com' -AdminUser Install -AdminPassword 'Somepass1'
                }
                else
                {
                    Add-LabDomainDefinition -Name 'contoso.com' -AdminUser Administrator -AdminPassword 'Somepass1'
                }
            }

            $DomainName = (Get-LabDomainDefinition)[0].Name
        }

        if ($DomainName -or ($Roles -and $Roles.Name -match 'DC$'))
        {
            $machine.IsDomainJoined = $true

            if ($Roles.Name -eq 'RootDC' -or $Roles.Name -eq 'DC')
            {
                if (-not $DomainName)
                {
                    if (-not (Get-LabDomainDefinition))
                    {
                        $DomainName = 'contoso.com'
                        switch ($VirtualizationHost)
                        {
                            'Azure'
                            {
                                Add-LabDomainDefinition -Name $DomainName -AdminUser Install -AdminPassword Somepass1 
                            }
                            'HyperV'
                            {
                                Add-LabDomainDefinition -Name $DomainName -AdminUser Administrator -AdminPassword Somepass1 
                            }
                            'VMware'
                            {
                                Add-LabDomainDefinition -Name $DomainName -AdminUser Administrator -AdminPassword Somepass1 
                            }
                        }
                    }
                    else
                    {
                        throw 'Domain name not specified for Root Domain Controller'
                    }
                }
            }
            elseif ('FirstChildDC' -in $Roles.Name)
            {
                $role = $Roles | Where-Object Name -eq FirstChildDC
                $containsProperties = [boolean]$role.Properties
                if ($containsProperties)
                {
                    $parentDomainInProperties = $role.Properties.ParentDomain
                    $newDomainInProperties = $role.Properties.NewDomain

                    Write-PSFMessage -Message "Machine contains custom properties for FirstChildDC: 'ParentDomain'='$parentDomainInProperties', 'NewDomain'='$newDomainInProperties'"
                }

                if ((-not $containsProperties) -and (-not $DomainName))
                {
                    Write-PSFMessage -Message 'Nothing specified (no DomainName nor ANY Properties). Giving up'

                    throw 'Domain name not specified for Child Domain Controller'
                }

                if ((-not $DomainName) -and ((-not $parentDomainInProperties -or (-not $newDomainInProperties))))
                {
                    Write-PSFMessage -Message 'No DomainName or Properties for ParentName and NewDomain specified. Giving up'

                    throw 'Domain name not specified for Child Domain Controller'
                }

                if ($containsProperties -and $parentDomainInProperties -and $newDomainInProperties -and (-not $DomainName))
                {
                    Write-PSFMessage -Message 'Properties specified but DomainName is not. Then populate DomainName based on Properties'

                    $DomainName = "$($role.Properties.NewDomain).$($role.Properties.ParentDomain)"
                    Write-PSFMessage -Message "Machine contains custom properties for FirstChildDC but DomainName parameter is not specified. Setting now to '$DomainName'"
                }
                elseif (((-not $containsProperties) -or ($containsProperties -and (-not $parentDomainInProperties) -and (-not $newDomainInProperties))) -and $DomainName)
                {
                    $newDomainName = $DomainName.Substring(0, $DomainName.IndexOf('.'))
                    $parentDomainName = $DomainName.Substring($DomainName.IndexOf('.') + 1)

                    Write-PSFMessage -Message 'No Properties specified (or properties for ParentName and NewDomain omitted) but DomainName parameter is specified. Calculating/updating ParentDomain and NewDomain properties'
                    if (-not $containsProperties)
                    {
                        $role.Properties = @{ 'NewDomain' = $newDomainName }
                        $role.Properties.Add('ParentDomain', $parentDomainName)
                    }
                    else
                    {
                        if (-not $role.Properties.ContainsKey('NewDomain'))
                        {
                            $role.Properties.Add('NewDomain', $newDomainName)
                        }

                        if (-not $role.Properties.ContainsKey('ParentDomain'))
                        {
                            $role.Properties.Add('ParentDomain', $parentDomainName)
                        }
                    }
                    $parentDomainInProperties = $role.Properties.ParentDomain
                    $newDomainInProperties = $role.Properties.NewDomain
                    Write-PSFMessage -Message "ParentDomain now set to '$parentDomainInProperties'"
                    Write-PSFMessage -Message "NewDomain now set to '$newDomainInProperties'"
                }
            }

            if (-not (Get-LabDomainDefinition | Where-Object Name -eq $DomainName))
            {
                if ($VirtualizationHost -eq 'Azure')
                {
                    Add-LabDomainDefinition -Name $DomainName -AdminUser Install -AdminPassword 'Somepass1'
                }
                else
                {
                    Add-LabDomainDefinition -Name $DomainName -AdminUser Administrator -AdminPassword 'Somepass1'
                }
            }
            $machine.DomainName = $DomainName
        }

        if (-not $OperatingSystem.Version)
        {
            if ($OperatingSystemVersion)
            {
                $OperatingSystem.Version = $OperatingSystemVersion
            }
            else
            {
                throw "Could not identify the version of operating system '$($OperatingSystem.OperatingSystemName)' assigned to machine '$Name'. The version is required to continue."
            }
        }

        switch ($OperatingSystem.Version.ToString(2))
        {
            '6.0'
            {
                $level = 'Win2008' 
            }
            '6.1'
            {
                $level = 'Win2008R2' 
            }
            '6.2'
            {
                $level = 'Win2012' 
            }
            '6.3'
            {
                $level = 'Win2012R2' 
            }
            '6.4'
            {
                $level = 'WinThreshold' 
            }
            '10.0'
            {
                $level = 'WinThreshold' 
            }
        }

        $role = $roles | Where-Object Name -in ('RootDC', 'FirstChildDC', 'DC')
        if ($role)
        {
            if ($role.Properties)
            {
                if ($role.Name -eq 'RootDC')
                {
                    if (-not $role.Properties.ContainsKey('ForestFunctionalLevel'))
                    {
                        $role.Properties.Add('ForestFunctionalLevel', $level)
                    }
                }

                if ($role.Name -eq 'RootDC' -or $role.Name -eq 'FirstChildDC')
                {
                    if (-not $role.Properties.ContainsKey('DomainFunctionalLevel'))
                    {
                        $role.Properties.Add('DomainFunctionalLevel', $level)
                    }
                }
            }
            else
            {
                if ($role.Name -eq 'RootDC')
                {
                    $role.Properties = @{'ForestFunctionalLevel' = $level }
                    $role.Properties.Add('DomainFunctionalLevel', $level)
                }
                elseif ($role.Name -eq 'FirstChildDC')
                {
                    $role.Properties = @{'DomainFunctionalLevel' = $level }
                }
            }
        }

        #Virtual network detection and automatic creation
        if ($VirtualizationHost -eq 'Azure')
        {
            if (-not (Get-LabVirtualNetworkDefinition))
            {
                #No virtual networks has been specified

                Write-ScreenInfo -Message 'No virtual networks specified. Creating a network automatically' -Type Warning
                if (-not ($Global:existingAzureNetworks))
                {
                    $Global:existingAzureNetworks = Get-AzVirtualNetwork
                }

                #Virtual network name will be same as lab name
                $autoNetworkName = (Get-LabDefinition).Name

                #Priority 1. Check for existence of an Azure virtual network with same name as network name
                $existingNetwork = $Global:existingAzureNetworks | Where-Object { $_.Name -eq $autoNetworkName }
                if ($existingNetwork)
                {
                    Write-PSFMessage -Message 'Virtual switch already exists with same name as lab being deployed. Trying to re-use.'
                    $addressSpace = $existingNetwork.AddressSpace.AddressPrefixes

                    Write-ScreenInfo -Message "Creating virtual network '$autoNetworkName' with address spacee '$addressSpace'" -Type Warning
                    Add-LabVirtualNetworkDefinition -Name $autoNetworkName -AddressSpace $addressSpace[0]

                    #First automatically assigned IP address will be following+1
                    $addressSpaceIpAddress = "$($addressSpace.Split('/')[0].Split('.')[0..2] -Join '.').5"
                    $script:autoIPAddress = [AutomatedLab.IPAddress]$addressSpaceIpAddress

                    $notDone = $false
                }
                else
                {
                    Write-PSFMessage -Message 'No Azure virtual network found with same name as network name. Attempting to find unused network in the range 192.168.2.x-192.168.255.x'

                    $networkFound = $false
                    [int]$octet = 1
                    do
                    {
                        $octet++

                        $azureInUse = $false
                        foreach ($azureNetwork in $Global:existingAzureNetworks.AddressSpace.AddressPrefixes)
                        {
                            if (Test-IpInSameSameNetwork -Ip1 "192.168.$octet.0/24" -Ip2 $azureNetwork)
                            {
                                $azureInUse = $true
                            }
                        }
                        if ($azureInUse)
                        {
                            Write-PSFMessage -Message "Network '192.168.$octet.0/24' is in use by an existing Azure virtual network"
                            continue
                        }

                        $networkFound = $true
                    }
                    until ($networkFound -or $octet -ge 255)

                    if ($networkFound)
                    {
                        Write-ScreenInfo "Creating virtual network with name '$autoNetworkName' and address space '192.168.$octet.1/24'" -Type Warning
                        Add-LabVirtualNetworkDefinition -Name $autoNetworkName  -AddressSpace "192.168.$octet.1/24"
                    }
                    else
                    {
                        throw 'Virtual network could not be created. Please create virtual network manually by calling Add-LabVirtualNetworkDefinition (after calling New-LabDefinition)'
                    }

                    #First automatically asigned IP address will be following+1
                    $script:autoIPAddress = ([AutomatedLab.IPAddress]("192.168.$octet.5")).AddressAsString
                }

                #throw 'No virtual network is defined. Please call Add-LabVirtualNetworkDefinition before adding machines but after calling New-LabDefinition'
            }
        }
        elseif ($VirtualizationHost -eq 'HyperV')
        {
            Write-PSFMessage -Message 'Detect if a virtual switch already exists with same name as lab being deployed. If so, use this switch for defining network name and address space.'

            #this takes a lot of time hence it should be called only once in a deployment
            if (-not $script:existingHyperVVirtualSwitches)
            {
                $script:existingHyperVVirtualSwitches = Get-LabVirtualNetwork
            }

            $networkDefinitions = Get-LabVirtualNetworkDefinition

            if (-not $networkDefinitions)
            {
                #No virtual networks has been specified

                Write-ScreenInfo -Message 'No virtual networks specified. Creating a network automatically' -Type Warning

                #Virtual network name will be same as lab name
                $autoNetworkName = (Get-LabDefinition).Name

                #Priority 1. Check for existence of Hyper-V virtual switch with same name as network name
                $existingNetwork = $existingHyperVVirtualSwitches | Where-Object Name -eq $autoNetworkName
                if ($existingNetwork)
                {
                    Write-PSFMessage -Message 'Virtual switch already exists with same name as lab being deployed. Trying to re-use.'

                    Write-ScreenInfo -Message "Using virtual network '$autoNetworkName' with address space '$addressSpace'" -Type Info
                    Add-LabVirtualNetworkDefinition -Name $autoNetworkName -AddressSpace $existingNetwork.AddressSpace
                }
                else
                {
                    Write-PSFMessage -Message 'No virtual switch found with same name as network name. Attempting to find unused network'

                    $addressSpace = Get-LabAvailableAddresseSpace

                    if ($addressSpace)
                    {
                        Write-ScreenInfo "Creating network '$autoNetworkName' with address space '$addressSpace'" -Type Warning
                        Add-LabVirtualNetworkDefinition -Name $autoNetworkName  -AddressSpace $addressSpace
                    }
                    else
                    {
                        throw 'Virtual network could not be created. Please create virtual network manually by calling Add-LabVirtualNetworkDefinition (after calling New-LabDefinition)'
                    }
                }
            }
            else
            {
                Write-PSFMessage -Message 'One or more virtual network(s) has been specified.'

                #Using first specified virtual network '$($networkDefinitions[0])' with address space '$($networkDefinitions[0].AddressSpace)'."

                <#
                        if ($script:autoIPAddress)
                        {
                        #Network already created and IP range already found
                        Write-PSFMessage -Message 'Network already created and IP range already found'
                        }
                        else
                        {
                #>

                foreach ($networkDefinition in $networkDefinitions)
                {
                    #check for an virtual switch having already the name of the new network switch
                    $existingNetwork = $existingHyperVVirtualSwitches | Where-Object Name -eq $networkDefinition.ResourceName

                    #does the current network definition has an address space assigned
                    if ($networkDefinition.AddressSpace)
                    {
                        Write-PSFMessage -Message "Virtual network '$($networkDefinition.ResourceName)' specified with address space '$($networkDefinition.AddressSpace)'"

                        #then check if the existing network has the same address space as the new one and throw an exception if not
                        if ($existingNetwork)
                        {
                            if ($existingNetwork.SwitchType -eq 'External')
                            {
                                #Different address spaces for different labs reusing an existing External virtual switch is permitted, however this requires knowledge and support
                                # for switching / routing fabrics external to AL and the host. Note to the screen this is an advanced configuration.
                                if ($networkDefinition.AddressSpace -ne $existingNetwork.AddressSpace)
                                {
                                    Write-ScreenInfo "Address space defined '$($networkDefinition.AddressSpace)' for network '$networkDefinition' is different from the address space '$($existingNetwork.AddressSpace)' used by currently existing Hyper-V switch with same name." -Type Warning
                                    Write-ScreenInfo "This is an advanced configuration, ensure external switching and routing is configured correctly" -Type Warning
                                    Write-PSFMessage -Message 'Existing External Hyper-V virtual switch found with different address space. This is an allowed advanced configuration'
                                }
                                else
                                {
                                    Write-PSFMessage -Message 'Existing External Hyper-V virtual switch found with same name and address space as first virtual network specified. Using this.'
                                }
                            }
                            else
                            {
                                if ($networkDefinition.AddressSpace -ne $existingNetwork.AddressSpace)
                                {
                                    throw "Address space defined '$($networkDefinition.AddressSpace)' for network '$networkDefinition' is different from the address space '$($existingNetwork.AddressSpace)' used by currently existing Hyper-V switch with same name. Cannot continue."
                                }
                            }
                        }
                        else
                        {
                            #if the network does not already exist, verify if the address space if not already assigned
                            $otherHypervSwitch = $existingHyperVVirtualSwitches | Where-Object AddressSpace -eq $networkDefinition.AddressSpace
                            if ($otherHypervSwitch)
                            {
                                throw "Another Hyper-V virtual switch '$($otherHypervSwitch.Name)' is using address space specified in this lab ($($networkDefinition.AddressSpace)). Cannot continue."
                            }

                            #and also verify that the new address space is not overlapping with an exsiting one
                            $otherHypervSwitch = $existingHyperVVirtualSwitches |
                            Where-Object { $_.AddressSpace } |
                            Where-Object { [AutomatedLab.IPNetwork]::Overlap($_.AddressSpace, $networkDefinition.AddressSpace) } |
                            Select-Object -First 1

                            if ($otherHypervSwitch)
                            {
                                throw "The Hyper-V virtual switch '$($otherHypervSwitch.Name)' is using an address space ($($otherHypervSwitch.AddressSpace)) that overlaps with the specified one in this lab ($($networkDefinition.AddressSpace)). Cannot continue."
                            }

                            Write-PSFMessage -Message 'Address space specified is valid'
                        }
                    }
                    else
                    {
                        if ($networkDefinition.SwitchType -eq 'External')
                        {
                            Write-PSFMessage 'External network interfaces will not get automatic IP addresses'
                            continue
                        }

                        Write-PSFMessage -Message "Virtual network '$networkDefinition' specified but without address space specified"

                        if ($existingNetwork)
                        {
                            Write-PSFMessage -Message "Existing Hyper-V virtual switch found with same name as first virtual network name. Using it with address space '$($existingNetwork.AddressSpace)'."
                            $networkDefinition.AddressSpace = $existingNetwork.AddressSpace
                        }
                        else
                        {
                            Write-PSFMessage -Message 'No Hyper-V virtual switch found with same name as lab name. Attempting to find unused network.'

                            $addressSpace = Get-LabAvailableAddresseSpace

                            if ($addressSpace)
                            {
                                Write-ScreenInfo "Using network '$networkDefinition' with address space '$addressSpace'" -Type Warning
                                $networkDefinition.AddressSpace = $addressSpace
                            }
                            else
                            {
                                throw 'Virtual network could not be used. Please create virtual network manually by calling Add-LabVirtualNetworkDefinition (after calling New-LabDefinition)'
                            }
                        }
                    }
                }
            }
        }

        if ($Network)
        {
            $networkDefinition = Get-LabVirtualNetworkDefinition -Name $network
            if (-not $networkDefinition)
            {
                throw "A virtual network definition with the name '$Network' could not be found. To get a list of network definitions, use 'Get-LabVirtualNetworkDefinition'"
            }

            if ($networkDefinition.SwitchType -eq 'External' -and -not $networkDefinition.AddressSpace -and -not $IpAddress)
            {
                $useDhcp = $true
            }

            $NetworkAdapter = New-LabNetworkAdapterDefinition -VirtualSwitch $networkDefinition.Name -UseDhcp:$useDhcp
        }
        elseif (-not $NetworkAdapter)
        {
            if ((Get-LabVirtualNetworkDefinition).Count -eq 1)
            {
                $networkDefinition = Get-LabVirtualNetworkDefinition

                $NetworkAdapter = New-LabNetworkAdapterDefinition -VirtualSwitch $networkDefinition.Name

            }
            else
            {
                throw "Network cannot be determined for machine '$machine'. Either no networks is defined or more than one network is defined while network is not specified when calling this function"
            }
        }

        $machine.HostType = $VirtualizationHost

        foreach ($adapter in $NetworkAdapter)
        {
            $adapterVirtualNetwork = Get-LabVirtualNetworkDefinition -Name $adapter.VirtualSwitch
            $adapter.InterfaceName = "Ethernet ($($adapterVirtualNetwork.Name))"
            #if there is no IPV4 address defined on the adapter
            if (-not $adapter.IpV4Address)
            {
                #if there is also no IP address defined on the machine and the adapter is not set to DHCP and the network the adapter is connected to does not know about an address space we cannot continue
                if (-not $IpAddress -and -not $adapter.UseDhcp -and -not $adapterVirtualNetwork.AddressSpace)
                {
                    throw "The virtual network '$adapterVirtualNetwork' defined on machine '$machine' does not have an IP address assigned and is not set to DHCP"
                }
                elseif ($IpAddress)
                {
                    if ($AzureProperties.SubnetName -and $adapterVirtualNetwork.Subnets.Count -gt 0)
                    {
                        $chosenSubnet = $adapterVirtualNetwork.Subnets | Where-Object Name -EQ $AzureProperties.SubnetName
                        if (-not $chosenSubnet)
                        {
                            throw ('No fitting subnet available. Subnet {0} could not be found in the list of available subnets {1}' -f $AzureProperties.SubnetName, ($adapterVirtualNetwork.Subnets.Name -join ','))
                        }

                        $adapter.Ipv4Address.Add([AutomatedLab.IPNetwork]::Parse($IpAddress, $chosenSubnet.AddressSpace.Netmask))
                    }
                    elseif ($VirtualizationHost -eq 'Azure' -and $adapterVirtualNetwork.Subnets.Count -gt 0 -and -not $AzureProperties.SubnetName)
                    {
                        # No default subnet and no name selected. Chose fitting subnet.
                        $chosenSubnet = $adapterVirtualNetwork.Subnets | Where-Object { $IpAddress -in (Get-NetworkRange -IPAddress $_.AddressSpace.IpAddress -SubnetMask $_.AddressSpace.Netmask) }
                        if (-not $chosenSubnet)
                        {
                            throw ('No fitting subnet available. No subnet was found with a valid address range. {0} was not in the range of these subnets: ' -f $IpAddress, ($adapterVirtualNetwork.Subnets.Name -join ','))
                        }

                        $adapter.Ipv4Address.Add([AutomatedLab.IPNetwork]::Parse($IpAddress, $chosenSubnet.AddressSpace.Netmask))
                    }
                    else
                    {
                        $adapter.Ipv4Address.Add([AutomatedLab.IPNetwork]::Parse($IpAddress, $adapterVirtualNetwork.AddressSpace.Netmask))
                    }
                }
                elseif (-not $adapter.UseDhcp)
                {
                    $ip = $adapterVirtualNetwork.NextIpAddress()

                    if ($AzureProperties.SubnetName -and $adapterVirtualNetwork.Subnets.Count -gt 0)
                    {
                        $chosenSubnet = $adapterVirtualNetwork.Subnets | Where-Object Name -EQ $AzureProperties.SubnetName
                        if (-not $chosenSubnet)
                        {
                            throw ('No fitting subnet available. Subnet {0} could not be found in the list of available subnets {1}' -f $AzureProperties.SubnetName, ($adapterVirtualNetwork.Subnets.Name -join ','))
                        }

                        $adapter.Ipv4Address.Add([AutomatedLab.IPNetwork]::Parse($ip, $chosenSubnet.AddressSpace.Netmask))
                    }
                    elseif ($VirtualizationHost -eq 'Azure' -and $adapterVirtualNetwork.Subnets.Count -gt 0 -and -not $AzureProperties.SubnetName)
                    {
                        # No default subnet and no name selected. Chose fitting subnet.
                        $chosenSubnet = $adapterVirtualNetwork.Subnets | Where-Object { $ip -in (Get-NetworkRange -IPAddress $_.AddressSpace.IpAddress -SubnetMask $_.AddressSpace.Netmask) }
                        if (-not $chosenSubnet)
                        {
                            throw ('No fitting subnet available. No subnet was found with a valid address range. {0} was not in the range of these subnets: ' -f $IpAddress, ($adapterVirtualNetwork.Subnets.Name -join ','))
                        }

                        $adapter.Ipv4Address.Add([AutomatedLab.IPNetwork]::Parse($ip, $chosenSubnet.AddressSpace.Netmask))
                    }
                    else
                    {
                        $adapter.Ipv4Address.Add([AutomatedLab.IPNetwork]::Parse($ip, $adapterVirtualNetwork.AddressSpace.Netmask))
                    }
                }
            }

            if ($DnsServer1)
            {
                $adapter.Ipv4DnsServers.Add($DnsServer1) 
            }
            if ($DnsServer2)
            {
                $adapter.Ipv4DnsServers.Add($DnsServer2) 
            }

            #if the virtual network is not external, the machine is not an Azure one, is domain joined and there is no DNS server configured
            if ($adapter.VirtualSwitch.SwitchType -ne 'External' -and
                $machine.HostType -ne 'Azure' -and
                #$machine.IsDomainJoined -and
                -not $adapter.UseDhcp -and
                -not ($DnsServer1 -or $DnsServer2
                ))
            {
                $adapter.Ipv4DnsServers.Add('0.0.0.0')
            }

            if ($Gateway)
            {
                $adapter.Ipv4Gateway.Add($Gateway) 
            }

            $machine.NetworkAdapters.Add($adapter)
        }

        Repair-LabDuplicateIpAddresses

        if ($processors -eq 0)
        {
            $processors = 1
            if (-not $script:processors)
            {
                $script:processors = if ($IsLinux -or $IsMacOs)
                {
                    $coreInf = Get-Content /proc/cpuinfo | Select-String 'siblings\s+:\s+\d+' | Select-Object -Unique
                    [int]($coreInf -replace 'siblings\s+:\s+')
                }
                else
                {
                    (Get-CimInstance -Namespace Root\CIMv2 -Class win32_processor).NumberOfLogicalProcessors 
                }
            }
            if ($script:processors -ge 2)
            {
                $machine.Processors = 2
            }
        }
        else
        {
            $machine.Processors = $Processors
        }


        if ($PSBoundParameters.ContainsKey('Memory'))
        {
            $machine.Memory = $Memory
        }
        else
        {
            $machine.Memory = 1

            #Memory weight based on role of machine
            $machine.Memory = 1
            foreach ($role in $Roles)
            {
                if ((Get-LabConfigurationItem -Name "MemoryWeight_$($role.Name)") -gt $machine.Memory)
                {
                    $machine.Memory = Get-LabConfigurationItem -Name "MemoryWeight_$($role.Name)"
                }
            }
        }

        if ($PSBoundParameters.ContainsKey('MinMemory'))
        {
            $machine.MinMemory = $MinMemory
        }
        if ($PSBoundParameters.ContainsKey('MaxMemory'))
        {
            $machine.MaxMemory = $MaxMemory
        }

        $machine.EnableWindowsFirewall = $EnableWindowsFirewall

        $machine.AutoLogonDomainName = $AutoLogonDomainName
        $machine.AutoLogonUserName = $AutoLogonUserName
        $machine.AutoLogonPassword = $AutoLogonPassword

        if ($machine.HostType -eq 'HyperV')
        {
            if ($RhelPackage)
            {
                $machine.LinuxPackageGroup = $RhelPackage
            }
            if ($SusePackage)
            {
                $machine.LinuxPackageGroup = $SusePackage
            }

            if ($OperatingSystemVersion)
            {
                $os = Get-LabAvailableOperatingSystem -NoDisplay | Where-Object { $_.OperatingSystemName -eq $OperatingSystem -and $_.Version -eq $OperatingSystemVersion }
            }
            else
            {
                $os = Get-LabAvailableOperatingSystem -NoDisplay | Where-Object OperatingSystemName -eq $OperatingSystem
                if ($os.Count -gt 1)
                {
                    $os = $os | Group-Object -Property Version | Sort-Object -Property Name -Descending | Select-Object -First 1 | Select-Object -ExpandProperty Group
                    Write-ScreenInfo "The operating system '$OperatingSystem' is available multiple times. Choosing the one with the highest version ($($os[0].Version))" -Type Warning
                }

                if ($os.Count -gt 1)
                {
                    $os = $os | Sort-Object -Property { (Get-Item -Path $_.IsoPath).LastWriteTime } -Descending | Select-Object -First 1
                    Write-ScreenInfo "The operating system '$OperatingSystem' with the same version is available on multiple images. Choosing the one with the highest LastWriteTime to honor updated images ($((Get-Item -Path $os.IsoPath).LastWriteTime))" -Type Warning
                }
            }

            if (-not $os)
            {
                if ($OperatingSystemVersion)
                {
                    throw "The operating system '$OperatingSystem' for machine '$Name' with version '$OperatingSystemVersion' could not be found in the available operating systems. Call 'Get-LabAvailableOperatingSystem' to get a list of operating systems added to the lab."
                }
                else
                {
                    throw "The operating system '$OperatingSystem' for machine '$Name' could not be found in the available operating systems. Call 'Get-LabAvailableOperatingSystem' to get a list of operating systems added to the lab."
                }
            }
            $machine.OperatingSystem = $os
        }
        elseif ($machine.HostType -eq 'Azure')
        {
            $machine.OperatingSystem = $OperatingSystem
        }
        elseif ($machine.HostType -eq 'VMWare')
        {
            $machine.OperatingSystem = $OperatingSystem
        }

        if (-not $TimeZone)
        {
            $TimeZone = (Get-TimeZone).StandardName
        }
        $machine.Timezone = $TimeZone

        if (-not $UserLocale)
        {
            $UserLocale = (Get-Culture).Name -replace '-POSIX'
        }
        $machine.UserLocale = $UserLocale

        $machine.Roles = $Roles
        $machine.PostInstallationActivity = $PostInstallationActivity

        if ($HypervProperties)
        {
            $machine.HypervProperties = $HypervProperties
        }

        if ($AzureProperties)
        {
            $machine.AzureProperties = $AzureProperties
        }
        if ($AzureRoleSize)
        {
            if (-not $AzureProperties)
            {
                $machine.AzureProperties = @{ RoleSize = $AzureRoleSize }
            }
            else
            {
                $machine.AzureProperties.RoleSize = $AzureRoleSize
            }
        }

        $machine.ToolsPath = $ToolsPath.Replace('<machinename>', $machine.Name)

        $machine.ToolsPathDestination = $ToolsPathDestination

        $type = Get-Type -GenericType AutomatedLab.ListXmlStore -T AutomatedLab.Disk
        $machine.Disks = New-Object $type

        if ($DiskName)
        {
            foreach ($disk in $DiskName)
            {
                $labDisk = $script:disks | Where-Object Name -eq $disk
                if (-not $labDisk)
                {
                    throw "The disk with the name '$disk' has not yet been added to the lab. Do this first using the cmdlet 'Add-LabDiskDefinition'"
                }
                $machine.Disks.Add($labDisk)
            }
        }

        $machine.SkipDeployment = $SkipDeployment
    }

    end
    {
        if ($Notes)
        {
            $machine.Notes = $Notes
        }

        Write-ScreenInfo -Message 'Done' -TaskEnd

        if ($PassThru)
        {
            $machine
        }

        Write-LogFunctionExit
    }
}
#endregion Add-LabMachineDefinition

#region Get-LabMachineDefinition
function Get-LabMachineDefinition
{
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    [OutputType([AutomatedLab.Machine])]

    param (
        [Parameter(Position = 0, ParameterSetName = 'ByName', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName,

        [Parameter(Mandatory, ParameterSetName = 'ByRole')]
        [AutomatedLab.Roles]$Role,

        [Parameter(Mandatory, ParameterSetName = 'All')]
        [switch]$All
    )

    begin
    {
        #required to suporess verbose messages, warnings and errors
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        Write-LogFunctionEntry

        $result = @()
    }

    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'ByName')
        {
            if ($ComputerName)
            {
                foreach ($n in $ComputerName)
                {
                    $machine = $Script:machines | Where-Object Name -in $n
                    if (-not $machine)
                    {
                        continue
                    }

                    $result += $machine
                }
            }
            else
            {
                $result = $Script:machines
            }
        }

        if ($PSCmdlet.ParameterSetName -eq 'ByRole')
        {
            $result = $Script:machines |
            Where-Object { $_.Roles.Name } |
            Where-Object { $_.Roles | Where-Object { $Role.HasFlag([AutomatedLab.Roles]$_.Name) } }

            if (-not $result)
            {
                return
            }
        }

        if ($PSCmdlet.ParameterSetName -eq 'All')
        {
            $result = $Script:machines
        }
    }

    end
    {
        $result
    }
}
#endregion Get-LabMachineDefinition

#region Remove-LabMachineDefinition
function Remove-LabMachineDefinition
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$Name
    )

    Write-LogFunctionEntry

    $machine = $script:machines | Where-Object Name -eq $Name

    if (-not $machine)
    {
        Write-ScreenInfo "There is no machine defined with the name '$Name'" -Type Warning
    }
    else
    {
        [Void]$script:machines.Remove($machine)
        Write-PSFMessage "Machine '$Name' removed. Lab has $($Script:machines.Count) machine(s) defined"
    }

    Write-LogFunctionExit
}
#endregion Remove-LabMachineDefinition

#region Get-LabMachineRoleDefinition
function Get-LabMachineRoleDefinition
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [AutomatedLab.Roles]$Role,

        [hashtable]$Properties
    )

    $roleObjects = @()
    $availableRoles = [Enum]::GetNames([AutomatedLab.Roles])

    foreach ($availableRole in $availableRoles)
    {
        if ($Role.HasFlag([AutomatedLab.Roles]$availableRole))
        {
            $roleObject = New-Object -TypeName AutomatedLab.Role
            $roleObject.Name = $availableRole
            $roleObject.Properties = $Properties

            $roleObjects += $roleObject
        }
    }

    return $roleObjects
}
#endregion Get-LabMachineRoleDefinition

#region Get-LabPostInstallationActivity
function Get-LabPostInstallationActivity
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName = 'FileContentDependencyRemoteScript')]
        [Parameter(Mandatory, ParameterSetName = 'FileContentDependencyLocalScript')]
        [string]$DependencyFolder,

        [Parameter(Mandatory, ParameterSetName = 'IsoImageDependencyRemoteScript')]
        [Parameter(Mandatory, ParameterSetName = 'IsoImageDependencyLocalScript')]
        [string]$IsoImage,

        [Parameter(ParameterSetName = 'FileContentDependencyRemoteScript')]
        [Parameter(ParameterSetName = 'FileContentDependencyLocalScript')]
        [Parameter(ParameterSetName = 'CustomRole')]
        [switch]$KeepFolder,

        [Parameter(Mandatory, ParameterSetName = 'FileContentDependencyRemoteScript')]
        [Parameter(Mandatory, ParameterSetName = 'IsoImageDependencyRemoteScript')]
        [string]$ScriptFileName,

        [Parameter(Mandatory, ParameterSetName = 'IsoImageDependencyLocalScript')]
        [Parameter(Mandatory, ParameterSetName = 'FileContentDependencyLocalScript')]
        [string]$ScriptFilePath,

        [Parameter(ParameterSetName = 'CustomRole')]
        [hashtable]$Properties,

        [switch]$DoNotUseCredSsp
    )
    DynamicParam
    {
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        $ParameterName = 'CustomRole'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.ParameterSetName = 'CustomRole'
        $AttributeCollection.Add($ParameterAttribute)
        $arrSet = (Get-ChildItem -Path (Join-Path -Path (Get-LabSourcesLocationInternal -Local) -ChildPath 'CustomRoles' -ErrorAction SilentlyContinue) -Directory -ErrorAction SilentlyContinue).Name

        if ($arrSet)
        {
            $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)
            $AttributeCollection.Add($ValidateSetAttribute)
            $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)

            $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
            return $RuntimeParameterDictionary
        }
    }

    begin
    {
        Write-LogFunctionEntry
        $CustomRole = $PsBoundParameters['CustomRole']
        $activity = New-Object -TypeName AutomatedLab.PostInstallationActivity
        if (-not $Properties)
        {
            $Properties = @{ } 
        }
    }

    process
    {
        if ($PSCmdlet.ParameterSetName -like 'FileContentDependency*')
        {
            $activity.DependencyFolder = $DependencyFolder
            $activity.KeepFolder = $KeepFolder.ToBool()
            if ($ScriptFilePath)
            {
                $activity.ScriptFilePath = $ScriptFilePath
            }
            else
            {
                $activity.ScriptFileName = $ScriptFileName
            }
        }
        elseif ($PSCmdlet.ParameterSetName -like 'IsoImage*')
        {
            $activity.IsoImage = $IsoImage
            if ($ScriptFilePath)
            {
                $activity.ScriptFilePath = $ScriptFilePath
            }
            else
            {
                $activity.ScriptFileName = $ScriptFileName
            }
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'CustomRole')
        {
            $activity.DependencyFolder = Join-Path -Path (Join-Path -Path (Get-LabSourcesLocation -Local) -ChildPath 'CustomRoles') -ChildPath $CustomRole
            $activity.KeepFolder = $KeepFolder.ToBool()
            $activity.ScriptFileName = "$CustomRole.ps1"
            $activity.IsCustomRole = $true

            #The next sections compares the given custom role properties with with the custom role parameters.
            #Custom role parameters are taken form the main role script as well as the HostStart.ps1 and the HostEnd.ps1
            $scripts = $activity.ScriptFileName, 'HostStart.ps1', 'HostEnd.ps1'
            $unknownParameters = New-Object System.Collections.Generic.List[string]

            foreach ($script in $scripts)
            {
                $scriptFullName = Join-Path -Path $activity.DependencyFolder -ChildPath $script
                if (-not (Test-Path -Path $scriptFullName))
                {
                    continue
                }
                $scriptInfo = Get-Command -Name $scriptFullName
                $commonParameters = [System.Management.Automation.Internal.CommonParameters].GetProperties().Name
                $parameters = $scriptInfo.Parameters.GetEnumerator() | Where-Object Key -NotIn $commonParameters

                #If the custom role knows about a ComputerName parameter and if there is no value defined by the user, add add empty value now.
                #Later that will be filled with the computer name of the computer the role is assigned to when the HostStart and the HostEnd scripts are invoked.
                if ($Properties)
                {
                    if (($parameters | Where-Object Key -eq 'ComputerName') -and -not $Properties.ContainsKey('ComputerName'))
                    {
                        $Properties.Add('ComputerName', '')
                    }
                }

                #test if all mandatory parameters are defined
                foreach ($parameter in $parameters)
                {
                    if ($parameter.Value.Attributes.Mandatory -and -not $properties.ContainsKey($parameter.Key))
                    {
                        Write-Error "There is no value defined for mandatory property '$($parameter.Key)' and custom role '$CustomRole'" -ErrorAction Stop
                    }
                }

                #test if there are custom role properties defined that do not map to the custom role parameters
                if ($Properties)
                {
                    foreach ($property in $properties.GetEnumerator())
                    {
                        if (-not $scriptInfo.Parameters.ContainsKey($property.Key) -and -not $unknownParameters.Contains($property.Key))
                        {
                            $unknownParameters.Add($property.Key)
                        }
                    }
                }
            }

            #antoher loop is required to remove all unknown parameters that are added due to the order of the first loop
            foreach ($script in $scripts)
            {
                $scriptFullName = Join-Path -Path $activity.DependencyFolder -ChildPath $script
                if (-not (Test-Path -Path $scriptFullName))
                {
                    continue
                }
                $scriptInfo = Get-Command -Name $scriptFullName
                $commonParameters = [System.Management.Automation.Internal.CommonParameters].GetProperties().Name
                $parameters = $scriptInfo.Parameters.GetEnumerator() | Where-Object Key -NotIn $commonParameters

                if ($Properties)
                {
                    foreach ($property in $properties.GetEnumerator())
                    {
                        if ($scriptInfo.Parameters.ContainsKey($property.Key) -and $unknownParameters.Contains($property.Key))
                        {
                            $unknownParameters.Remove($property.Key) | Out-Null
                        }
                    }
                }
            }

            if ($unknownParameters.Count -gt 0)
            {
                Write-Error "The defined properties '$($unknownParameters -join ', ')' are unknown for custom role '$CustomRole'" -ErrorAction Stop
            }

            if ($Properties)
            {
                foreach ($kvp in $Properties.GetEnumerator())
                {
                    [object[]]$toList = $kvp.Value
                    $activity.Properties.Add($kvp.Key, $toList )
                }
            }
        }

        $activity.DoNotUseCredSsp = $DoNotUseCredSsp
    }

    end
    {
        Write-LogFunctionExit -ReturnValue $activity
        return $activity
    }
}
#endregion Get-PostInstallationActivity
#endregion Machine Definition Functions

#region Get-DiskSpeed
function Get-DiskSpeed
{
    [CmdletBinding()]
    param (
        [ValidatePattern('[a-zA-Z]')]
        [Parameter(Mandatory)]
        [string]$DriveLetter,

        [ValidateRange(1, 50)]
        [int]$Interations = 1
    )

    Write-LogFunctionEntry

    if (-not $labSources)
    {
        $labSources = Get-LabSourcesLocation
    }

    $IsReadOnly = Get-Partition -DriveLetter ($DriveLetter.TrimEnd(':')) | Select-Object -ExpandProperty IsReadOnly
    if ($IsReadOnly)
    {
        Write-ScreenInfo -Message "Drive $DriveLetter is read-only. Skipping disk speed test" -Type Warning

        $readThroughoutRandom = 0
        $writeThroughoutRandom = 0
    }
    else
    {
        Write-ScreenInfo -Message "Measuring speed of drive $DriveLetter" -Type Info

        $tempFileName = [System.IO.Path]::GetTempFileName()

        & "$labSources\Tools\WinSAT.exe" disk -ran -read -count $Interations -drive $DriveLetter -xml $tempFileName | Out-Null
        $readThroughoutRandom = (Select-Xml -Path $tempFileName -XPath '/WinSAT/Metrics/DiskMetrics/AvgThroughput').Node.'#text'

        & "$labSources\Tools\WinSAT.exe" disk -ran -write -count $Interations -drive $DriveLetter -xml $tempFileName | Out-Null
        $writeThroughoutRandom = (Select-Xml -Path $tempFileName -XPath '/WinSAT/Metrics/DiskMetrics/AvgThroughput').Node.'#text'

        Remove-Item -Path $tempFileName
    }

    $result = New-Object PSObject -Property ([ordered]@{
            ReadRandom  = $readThroughoutRandom
            WriteRandom = $writeThroughoutRandom
        })

    $result

    Write-LogFunctionExit
}
#endregion

#region Set-LabLocalVirtualMachineDiskAuto
function Set-LabLocalVirtualMachineDiskAuto
{
    [CmdletBinding()]
    param
    (
        [int64]
        $SpaceNeeded
    )

    $type = Get-Type -GenericType AutomatedLab.ListXmlStore -T AutomatedLab.LocalDisk
    $drives = New-Object $type

    #read the cache
    try
    {
        if ($IsLinux -or $IsMacOs)
        {
            $cachedDrives = $type::Import((Join-Path -Path (Get-LabConfigurationItem -Name LabAppDataRoot) -ChildPath 'Stores/LocalDisks.xml'))
        }
        else
        {
            $cachedDrives = $type::ImportFromRegistry('Cache', 'LocalDisks')
        }
        Write-PSFMessage "Read $($cachedDrives.Count) drive infos from the cache"
    }
    catch
    {
        Write-PSFMessage 'Could not read info from the cache'
    }

    #Retrieve drives with enough space for placement of VMs
    foreach ($drive in (Get-LabVolumesOnPhysicalDisks | Where-Object FreeSpace -ge $SpaceNeeded))
    {
        $drives.Add($drive)
    }

    if (-not $drives)
    {
        return $false
    }

    #if the current disk config is different from the is in the cache, wait until the running lab deployment is done.
    if ($cachedDrives -and (Compare-Object -ReferenceObject $drives.DriveLetter -DifferenceObject $cachedDrives.DriveLetter))
    {
        $labDiskDeploymentInProgressPath = Get-LabConfigurationItem -Name DiskDeploymentInProgressPath
        if (Test-Path -Path $labDiskDeploymentInProgressPath)
        {
            Write-ScreenInfo "Another lab disk deployment seems to be in progress. If this is not correct, please delete the file '$labDiskDeploymentInProgressPath'." -Type Warning
            Write-ScreenInfo "Waiting with 'Get-DiskSpeed' until other disk deployment is finished. Otherwise a mounted virtual disk could be chosen for deployment." -NoNewLine
            do
            {
                Write-ScreenInfo -Message . -NoNewLine
                Start-Sleep -Seconds 15
            } while (Test-Path -Path $labDiskDeploymentInProgressPath)
        }
        Write-ScreenInfo 'done'

        #refresh the list of drives with enough space for placement of VMs
        $drives.Clear()
        foreach ($drive in (Get-LabVolumesOnPhysicalDisks | Where-Object FreeSpace -ge $SpaceNeeded))
        {
            $drives.Add($drive)
        }

        if (-not $drives)
        {
            return $false
        }
    }

    Write-Debug -Message "Drive letters placed on physical drives: $($drives.DriveLetter -Join ', ')"
    foreach ($drive in $drives)
    {
        Write-Debug -Message "Drive $drive free space: $($drive.FreeSpaceGb)GB)"
    }

    #Measure speed on drives found
    Write-PSFMessage -Message 'Measuring speed on fixed drives...'

    for ($i = 0; $i -lt $drives.Count; $i++)
    {
        $drive = $drives[$i]

        if ($cachedDrives -contains $drive)
        {
            $drive = ($cachedDrives -eq $drive)[0]
            $drives[$drives.IndexOf($drive)] = $drive
            Write-PSFMessage -Message "(cached) Measurements for drive $drive (serial: $($drive.Serial)) (signature: $($drive.Signature)): Read=$([int]($drive.ReadSpeed)) MB/s  Write=$([int]($drive.WriteSpeed)) MB/s  Total=$([int]($drive.TotalSpeed)) MB/s"
        }
        else
        {
            $result = Get-DiskSpeed -DriveLetter $drive.DriveLetter
            $drive.ReadSpeed = $result.ReadRandom
            $drive.WriteSpeed = $result.WriteRandom

            Write-PSFMessage -Message "Measurements for drive $drive (serial: $($drive.Serial)) (signature: $($drive.Signature)): Read=$([int]($drive.ReadSpeed)) MB/s  Write=$([int]($drive.WriteSpeed)) MB/s  Total=$([int]($drive.TotalSpeed)) MB/s"
        }
    }

    if ($IsLinux -or $IsMacOs)
    {
        $drives.Export((Join-Path -Path (Get-LabConfigurationItem -Name LabAppDataRoot) -ChildPath 'Stores/LocalDisks.xml'))
    }
    else
    {
        $drives.ExportToRegistry('Cache', 'LocalDisks')
    }

    #creating a new list is required as otherwise $drives would be converted into an Object[]
    $drives = $drives | Sort-Object -Property TotalSpeed -Descending
    $bootDrive = $drives | Where-Object DriveLetter -eq $env:SystemDrive[0]
    if ($bootDrive)
    {
        Write-PSFMessage -Message "Boot drive is drive '$bootDrive'"
    }
    else
    {
        Write-PSFMessage -Message 'Boot drive is not part of the selected drive'
    }

    if ($drives[0] -ne $bootDrive)
    {
        #Fastest drive is not the boot drive. Selecting this drive!
        Write-PSFMessage -Message "Selecing drive $($drives[0].DriveLetter) for VMs based on speed and NOT being the boot drive"
        $script:lab.Target.Path = "$($drives[0].DriveLetter):\AutomatedLab-VMs"
    }
    else
    {
        if ($drives.Count -lt 2)
        {
            Write-PSFMessage "Selecing drive $($drives[0].DriveLetter) for VMs as it is the only one"
            $script:lab.Target.Path = "$($drives[0].DriveLetter):\AutomatedLab-VMs"
        }
        #Fastest drive is the boot drive. If speed on next fastest drive is close to the boot drive in speed (within 50%), select this drive now instead of the boot drive
        #If not, select the boot drive
        elseif (($drives[1].TotalSpeed * 100 / $drives[0].TotalSpeed) -gt 50)
        {
            Write-PSFMessage "Selecing drive $($drives[1].DriveLetter) for VMs based on speed and NOT being the boot drive"
            Write-PSFMessage "Selected disk speed compared to system disk is $(($drives[1].TotalSpeed * 100 / $drives[0].TotalSpeed))%"

            $script:lab.Target.Path = "$($drives[1].DriveLetter):\AutomatedLab-VMs"
        }
        else
        {
            Write-PSFMessage "Selecing drive $($drives[0].DriveLetter) for VMs based on speed though this drive is actually the boot drive but is much faster than second fastest drive ($($drives[1].DriveLetter))"
            Write-PSFMessage ('Selected system disk, speed of next fastest disk compared to system disk is {0:P}' -f ($drives[1].TotalSpeed / $drives[0].TotalSpeed))
            $script:lab.Target.Path = "$($drives[0].DriveLetter):\AutomatedLab-VMs"
        }
    }
}
#endregion Set-LabLocalVirtualMachineDiskAuto

#region Get-LabVirtualNetwork
function Get-LabVirtualNetwork
{
    [cmdletBinding()]

    $virtualnetworks = @()

    $switches = if ($IsLinux)
    {  
    }
    else
    {
        Get-VMSwitch 
    }

    foreach ($switch in $switches)
    {
        $network = New-Object AutomatedLab.VirtualNetwork
        $network.Name = $switch.Name
        $network.SwitchType = $switch.SwitchType.ToString()
        $ipAddress = Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object { $_.InterfaceAlias -eq "vEthernet ($($network.Name))" -and $_.PrefixOrigin -eq 'manual' } |
        Select-Object -First 1

        if ($ipAddress)
        {
            $network.AddressSpace = "$($ipAddress.IPAddress)/$($ipAddress.PrefixLength)"
        }

        $virtualnetworks += $network
    }

    $virtualnetworks
}
#endregion Get-LabVirtualNetwork

#region Get-LabAvailableAddresseSpace
function Get-LabAvailableAddresseSpace
{
    $defaultAddressSpace = Get-LabConfigurationItem -Name DefaultAddressSpace

    if (-not $defaultAddressSpace)
    {
        Write-Error 'Could not get the PrivateData value DefaultAddressSpace. Cannot find an available address space.'
        return
    }

    $existingHyperVVirtualSwitches = Get-LabVirtualNetwork

    $networkFound = $false
    $addressSpace = [AutomatedLab.IPNetwork]$defaultAddressSpace

    if ($null -eq $reservedAddressSpaces)
    {
        $script:reservedAddressSpaces = @() 
    }

    do
    {
        $addressSpace = $addressSpace.Increment()

        $conflictingSwitch = $existingHyperVVirtualSwitches | Where-Object AddressSpace -eq $addressSpace
        if ($conflictingSwitch)
        {
            Write-PSFMessage -Message "Network '$addressSpace' is in use by existing Hyper-V virtual switch '$conflictingSwitch'"
            continue
        }

        if ($addressSpace -in $reservedAddressSpaces)
        {
            Write-PSFMessage -Message "Network '$addressSpace' has already been defined in this lab"
            continue
        }

        $localAddresses = if ($IsLinux)
        {
            (ip -4 addr) | grep -oP '(?<=inet\s)\d+(\.\d+){3}'
        }
        else
        {
            (Get-NetIPAddress -AddressFamily IPv4).IPAddress
        }

        if ($addressSpace.IpAddress -in $localAddresses)
        {
            Write-PSFMessage -Message "Network '$addressSpace' is in use locally"
            continue
        }

        $route = if ($IsLinux)
        {
            (route | Select-Object -First 5 -Skip 2 | ForEach-Object { '{0}/{1}' -f ($_ -split '\s+')[0], (ConvertTo-MaskLength ($_ -split '\s+')[2]) })
        }
        else
        {
            Get-NetRoute -DestinationPrefix $addressSpace.ToString() -ErrorAction SilentlyContinue
        }

        if ($null -ne $route)
        {
            Write-PSFMessage -Message "Network '$addressSpace' is routable"
            continue
        }

        $networkFound = $true
    }
    until ($networkFound)

    $script:reservedAddressSpaces += $addressSpace
    $addressSpace
}
#endregion Get-LabAvailableAddresseSpace

#region Internal
function Repair-LabDuplicateIpAddresses
{
    [CmdletBinding()]
    param ( )

    foreach ($machine in (Get-LabMachineDefinition))
    {
        foreach ($adapter in $machine.NetworkAdapters)
        {
            foreach ($ipAddress in $adapter.Ipv4Address | Where-Object { $_.IPAddress.IsAutoGenerated })
            {
                $currentIp = $ipAddress
                $otherIps = (Get-LabMachineDefinition | Where-Object Name -ne $machine.Name).NetworkAdapters.IPV4Address

                while ($ipAddress.IpAddress -in $otherIps.IpAddress)
                {
                    $ipAddress.IpAddress = $ipAddress.IpAddress.Increment()
                }

                $adapter.Ipv4Address.Remove($currentIp) | Out-Null
                $adapter.Ipv4Address.Add($ipAddress)
            }
        }
    }
}

function Set-LinuxPackage
{
    param
    (
        [string[]]
        $Package,

        [ValidateSet('RedHat', 'Suse')]
        [string]
        $LinuxType
    )

    if ($LinuxType -eq 'RedHat')
    {
        foreach ($entry in $Package)
        {
            [void] ($script:RedHatPackage.Add($entry))
        }
        return
    }

    foreach ($entry in $Package)
    {
        [void] ($script:SusePackage.Add($entry))
    }
}

function Get-OnlineAdapterHardwareAddress
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Special handling for Linux")]
    [OutputType([string[]])]
    [CmdletBinding()]
    param ( )

    if ($IsLinux)
    {
        ip link show up | ForEach-Object { if ($_ -match '(\w{2}:?){6}' -and $Matches.0 -ne '00:00:00:00:00:00')
            {
                $Matches.0
            }
        }
    }
    else
    {
        Get-CimInstance Win32_NetworkAdapter | Where-Object { $_.NetEnabled -and $_.NetConnectionID } | Select-Object -ExpandProperty MacAddress
    }
}
#endregion Internal
