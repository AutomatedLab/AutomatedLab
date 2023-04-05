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
        <JoinWorkgroup >NET</JoinWorkgroup>
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
        <SynchronousCommand wcm:action="add">
            <Description>Configure WinRM settings</Description>
            <Order>6</Order>
            <CommandLine>PowerShell -File C:\WinRmCustomization.ps1</CommandLine>
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
        <JoinWorkgroup >NET</JoinWorkgroup>
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
        <SynchronousCommand wcm:action="add">
            <Description>Configure WinRM settings</Description>
            <Order>8</Order>
            <CommandLine>PowerShell -File C:\WinRmCustomization.ps1</CommandLine>
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
text --non-interactive
firstboot --disable
reboot
eula --agreed
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
<net-udev config:type="list">
</net-udev>
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

$cloudInitContent = @'
version: v1
network:
  network:
    version: 2
storage:
  layout:
    name: lvm
apt:
  primary:
    - arches: [amd64]
      uri: http://us.archive.ubuntu.com/ubuntu
  security:
    - arches: [amd64]
      uri: http://us.archive.ubuntu.com/ubuntu
  sources_list: |
    deb [arch=amd64] $PRIMARY $RELEASE main universe restricted multiverse
    deb [arch=amd64] $PRIMARY $RELEASE-updates main universe restricted multiverse
    deb [arch=amd64] $SECURITY $RELEASE-security main universe restricted multiverse
    deb [arch=amd64] $PRIMARY $RELEASE-backports main universe restricted multiverse
  sources:
    microsoft-powershell.list:
      source: 'deb [arch=amd64,armhf,arm64 signed-by=BC528686B50D79E339D3721CEB3E94ADBE1229CF] https://packages.microsoft.com/ubuntu/REPLACERELEASE/prod $RELEASE main'
      keyid: BC528686B50D79E339D3721CEB3E94ADBE1229CF # https://packages.microsoft.com/keys/microsoft.asc
packages:
  - oddjob
  - oddjob-mkhomedir
  - sssd
  - adcli
  - krb5-workstation
  - realmd
  - samba-common
  - samba-common-tools
  - authselect-compat
  - sshd
  - powershell
identity:
  username: {}
  hostname: {}
  password: {}
late-commands:
  - 'echo "Subsystem powershell /usr/bin/pwsh -sshs -NoLogo" >> /etc/ssh/sshd_config'
'@

Import-Module AutomatedLabCore

try
{
  $null = [AutomatedLab.Machine]
}
catch
{
  $moduleroot = (Get-Module -List AutomatedLabCore)[0].ModuleBAse
  if ($PSEdition -eq 'Core')
  {
    Add-Type -Path $moduleroot\lib\core\AutomatedLab.dll
  }
  else
  {
    Add-Type -Path $moduleroot\lib\full\AutomatedLab.dll
  }
}

if (-not (Test-Path "alias:Get-LabPostInstallationActivity")) { New-Alias -Name Get-LabPostInstallationActivity -Value Get-LabInstallationActivity -Description "Alias so that scripts keep working" }
if (-not (Test-Path "alias:Get-LabPreInstallationActivity")) { New-Alias -Name Get-LabPreInstallationActivity -Value Get-LabInstallationActivity -Description "Alias so that scripts keep working" }
