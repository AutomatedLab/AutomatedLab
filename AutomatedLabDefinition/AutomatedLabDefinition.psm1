#region Internals
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
    <component name="Security-Malware-Windows-Defender" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <DisableAntiSpyware>true</DisableAntiSpyware>
    </component>
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
#region Get-Type (helper function for creating generic types)
function Get-Type
{
    # .ExternalHelp AutomatedLabDefinition.Help.xml
    
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [string] $GenericType,
        
        [Parameter(Position = 1, Mandatory = $true)]
        [string[]] $T
    )
    
    $T = $T -as [type[]]
    
    try
    {
        $generic = [type]($GenericType + '`' + $T.Count)
        $generic.MakeGenericType($T)
    }
    catch [Exception]
    {
        throw New-Object -TypeName System.Exception -ArgumentList ('Cannot create generic type', $_.Exception)
    }
}
#endregion
#region Invoke-Ternary
function Invoke-Ternary 
{
    # .ExternalHelp AutomatedLabDefinition.Help.xml
    
    param
    (
        [scriptblock]
        $decider,

        [scriptblock]
        $ifTrue,

        [scriptblock]
        $ifFalse
    )

    if (&$decider)
    {
        &$ifTrue
    }
    else
    {
        &$ifFalse
    }
}
Set-Alias -Name ?? -Value Invoke-Ternary -Option AllScope -Description "Ternary Operator like '?' in C#"
#endregion
#region Get-LabVolumesOnPhysicalDisks

function Get-LabVolumesOnPhysicalDisks
{
    # .ExternalHelp AutomatedLabDefinition.Help.xml

    $physicalDisks = Get-PhysicalDisk
    $disks = Get-CimInstance -Class Win32_DiskDrive

    $labVolumes = foreach ($disk in $disks) 
    {
        $query = 'ASSOCIATORS OF {{Win32_DiskDrive.DeviceID="{0}"}} WHERE AssocClass=Win32_DiskDriveToDiskPartition' -f $disk.DeviceID.Replace('\','\\')
 
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
#endregion Internals

#region Lab Definition Functions
#region New-LabDefinition
function New-LabDefinition
{
    # .ExternalHelp AutomatedLabDefinition.Help.xml
    
    [CmdletBinding()]
    param (
        [string]$Name,
        
        [string]$Path,
        
        [string]$VmPath,
        
        [int]$ReferenceDiskSizeInGB = 50,
        
        [int]$MaxMemory = 0,
        
        [hashtable]$Notes,

        [switch]$UseAllMemory = $false,

        [switch]$UseStaticMemory = $false,

        [ValidateSet('Azure', 'HyperV')]
        [string]$DefaultVirtualizationEngine,
        
        [switch]$NoAzurePublishSettingsFile,
        
        [string]$AzureSubscriptionName
    )

    Write-LogFunctionEntry

    $hostOSVersion = [System.Version](Get-CimInstance -ClassName Win32_OperatingSystem).Version 
    if (($hostOSVersion -lt [System.Version]'6.2') -or (($hostOSVersion -ge [System.Version]'6.4') -and ($hostOSVersion -lt [System.Version]'10.0.10122')))
    {
        $osName = $((Get-CimInstance -ClassName Win32_OperatingSystem).Caption.PadRight(10))
        $osBuild = $((Get-CimInstance -ClassName Win32_OperatingSystem).Version.PadRight(11)) 
        '***************************************************************************' 
        ' THIS HOST MACHINE IS NOT RUNNING AN OS SUPPORTED BY AUTOMATEDLAB!'
        '' 
        '   Operating System detected as:'
        "     Name:  $osName"
        "     Build: $osBuild"
        '' 
        ' AutomatedLab is supported on the following virtualization platforms'
        '' 
        ' - Microsoft Azure'
        ' - Windows 10 build 10.0.10122 or newer'
        ' - Windows 8.0 Professional'
        ' - Windows 8.0 Enterprise' 
        ' - Windows 8.1 Professional'
        ' - Windows 8.1 Enterprise'
        ' - Windows 2012 Server Standard' 
        ' - Windows 2012 Server DataCenter'
        ' - Windows 2012 R2 Server Standard'
        ' - Windows 2012 R2 Server DataCenter'
        '***************************************************************************'
    }
    
    #settings for a new log

    #reset the log and its format
    $Global:AL_DeploymentStart = $null
    $Global:taskStart = @()
    $Global:indent = 0
    
    $Global:labDeploymentNoNewLine = $false

    $Script:reservedAddressSpaces = $null
    
    Write-ScreenInfo -Message 'Initialization' -TimeDelta ([timespan]0) -TimeDelta2 ([timespan]0) -TaskStart

    Write-ScreenInfo -Message "Host operating system version: '$($hostOSVersion.ToString())'"
    
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
        
        $macAddress = Get-WmiObject Win32_NetworkAdapter | 
        Where-Object { $_.NetEnabled -and $_.NetConnectionID } | 
        Where-Object { $_.MACaddress.ToString().SubString(0, 8) -notin $reservedMacAddresses } |
        Select-Object -ExpandProperty MACAddress -Unique
        
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
    $automatedLabPSDefaultParameterValues = $global:PSDefaultParameterValues.GetEnumerator() | Where-Object {(Get-Command ($_.Name).Split(':')[0]).Module -like 'Automated*'}
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
    
    if ($global:labNamePrefix) { $Name = "$global:labNamePrefix$Name" }
    
    if ($PSBoundParameters.ContainsKey('Path'))
    {
        $script:labPath = $Path
    }
    else
    {
        $script:labpath = "$([System.Environment]::GetFolderPath('MyDocuments'))\AutomatedLab-Labs\$Name"
    }
    Write-ScreenInfo -Message "Location of lab definition files will be '$($script:labpath)'"
    
    $script:defaults = $MyInvocation.MyCommand.Module.PrivateData
    
    $script:lab = New-Object AutomatedLab.Lab
    
    $script:lab.Name = $Name
    
    #Update SysInternals suite if needed
    $type = Get-Type -GenericType AutomatedLab.DictionaryXmlStore -T String, DateTime
    
    try
    {
        Write-Verbose -Message 'Get last check time of SysInternals suite'
        $timestamps = $type::ImportFromRegistry('Cache', 'Timestamps')
        $lastChecked = $timestamps.SysInternalsUpdateLastChecked
        Write-Verbose -Message "Last check was '$lastChecked'."
    }
    catch
    {
        Write-Verbose -Message 'Last check time could not be retrieved. SysInternals suite never updated'
        $lastChecked = Get-Date -Year 1601
        $timestamps = New-Object $type
    }

    if ($lastChecked)
    {
        $lastChecked = $lastChecked.AddDays(7)
    }
    
    if ((Get-Date) -gt $lastChecked)
    {
        Write-Verbose -Message 'Last check time is more then a week ago. Check web site for update.'
        
        $sysInternalsUrl = (Get-Module -Name AutomatedLab)[0].PrivateData.SysInternalsUrl
        $sysInternalsDownloadUrl = (Get-Module -Name AutomatedLab)[0].PrivateData.SysInternalsDownloadUrl
    
        try
        {
            Write-Verbose -Message 'Web page downloaded'
            $webRequest = Invoke-WebRequest -Uri $sysInternalsURL -UseBasicParsing
            $pageDownloaded = $true
        }
        catch
        {
            Write-Verbose -Message 'Web page could not be downloaded'
            Write-ScreenInfo -Message "No connection to '$sysInternalsURL'. Skipping." -Type Error
            $pageDownloaded = $false
        }
        
        if ($pageDownloaded)
        {
            $updateStart = $webRequest.Content.IndexOf('Updated')+'Updated:'.Length
            $updateFinish = $webRequest.Content.IndexOf('</p>', $updateStart)
            $updateStringFromWebPage = $webRequest.Content.Substring($updateStart, $updateFinish-$updateStart).Trim()
            
            Write-Verbose -Message "Update string from web page: '$updateStringFromWebPage'"
            
            $type = Get-Type -GenericType AutomatedLab.DictionaryXmlStore -T String, String            
            try
            {
                $versions = $type::ImportFromRegistry('Cache', 'Versions')
            }
            catch
            {
                $versions = New-Object $type
            }
            
            Write-Verbose -Message "Update string from registry: '$currentVersion'"
    
            if ($versions['SysInternals'] -ne $updateStringFromWebPage)
            {
                Write-ScreenInfo -Message 'Performing update of SysInternals suite now' -Type Warning -TaskStart
                Start-Sleep -Seconds 1
                
                #Download SysInternals suite
                $tempFolderName = "$($Env:Temp)\$([System.Guid]::NewGuid().ToString())"
                Write-Verbose -Message "Temp folder path: '$tempFolderName'"
                
                New-Item -ItemType Directory -Path $tempFolderName | Out-Null
                $filePath = "$tempFolderName\SysinternalsSUite.zip"
                Write-Verbose -Message "Temp file: '$filePath'"

                try
                {
                    Invoke-WebRequest -Uri $sysInternalsDownloadURL -UseBasicParsing -OutFile $filePath
                    $fileDownloaded = $true
                    Write-Verbose -Message "File '$sysInternalsDownloadURL' downloaded"
                }
                catch
                {
                    Write-ScreenInfo -Message "File '$sysInternalsDownloadURL' could not be downloaded. Skipping." -Type Error -TaskEnd
                    $fileDownloaded = $false
                }
                
                if ($fileDownloaded)
                {
                    Unblock-File -Path $filePath
        
                    #Extract files to Tools folder
                    if (-not (Test-Path -Path "$labSources\Tools"))
                    {
                        Write-Verbose -Message "Folder '$labSources\Tools' does not exist. Creating now."
                        New-Item -ItemType Directory -Path "$labSources\Tools" | Out-Null
                    }
                    if (-not (Test-Path -Path "$labSources\Tools\SysInternals"))
                    {
                        Write-Verbose -Message "Folder '$labSources\Tools\SysInternals' does not exist. Creating now."
                        New-Item -ItemType Directory -Path "$labSources\Tools\SysInternals" | Out-Null
                    }
                    else
                    {
                        Write-Verbose -Message "Folder '$labSources\Tools\SysInternals' exist. Removing it now and recreating it."
                        Remove-Item -Path "$labSources\Tools\SysInternals" -Recurse | Out-Null
                        New-Item -ItemType Directory -Path "$labSources\Tools\SysInternals" | Out-Null
                    }
        
                    Write-Verbose -Message 'Exteacting files'
                    $shell = New-Object -ComObject Shell.Application
                    $shell.namespace("$labSources\Tools\SysInternals").CopyHere($shell.Namespace($filePath).Items())
                    Remove-Item -Path $tempFolderName -Recurse
        
                    #Update registry
                    $versions['SysInternals'] = $updateStringFromWebPage
                    $versions.ExportToRegistry('Cache', 'Versions')

                    $timestamps['SysInternalsUpdateLastChecked'] = Get-Date
                    $timestamps.ExportToRegistry('Cache', 'Timestamps')
                    
                    Write-ScreenInfo -Message "SysInternals Suite has been updated and placed in '$labSources\Tools\SysInternals'" -Type Warning -TaskEnd
                }
            }
        }
    }
    
    while (Get-LabVirtualNetworkDefinition)
    {
        Remove-LabVirtualNetworkDefinition -Name (Get-LabVirtualNetworkDefinition)[0].Name
    }
    
    $machineDefinitionFilePath = Join-Path -Path $script:labPath -ChildPath $defaults.MachineFileName
    $machineDefinitionFile = New-Object AutomatedLab.MachineDefinitionFile
    $machineDefinitionFile.Path = $machineDefinitionFilePath
    $script:lab.MachineDefinitionFiles.Add($machineDefinitionFile)
    
    $diskDefinitionFilePath = Join-Path -Path $script:labPath -ChildPath $defaults.DiskFileName
    $diskDefinitionFile = New-Object AutomatedLab.DiskDefinitionFile
    $diskDefinitionFile.Path = $diskDefinitionFilePath
    $script:lab.DiskDefinitionFiles.Add($diskDefinitionFile)
    
    Write-ScreenInfo -Message "Location of LabSources folder is '($labSources)'"
    
    if (-not (Get-LabIsoImageDefinition) -and $DefaultVirtualizationEngine -ne 'Azure')
    {
        if (Get-ChildItem -Path "$(Get-LabSourcesLocation)\ISOs" -Filter *.iso -Recurse)
        {
            Write-ScreenInfo -Message 'Auto-adding ISO files' -TaskStart
            Add-LabIsoImageDefinition -Path "$(Get-LabSourcesLocation)\ISOs"
            Write-ScreenInfo -Message 'Done' -TaskEnd
        }
        else
        {
            Write-ScreenInfo -Message "No ISO files found in $(Get-LabSourcesLocation)\ISOs folder. If using Hyper-V for lab machines, please add ISO files manually using 'Add-LabIsoImageDefinition'" -Type Warning
        }
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
    
    Write-LogFunctionExit
}
#endregion New-LabDefinition

#region Get-LabDefinition
function Get-LabDefinition
{
    # .ExternalHelp AutomatedLabDefinition.Help.xml
    
    [CmdletBinding()]
    [OutputType([AutomatedLab.Lab])]
    param ()
    
    Write-LogFunctionEntry
    
    return $script:lab
    
    Write-LogFunctionExit
}
#endregion Get-LabDefinition

#region Export-LabDefinition
function Export-LabDefinition
{
    # .ExternalHelp AutomatedLabDefinition.Help.xml
    
    [CmdletBinding()]
    param (
        [switch]$Force,
                         
        [switch]$ExportDefaultUnattendedXml = $true
    )
            
    Write-LogFunctionEntry
            
    if (Get-LabMachineDefinition | Where-Object HostType -eq 'HyperV')
    {
        $osesCount = (Get-LabAvailableOperatingSystem).Count
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
                $dnsServerName = (Get-LabMachineDefinition | Where-Object {$_.IpV4Address -eq $dnsServerIP}).Name
                Write-ScreenInfo -Message "No DNS server was defined for Azure virtual network while AD is being deployed. Setting DNS server to IP address of '$dnsServerName'" -Type Warning
            }
        }
    }
    
    #Automatic DNS (client) configuration of machines
    $firstRootDc = Get-LabMachineDefinition -Role RootDC | Select-Object -First 1
    $firstRouter = Get-LabMachineDefinition -Role Routing | Select-Object -First 1
    $firstRouterExternalSwitch = $firstRouter.NetworkAdapters | Where-Object { $_.VirtualSwitch.SwitchType -eq 'External' }
    
    if ($firstRootDc -or $firstRouter)
    {
        foreach ($machine in (Get-LabMachineDefinition | Where-Object HostType -ne Azure))
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
                        Write-Verbose "Looking for a root DC in the machine's domain '$($machine.DomainName)'"
                        $rootDc = Get-LabMachineDefinition -Role RootDC | Where-Object DomainName -eq $machine.DomainName
                        if ($rootDc)
                        {
                            Write-Verbose "RootDC found, using the IP address of '$rootDc' for DNS: "
                            $networkAdapter.IPv4DnsServers = $rootDc.NetworkAdapters[0].Ipv4Address[0].IpAddress
                        }
                        else
                        {
                            Write-Verbose "No RootDC found, looking for FirstChildDC in the machine's domain"
                            $firstChildDC = Get-LabMachineDefinition -Role FirstChildDC | Where-Object DomainName -eq $machine.DomainName
                        
                            if ($firstChildDC)
                            {
                                $networkAdapter.IPv4DnsServers = $firstChildDC.NetworkAdapters[0].Ipv4Address[0].IpAddress
                            }
                            else
                            {
                                Write-Warning "Automatic assignment of DNS server did not work for machine '$machine'. No domain controller could be found for domain '$($machine.DomainName)'"
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
        $hypervUsedOperatingSystems = Get-LabAvailableOperatingSystem | Where-Object OperatingSystemImageName -in $hypervMachines.OperatingSystem.OperatingSystemName

        $spaceNeededBaseDisks = ($hypervUsedOperatingSystems | Measure-Object -Property Size -Sum).Sum
        $spaceBaseDisksAlreadyClaimed = ($hypervUsedOperatingSystems | Measure-Object -Property size -Sum).Sum
        $spaceNeededData = ($hypervMachines | Where-Object { -not (Get-VM -Name $_.Name -ErrorAction SilentlyContinue) }).Count * 2GB
        
        $spaceNeeded = $spaceNeededBaseDisks + $spaceNeededData - $spaceBaseDisksAlreadyClaimed
        
        Write-Verbose -Message "Space needed by HyperV base disks:                     $([int]($spaceNeededBaseDisks / 1GB))"
        Write-Verbose -Message "Space needed by HyperV base disks but already claimed: $([int]($spaceBaseDisksAlreadyClaimed / 1GB * -1))"
        Write-Verbose -Message "Space estimated for HyperV data:                       $([int]($spaceNeededData / 1GB))"
        Write-ScreenInfo -Message "Estimated (additional) local drive space needed for all machines: $([System.Math]::Round(($spaceNeeded / 1GB),2)) GB" -Type Info
        
        $labTargetPath = (Get-LabDefinition).Target.Path
        if ($labTargetPath)
        {
            $freeSpace = (Get-PSDrive -Name $labTargetPath[0]).Free
            if ($freeSpace -lt $spaceNeeded)
            {
                Throw "VmPath parameter is specified for the lab and contains: '$labTargetPath'. However, estimated needed space be $([int]($spaceNeeded / 1GB))GB but drive has only $([System.Math]::Round($freeSpace / 1GB)) GB of free space"
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
        Write-ScreenInfo -Message "Location of Hyper-V machines will be '$labTargetPath'"
        
        if (-not (Test-Path -Path $labTargetPath))
        {
            New-Item -ItemType Directory -Path $labTargetPath | Out-Null
        }

    }
    
    
    $lab.LabFilePath = Join-Path -Path $script:labPath -ChildPath $script:defaults.LabFileName
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
            Write-Warning 'There are no machines defined, nothing to export'
            return
        }
            
        if ($Script:machines.OperatingSystem | Where-Object Version -lt '6.2')
        {
            $unattendedXmlDefaultContent2008 | Out-File -FilePath (Join-Path -Path $script:lab.Sources.UnattendedXml.Value -ChildPath Unattended2008.xml) -Encoding unicode
        }
        if ($Script:machines.OperatingSystem | Where-Object Version -ge '6.2')
        {
            $unattendedXmlDefaultContent2012 | Out-File -FilePath (Join-Path -Path $script:lab.Sources.UnattendedXml.Value -ChildPath Unattended2012.xml) -Encoding unicode
        }
    }
            
    $Global:labExported = $true
    
    Write-LogFunctionExit
}
#endregion Export-LabDefinition

#region Test-LabDefinition
function Test-LabDefinition
{
    # .ExternalHelp AutomatedLabDefinition.Help.xml
    
    [CmdletBinding()]
    param (
        [string]$Path,
        
        [switch]$Quiet
    )
    
    Write-LogFunctionEntry

    $script:defaults = $MyInvocation.MyCommand.Module.PrivateData

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
        $Path = Join-Path -Path $lab.LabPath -ChildPath $script:defaults.LabFileName
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
    
    Write-Verbose "There are $($machineDefinitionFiles.Count) machine XML file referenced in the lab xml file"
    foreach ($machineDefinitionFile in $machineDefinitionFiles)
    {
        if (-not (Test-Path -Path $machineDefinitionFile))
        {
            throw 'Error importing the machines. Verify the paths in the section <MachineDefinitionFiles> of the lab definition XML file.'
        }
    }
    
    $Script:ValidationPass = $true
    
    Write-Verbose 'Starting validation against all xml files'
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
                    Write-Warning "Could not invoke validator $t"
                }
            }
        }    
        
        $summaryMessageContainer.AddSummary()
    }
    catch
    {
        throw $_
    }
    
    Write-Verbose -Message "Lab Validation complete, overvall runtime was $($summaryMessageContainer.Runtime)"
    
    $messages = $summaryMessageContainer | ForEach-Object { $_.GetFilteredMessages('All') }
    if (-not $Quiet)
    {
        Write-ScreenInfo ($messages | Where-Object { $_.Type -band [AutomatedLab.MessageType]::Default } | Out-String)

        if ($VerbosePreference -eq 'Continue')
        {
            Write-Verbose ($messages | Where-Object { $_.Type -band [AutomatedLab.MessageType]::VerboseDebug } | Out-String)
        }
    }
    else
    {
        if ($messages | Where-Object { $_.Type -band [AutomatedLab.MessageType]::Warning })
        {
            $messages | Where-Object { $_.Type -band [AutomatedLab.MessageType]::Warning } | ForEach-Object `
            {
                Write-Screeninfo -Message "Issue: '$($_.TargetObject)'. Cause: $($_.Message)" -Type Warning
            }
        }
        
        if ($messages | Where-Object { $_.Type -band [AutomatedLab.MessageType]::Error })
        {
            $messages | Where-Object { $_.Type -band [AutomatedLab.MessageType]::Error } | ForEach-Object `
            {
                Write-Screeninfo -Message "Issue: '$($_.TargetObject)'. Cause: $($_.Message)" -Type Error
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
    # .ExternalHelp AutomatedLabDefinition.Help.xml
    
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
    Write-Verbose "Added domain '$Name'. Lab now has $($Script:lab.Domains.Count) domain(s) defined"
    
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
    # .ExternalHelp AutomatedLabDefinition.Help.xml
    
    Write-LogFunctionEntry
    
    return $script:lab.Domains
    
    Write-LogFunctionExit
}
#endregion Get-LabDomainDefinition

#region Remove-LabDomainDefinition
function Remove-LabDomainDefinition
{
    # .ExternalHelp AutomatedLabDefinition.Help.xml
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Name
    )
    
    Write-LogFunctionEntry
    
    $domain = $script:lab.Domains | Where-Object { $_.Name -eq $Name }
    
    if (-not $domain)
    {
        Write-Warning "There is no domain defined with the name '$Name'"
    }
    else
    {
        [Void]$script:lab.Domains.Remove($domain)
        Write-Verbose "Domain '$Name' removed. Lab has $($Script:lab.Domains.Count) domain(s) defined"
    }
    
    Write-LogFunctionExit
}
#endregion Remove-LabDomainDefinition
#endregion Domain Definition Functions

#region Iso Image Definition Functions
#region Add-LabIsoImageDefinition
function Add-LabIsoImageDefinition
{
    # .ExternalHelp AutomatedLabDefinition.Help.xml
    
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
        Write-Warning -Message 'The -IsOperatingSystem switch parameter is obsolete and thereby ignored'
    }
    
    if (-not $script:lab)
    {
        throw 'Please create a lab before using this cmdlet. To create a new lab, call New-LabDefinition'
    }
    
    
    $type = Get-Type -GenericType AutomatedLab.ListXmlStore -T AutomatedLab.IsoImage
    #read the cache
    try
    {
        $importMethodInfo = $type.GetMethod('ImportFromRegistry', [System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Static)
        $cachedIsos = $importMethodInfo.Invoke($null, ('Cache', 'LocalIsoImages'))
        Write-Verbose "Read $($cachedIsos.Count) ISO images from the cache"
    }
    catch
    {
        Write-Verbose 'Could not read ISO images info from the cache'
        $cachedIsos = New-Object $type
    }

    if (Test-LabPathIsOnLabAzureLabSourcesStorage $Path)
    {
        $isoFiles = Get-LabAzureLabSourcesContent -RegexFilter '\.iso' -File -ErrorAction SilentlyContinue
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
            Write-Verbose "The ISO '$($iso.Path)' with a size '$($iso.Size)' is already in the cache."
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
                Write-Verbose "The ISO '$($iso.Path)' with a size '$($iso.Size)' is not in the cache. Reading the operating systems from ISO."
                Mount-DiskImage -ImagePath $isoFile.FullName -StorageType ISO
                Get-PSDrive | Out-Null #This is just to refresh the drives. Somehow if this cmdlet is not called, PowerShell does not see the new drives.
                $letter = (Get-DiskImage -ImagePath $isoFile.FullName | Get-Volume).DriveLetter
                $isOperatingSystem = (Test-Path "$letter`:\Sources\Install.wim")
                DisMount-DiskImage -ImagePath $isoFile.FullName
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
                            Write-Warning "The operating system '$($os.OperatingSystemName)' with version '$($os.Version)' is already added to the lab. If this is an issue with cached information, use Clear-LabCache to solve the issue."
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
        ForEach-Object { Write-Warning "The operating system $($_.OperatingSystemName) version $($_.Version) defined more than once in '$($iso.Path)'" }
    }

    $cachedIsos.ExportToRegistry('Cache', 'LocalIsoImages')
    
    foreach ($iso in $isos)
    {
        $isosToRemove = $script:lab.Sources.ISOs | Where-Object { $_.Name -eq $iso.Name -or $_.Path -eq $iso.Path }
        foreach ($isoToRemove in $isosToRemove)
        {
            $script:lab.Sources.ISOs.Remove($isoToRemove) | Out-Null
        }

        #$script:lab.Sources.ISOs.Remove($iso) | Out-Null
        $script:lab.Sources.ISOs.Add($iso)
        if (-not $NoDisplay)
        {
            Write-ScreenInfo -Message "Added '$($iso.Path)'"
        }
    }
    Write-Verbose "Final Lab ISO count: $($script:lab.Sources.ISOs.Count)"
    
    Write-LogFunctionExit
}
#endregion Add-LabIsoImageDefinition

#region Get-LabIsoImageDefinition
function Get-LabIsoImageDefinition
{
    # .ExternalHelp AutomatedLabDefinition.Help.xml
    
    Write-LogFunctionEntry
    
    $script:lab.Sources.ISOs
    
    Write-LogFunctionExit
}
#endregion Get-LabIsoImageDefinition

#region Remove-LabIsoImageDefinition
function Remove-LabIsoImageDefinition
{
    # .ExternalHelp AutomatedLabDefinition.Help.xml
    
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
        Write-Warning "There is no Iso Image defined with the name '$Name'"
    }
    else
    {
        [Void]$script:lab.Sources.ISOs.Remove($iso)
        Write-Verbose "Iso Image '$Name' removed. Lab has $($Script:lab.Sources.ISOs.Count) Iso Image(s) defined"
    }
    
    Write-LogFunctionExit
}
#endregion Remove-LabIsoImageDefinition
#endregion Iso Image Definition Functions

#region Machine Definition Functions
#region Add-LabDiskDefinition
function Add-LabDiskDefinition
{
    # .ExternalHelp AutomatedLabDefinition.Help.xml
    
    [CmdletBinding()]
    [OutputType([AutomatedLab.Disk])]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateScript({
                    $doesAlreadyExist = Test-Path -Path $_
                    if ($doesAlreadyExist)
                    {
                        Write-Warning 'The disk does already exist'
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
        [ValidateRange(20, 1024)]
        [ValidateNotNullOrEmpty()]
        [int]$DiskSizeInGb = 60,

		[switch]$SkipInitialize,
        
        [switch]$PassThru
    )
    
    Write-LogFunctionEntry
    
    if ($script:disks -eq $null)
    {
        $errorMessage = "Create a new lab first using 'New-LabDefinition' before adding disks"
        Write-Error $errorMessage
        Write-LogFunctionExitWithError -Message $errorMessage
        return
    }
    
    if ($Name)
    {
        if ($script:disks | Where-Object { $_.Name -eq $Name }
        )
        {
            $errorMessage = "A disk with the name '$Path ' does already exist"
            Write-Error $errorMessage
            Write-LogFunctionExitWithError -Message $errorMessage
            return
        }
    }
    
    $disk = New-Object -TypeName AutomatedLab.Disk
    $disk.Name = $Name
    $disk.DiskSize = $DiskSizeInGb	
	$disk.SkipInitialization = [bool]$SkipInitialize
	
    
    $script:disks.Add($disk)
    
    Write-Verbose "Added disk '$Name' with path '$Path'. Lab now has $($Script:disks.Count) disk(s) defined"
    
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
    # .ExternalHelp AutomatedLabDefinition.Help.xml
    
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
        
        [ValidatePattern('^([a-zA-Z0-9-_]){2,15}$')]
        [string[]]$DiskName,
        
        [ValidateSet(
                'Windows 7 PROFESSIONAL', 'Windows 7 ULTIMATE', 'Windows 7 Enterprise',
                'Windows 8 Pro', 'Windows 8 Enterprise',
                'Windows 8.1 Pro', 'Windows 8.1 Enterprise',
                'Windows 10 Pro', 'Windows 10 Enterprise', 'Windows 10 Enterprise 2015 LTSB','Windows 10 Enterprise 2016 LTSB', 'Windows 10 Pro Technical Preview', 'Windows 10 Enterprise Technical Preview',
                'Windows Server 2008 R2 SERVERDATACENTER', 'Windows Server 2008 R2 SERVERDATACENTERCORE', 'Windows Server 2008 R2 SERVERENTERPRISE', 'Windows Server 2008 R2 SERVERENTERPRISECORE', 'Windows Server 2008 R2 SERVERSTANDARD', 'Windows Server 2008 R2 SERVERSTANDARDCORE', 'Windows Server 2008 R2 SERVERWEB', 'Windows Server 2008 R2 SERVERWEBCORE',
                'Windows Server 2012 SERVERDATACENTER', 'Windows Server 2012 SERVERDATACENTERCORE', 'Windows Server 2012 SERVERSTANDARD', 'Windows Server 2012 SERVERSTANDARDCORE',
                'Windows Server 2012 R2 SERVERDATACENTER', 'Windows Server 2012 R2 SERVERDATACENTERCORE', 'Windows Server 2012 R2 SERVERSTANDARD', 'Windows Server 2012 R2 SERVERSTANDARDCORE',
                'Windows Server 2016 Technical Preview 4 SERVERSTANDARDCORE', 'Windows Server 2016 Technical Preview 4 SERVERSTANDARD', 'Windows Server 2016 Technical Preview 4 SERVERDATACENTERCORE', 'Windows Server 2016 Technical Preview 4 SERVERDATACENTER',
                'Windows Server 2016 Technical Preview 5 SERVERSTANDARDCORE', 'Windows Server 2016 Technical Preview 5 SERVERSTANDARD', 'Windows Server 2016 Technical Preview 5 SERVERDATACENTERCORE', 'Windows Server 2016 Technical Preview 5 SERVERDATACENTER',
                'Windows Server 2016 SERVERDATACENTER', 'Windows Server 2016 SERVERDATACENTERCORE', 'Windows Server 2016 SERVERSTANDARD', 'Windows Server 2016 SERVERSTANDARDCORE',
                'Windows Server 2016 SERVERSTANDARDNANO', 'Windows Server 2016 SERVERDATACENTERNANO'
                
        )]
        [Alias('OS')]
        [AutomatedLab.OperatingSystem]$OperatingSystem = (Get-LabDefinition).DefaultOperatingSystem,
        
        [string]$OperatingSystemVersion,
        
        [Parameter(ParameterSetName = 'Network')]
        [ValidatePattern('^([a-zA-Z0-9])|([ ]){2,244}$')]
        [string]$Network,

        [Parameter(ParameterSetName = 'Network')]
        [ValidatePattern('^(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9])[.]){3}(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9]))(\/[1-3]?[1-9])?$')]
        [string]$IpAddress,

        [Parameter(ParameterSetName = 'Network')]
        [ValidatePattern('^(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9])[.]){3}(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9]))(\/[1-3]?[1-9])?$')]
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
        
        [string]$ProductKey,
        
        #Created ValidateSet using: "'" + ([System.Globalization.CultureInfo]::GetCultures([System.Globalization.CultureTypes]::InstalledWin32Cultures).Name -join "', '") + "'" | clip
        [ValidateSet('af', 'af-ZA', 'am', 'am-ET', 'ar', 'ar-AE', 'ar-BH', 'ar-DZ', 'ar-EG', 'ar-IQ', 'ar-JO', 'ar-KW', 'ar-LB', 'ar-LY', 'ar-MA', 'ar-OM', 'ar-QA', 'ar-SA', 'ar-SY', 'ar-TN', 'ar-YE', 'arn', 'arn-CL', 'as', 'as-IN', 'az', 'az-Cyrl', 'az-Cyrl-AZ', 'az-Latn', 'az-Latn-AZ', 'ba', 'ba-RU', 'be', 'be-BY', 'bg', 'bg-BG', 'bn', 'bn-BD', 'bn-IN', 'bo', 'bo-CN', 'br', 'br-FR', 'bs', 'bs-Cyrl', 'bs-Cyrl-BA', 'bs-Latn', 'bs-Latn-BA', 'ca', 'ca-ES', 'ca-ES-valencia', 'chr', 'chr-Cher', 'chr-Cher-US', 'co', 'co-FR', 'cs', 'cs-CZ', 'cy', 'cy-GB', 'da', 'da-DK', 'de', 'de-AT', 'de-CH', 'de-DE', 'de-LI', 'de-LU', 'dsb', 'dsb-DE', 'dv', 'dv-MV', 'el', 'el-GR', 'en', 'en-029', 'en-AU', 'en-BZ', 'en-CA', 'en-GB', 'en-HK', 'en-IE', 'en-IN', 'en-JM', 'en-MY', 'en-NZ', 'en-PH', 'en-SG', 'en-TT', 'en-US', 'en-ZA', 'en-ZW', 'es', 'es-419', 'es-AR', 'es-BO', 'es-CL', 'es-CO', 'es-CR', 'es-DO', 'es-EC', 'es-ES', 'es-GT', 'es-HN', 'es-MX', 'es-NI', 'es-PA', 'es-PE', 'es-PR', 'es-PY', 'es-SV', 'es-US', 'es-UY', 'es-VE', 'et', 'et-EE', 'eu', 'eu-ES', 'fa', 'fa-IR', 'ff', 'ff-Latn', 'ff-Latn-SN', 'fi', 'fi-FI', 'fil', 'fil-PH', 'fo', 'fo-FO', 'fr', 'fr-BE', 'fr-CA', 'fr-CD', 'fr-CH', 'fr-CI', 'fr-CM', 'fr-FR', 'fr-HT', 'fr-LU', 'fr-MA', 'fr-MC', 'fr-ML', 'fr-RE', 'fr-SN', 'fy', 'fy-NL', 'ga', 'ga-IE', 'gd', 'gd-GB', 'gl', 'gl-ES', 'gn', 'gn-PY', 'gsw', 'gsw-FR', 'gu', 'gu-IN', 'ha', 'ha-Latn', 'ha-Latn-NG', 'haw', 'haw-US', 'he', 'he-IL', 'hi', 'hi-IN', 'hr', 'hr-BA', 'hr-HR', 'hsb', 'hsb-DE', 'hu', 'hu-HU', 'hy', 'hy-AM', 'id', 'id-ID', 'ig', 'ig-NG', 'ii', 'ii-CN', 'is', 'is-IS', 'it', 'it-CH', 'it-IT', 'iu', 'iu-Cans', 'iu-Cans-CA', 'iu-Latn', 'iu-Latn-CA', 'ja', 'ja-JP', 'ka', 'ka-GE', 'kk', 'kk-KZ', 'kl', 'kl-GL', 'km', 'km-KH', 'kn', 'kn-IN', 'ko', 'ko-KR', 'kok', 'kok-IN', 'ku', 'ku-Arab', 'ku-Arab-IQ', 'ky', 'ky-KG', 'lb', 'lb-LU', 'lo', 'lo-LA', 'lt', 'lt-LT', 'lv', 'lv-LV', 'mi', 'mi-NZ', 'mk', 'mk-MK', 'ml', 'ml-IN', 'mn', 'mn-Cyrl', 'mn-MN', 'mn-Mong', 'mn-Mong-CN', 'mn-Mong-MN', 'moh', 'moh-CA', 'mr', 'mr-IN', 'ms', 'ms-BN', 'ms-MY', 'mt', 'mt-MT', 'my', 'my-MM', 'nb', 'nb-NO', 'ne', 'ne-IN', 'ne-NP', 'nl', 'nl-BE', 'nl-NL', 'nn', 'nn-NO', 'no', 'nso', 'nso-ZA', 'oc', 'oc-FR', 'om', 'om-ET', 'or', 'or-IN', 'pa', 'pa-Arab', 'pa-Arab-PK', 'pa-IN', 'pl', 'pl-PL', 'prs', 'prs-AF', 'ps', 'ps-AF', 'pt', 'pt-BR', 'pt-PT', 'qut', 'qut-GT', 'quz', 'quz-BO', 'quz-EC', 'quz-PE', 'rm', 'rm-CH', 'ro', 'ro-MD', 'ro-RO', 'ru', 'ru-RU', 'rw', 'rw-RW', 'sa', 'sa-IN', 'sah', 'sah-RU', 'sd', 'sd-Arab', 'sd-Arab-PK', 'se', 'se-FI', 'se-NO', 'se-SE', 'si', 'si-LK', 'sk', 'sk-SK', 'sl', 'sl-SI', 'sma', 'sma-NO', 'sma-SE', 'smj', 'smj-NO', 'smj-SE', 'smn', 'smn-FI', 'sms', 'sms-FI', 'so', 'so-SO', 'sq', 'sq-AL', 'sr', 'sr-Cyrl', 'sr-Cyrl-BA', 'sr-Cyrl-CS', 'sr-Cyrl-ME', 'sr-Cyrl-RS', 'sr-Latn', 'sr-Latn-BA', 'sr-Latn-CS', 'sr-Latn-ME', 'sr-Latn-RS', 'st', 'st-ZA', 'sv', 'sv-FI', 'sv-SE', 'sw', 'sw-KE', 'syr', 'syr-SY', 'ta', 'ta-IN', 'ta-LK', 'te', 'te-IN', 'tg', 'tg-Cyrl', 'tg-Cyrl-TJ', 'th', 'th-TH', 'ti', 'ti-ER', 'ti-ET', 'tk', 'tk-TM', 'tn', 'tn-BW', 'tn-ZA', 'tr', 'tr-TR', 'ts', 'ts-ZA', 'tt', 'tt-RU', 'tzm', 'tzm-Latn', 'tzm-Latn-DZ', 'tzm-Tfng', 'tzm-Tfng-MA', 'ug', 'ug-CN', 'uk', 'uk-UA', 'ur', 'ur-IN', 'ur-PK', 'uz', 'uz-Cyrl', 'uz-Cyrl-UZ', 'uz-Latn', 'uz-Latn-UZ', 'vi', 'vi-VN', 'wo', 'wo-SN', 'xh', 'xh-ZA', 'yo', 'yo-NG', 'zh', 'zh-CN', 'zh-Hans', 'zh-Hant', 'zh-HK', 'zh-MO', 'zh-SG', 'zh-TW', 'zu', 'zu-ZA')]
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

        [string]$FriendlyName
    )
DynamicParam {
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        $ParameterName = 'AzureRoleSize'        
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $AttributeCollection.Add($ParameterAttribute)
        $defaultLocation = (Get-LabAzureDefaultLocation -ErrorAction SilentlyContinue).Location
        if($defaultLocation)
        {
            $vmSizes = Get-AzureRMVmSize -Location $defaultLocation -ErrorAction SilentlyContinue | Sort-Object -Property Name
            $arrSet = $vmSizes | %{"$($_.Name) ($($_.NumberOfCores) Cores, $($_.MemoryInMB) Mb, $($_.MaxDataDiskCount) max data disks)"}
            $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)
            $AttributeCollection.Add($ValidateSetAttribute)
        }
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)

        $ParameterName = 'TimeZone'        
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $AttributeCollection.Add($ParameterAttribute)
        $arrSet = ([System.TimeZoneInfo]::GetSystemTimeZones().Id | Sort-Object)
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)
        $AttributeCollection.Add($ValidateSetAttribute)
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)

        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
        return $RuntimeParameterDictionary
}

begin
{    
    Write-LogFunctionEntry
    $AzureRoleSize = $PsBoundParameters['AzureRoleSize']
    $TimeZone = $PsBoundParameters['TimeZone']
}

process
{
    $machineRoles = ''
    if ($Roles) { $machineRoles = " (Roles: $($Roles.Name -join ', '))" }
    
    $azurePropertiesValidKeys = 'ResourceGroupName', 'UseAllRoleSizes', 'RoleSize', 'LoadBalancerRdpPort', 'LoadBalancerWinRmHttpPort', 'LoadBalancerWinRmHttpsPort'
    
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
        throw "No operating system was defined for machine '$Name' and no default operating system defined. Please define either of these and retry. Call 'Get-LabAvailableOperatingSystem' to get a list of operating systems added to the lab."
    }

    if ($AzureProperties)
    {
        $illegalKeys = Compare-Object -ReferenceObject $azurePropertiesValidKeys -DifferenceObject ($AzureProperties.Keys | Select-Object -Unique) |
        Where-Object SideIndicator -eq '=>' |
        Select-Object -ExpandProperty InputObject

        if ($illegalKeys)
        {
            throw "The key(s) '$($illegalKeys -join ', ')' are not supported in AzureProperties. Valid keys are '$($azurePropertiesValidKeys -join ', ')'"
        }
    }

    if ($global:labNamePrefix) { $Name = "$global:labNamePrefix$Name" }
    
    if ($script:machines -eq $null)
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
    $script:machines.Add($machine)
    
    if ((Get-LabDefinition).DefaultVirtualizationEngine -and (-not $PSBoundParameters.ContainsKey('VirtualizationHost')))
    {
        $VirtualizationHost = (Get-LabDefinition).DefaultVirtualizationEngine
    }

    if($VirtualizationHost -eq 'Azure')
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
                'HyperV' { $installationUser = New-Object AutomatedLab.User('Administrator', 'Somepass1') }
                'Azure'  { $installationUser = New-Object AutomatedLab.User('Install', 'Somepass1') }
                Default  { $installationUser = New-Object AutomatedLab.User('Administrator', 'Somepass1') }
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
                        'Azure'  { Add-LabDomainDefinition -Name $DomainName -AdminUser Install -AdminPassword Somepass1 }
                        'HyperV' { Add-LabDomainDefinition -Name $DomainName -AdminUser Administrator -AdminPassword Somepass1 }
                        'VMware' { Add-LabDomainDefinition -Name $DomainName -AdminUser Administrator -AdminPassword Somepass1 }
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
                
                Write-Verbose -Message "Machine contains custom properties for FirstChildDC: 'ParentDomain'='$parentDomainInProperties', 'NewDomain'='$newDomainInProperties'"
            }
            
            if ((-not $containsProperties) -and (-not $DomainName))
            {
                Write-Verbose -Message 'Nothing specified (no DomainName nor ANY Properties). Giving up'
                
                throw 'Domain name not specified for Child Domain Controller'
            }
            
            if ((-not $DomainName) -and ((-not $parentDomainInProperties -or (-not $newDomainInProperties))))
            {
                Write-Verbose -Message 'No DomainName or Properties for ParentName and NewDomain specified. Giving up'
                
                throw 'Domain name not specified for Child Domain Controller'
            }
            
            if ($containsProperties -and $parentDomainInProperties -and $newDomainInProperties -and (-not $DomainName))
            {
                Write-Verbose -Message 'Properties specified but DomainName is not. Then populate DomainName based on Properties'
                
                $DomainName = "$($role.Properties.NewDomain).$($role.Properties.ParentDomain)"
                Write-Verbose -Message "Machine contains custom properties for FirstChildDC but DomainName parameter is not specified. Setting now to '$DomainName'"
            }
            elseif (((-not $containsProperties) -or ($containsProperties -and (-not $parentDomainInProperties) -and (-not $newDomainInProperties))) -and $DomainName)
            {
                $newDomainName = $DomainName.Substring(0, $DomainName.IndexOf('.'))
                $parentDomainName = $DomainName.Substring($DomainName.IndexOf('.') + 1)

                Write-Verbose -Message 'No Properties specified (or properties for ParentName and NewDomain omitted) but DomainName parameter is specified. Calculating/updating ParentDomain and NewDomain properties'
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
                Write-Verbose -Message "ParentDomain now set to '$parentDomainInProperties'"
                Write-Verbose -Message "NewDomain now set to '$newDomainInProperties'"
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
    
    switch ($OperatingSystem.Version.ToString(2))
    {
        '6.0'  { $level = 'Win2008' }
        '6.1'  { $level = 'Win2008R2' }
        '6.2'  { $level = 'Win2012' }
        '6.3'  { $level = 'Win2012R2' }
        '6.4'  { $level = 'WinThreshold' }
        '10.0' { $level = 'WinThreshold' }
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
                $role.Properties = @{'ForestFunctionalLevel' = $level}
                $role.Properties.Add('DomainFunctionalLevel', $level)
            }
            elseif ($role.Name -eq 'FirstChildDC')
            {
                $role.Properties = @{'DomainFunctionalLevel' = $level}
            }
        }
    }
    
    $role = $roles | Where-Object Name -in Exchange2013, Exchange2016
    if ($role)
    {
        if ($role.Properties)
        {
            if (-not $role.Properties.ContainsKey('OrganizationName'))
            {
                $role.Properties.Add('OrganizationName', 'ExOrg')
            }
        }
        else
        {
            $role.Properties = @{ 'OrganizationName' = 'ExOrg' }
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
                $Global:existingAzureNetworks = Get-AzureRmVirtualNetwork
            }
            
            #Virtual network name will be same as lab name
            $autoNetworkName = (Get-LabDefinition).Name
            
            #Priority 1. Check for existence of an Azure virtual network with same name as network name
            $existingNetwork = $Global:existingAzureNetworks | Where-Object { $_.Name -eq $autoNetworkName }
            if ($existingNetwork)
            {
                Write-Verbose -Message 'Virtual switch already exists with same name as lab being deployed. Trying to re-use.'
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
                Write-Verbose -Message 'No Azure virtual network found with same name as network name. Attempting to find unused network in the range 192.168.2.x-192.168.255.x'
                
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
                        Write-Verbose -Message "Network '192.168.$octet.0/24' is in use by an existing Azure virtual network"
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
        Write-Verbose -Message 'Detect if a virtual switch already exists with same name as lab being deployed. If so, use this switch for defining network name and address space.'
        
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
                Write-Verbose -Message 'Virtual switch already exists with same name as lab being deployed. Trying to re-use.'
                
                Write-ScreenInfo -Message "Using virtual network '$autoNetworkName' with address space '$addressSpace'" -Type Info
                Add-LabVirtualNetworkDefinition -Name $autoNetworkName -AddressSpace $existingNetwork.AddressSpace
            }
            else
            {
                Write-Verbose -Message 'No virtual switch found with same name as network name. Attempting to find unused network'
                
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
            Write-Verbose -Message 'One or more virtual network(s) has been specified.'
            
            #Using first specified virtual network '$($networkDefinitions[0])' with address space '$($networkDefinitions[0].AddressSpace)'."
            
            <#
                    if ($script:autoIPAddress)
                    {
                    #Network already created and IP range already found
                    Write-Verbose -Message 'Network already created and IP range already found'
                    }
                    else
                    {
            #>

            foreach ($networkDefinition in $networkDefinitions)
            {
                #check for an virtuel switch having already the name of the new network switch
                $existingNetwork = $existingHyperVVirtualSwitches | Where-Object Name -eq $networkDefinition

                #does the current network definition has an address space assigned
                if ($networkDefinition.AddressSpace)
                {
                    Write-Verbose -Message "Virtual network '$networkDefinition' specified with address space '$($networkDefinition.AddressSpace)'"
                    
                    #then check if the existing network has the same address space as the new one and throw an exception if not
                    if ($existingNetwork)
                    {
                        if ($networkDefinition.AddressSpace -ne $existingNetwork.AddressSpace)
                        {
                            throw "Address space defined '$($networkDefinition.AddressSpace)' for network '$networkDefinition' is different from the address space '$($existingNetwork.AddressSpace)' used by currently existing Hyper-V switch with same name. Cannot continue."
                        }
                        
                        Write-Verbose -Message 'Existing Hyper-V virtual switch found with same name and address space as first virtual network specified. Using this.'
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
                        
                        Write-Verbose -Message 'Address space specified is valid'
                    }
                }
                else
                {
                    if ($networkDefinition.SwitchType -eq 'External')
                    {
                        Write-Verbose 'External network interfaces will not get automatic IP addresses'
                        continue
                    }

                    Write-Verbose -Message "Virtual network '$networkDefinition' specified but without address space specified"
                    
                    if ($existingNetwork)
                    {
                        Write-Verbose -Message "Existing Hyper-V virtual switch found with same name as first virtual network name. Using it with address space '$($existingNetwork.AddressSpace)'."
                        $networkDefinition.AddressSpace = $existingNetwork.AddressSpace
                    }
                    else
                    {
                        Write-Verbose -Message 'No Hyper-V virtual switch found with same name as lab name. Attempting to find unused network.'
                
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
                $adapter.Ipv4Address.Add([AutomatedLab.IPNetwork]::Parse($IpAddress, $adapterVirtualNetwork.AddressSpace.Netmask))
            }
            elseif (-not $adapter.UseDhcp)
            {
                $ip = $adapterVirtualNetwork.NextIpAddress()
                $adapter.Ipv4Address.Add([AutomatedLab.IPNetwork]::Parse($ip, $adapterVirtualNetwork.AddressSpace.Netmask))
            }
        }

        if ($DnsServer1) { $adapter.Ipv4DnsServers.Add($DnsServer1) }
        if ($DnsServer2) { $adapter.Ipv4DnsServers.Add($DnsServer2) }

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

        if ($Gateway) { $adapter.Ipv4Gateway.Add($Gateway) }

        $machine.NetworkAdapters.Add($adapter)
    }

    Repair-LabDuplicateIpAddresses
    
    if ($processors -eq 0)
    {
        $processors = 1
        if (-not $script:processors) { $script:processors = (Get-WmiObject -Namespace Root\CIMv2 -Class win32_processor).NumberOfLogicalProcessors }
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
            if ($PSCmdlet.MyInvocation.MyCommand.Module.PrivateData."MemoryWeight_$($role.Name)" -gt $machine.Memory)
            {
                $machine.Memory = $PSCmdlet.MyInvocation.MyCommand.Module.PrivateData."MemoryWeight_$($role.Name)"
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
        if ($OperatingSystemVersion)
        {
            $os = Get-LabAvailableOperatingSystem | Where-Object { $_.OperatingSystemName -eq $OperatingSystem -and $_.Version -eq $OperatingSystemVersion }
        }
        else
        {
            $os = Get-LabAvailableOperatingSystem | Where-Object OperatingSystemName -eq $OperatingSystem
            if ($os.Count -gt 1)
            {
                $os = $os | Group-Object -Property Version | Sort-Object -Property Name -Descending | Select-Object -First 1 | Select-Object -ExpandProperty Group
                Write-Warning "The operating system '$OperatingSystem' is available multiple times. Choosing the one with the highest version ($($os[0].Version))"
            }

            if ($os.Count -gt 1)
            {
                $os = $os | Sort-Object -Property { (Get-Item -Path $_.IsoPath).LastWriteTime } -Descending | Select-Object -First 1
                Write-Warning "The operating system '$OperatingSystem' with the same version is available on multiple images. Choosing the one with the highest LastWriteTime to honor updated images ($((Get-Item -Path $os.IsoPath).LastWriteTime))"
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
    
    if (-not $TimeZone)   { $TimeZone = tzutil.exe /g }
    $machine.Timezone = $TimeZone
    
    if (-not $UserLocale) { $UserLocale = (Get-Culture).Name }
    $machine.UserLocale = $UserLocale
    
    $machine.ProductKey = $ProductKey
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
    # .ExternalHelp AutomatedLabDefinition.Help.xml
    
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
    # .ExternalHelp AutomatedLabDefinition.Help.xml
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$Name
    )
    
    Write-LogFunctionEntry
    
    $machine = $script:machines | Where-Object Name -eq $Name
    
    if (-not $machine)
    {
        Write-Warning "There is no machine defined with the name '$Name'"
    }
    else
    {
        [Void]$script:machines.Remove($machine)
        Write-Verbose "Machine '$Name' removed. Lab has $($Script:machines.Count) machine(s) defined"
    }
    
    Write-LogFunctionExit
}
#endregion Remove-LabMachineDefinition

#region Get-LabMachineRoleDefinition
function Get-LabMachineRoleDefinition
{
    # .ExternalHelp AutomatedLabDefinition.Help.xml
    
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
    # .ExternalHelp AutomatedLabDefinition.Help.xml
    
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
        [switch]$KeepFolder,
        
        [Parameter(Mandatory, ParameterSetName = 'FileContentDependencyRemoteScript')]
        [Parameter(Mandatory, ParameterSetName = 'IsoImageDependencyRemoteScript')]
        [string]$ScriptFileName,
        
        [Parameter(Mandatory, ParameterSetName = 'IsoImageDependencyLocalScript')]
        [Parameter(Mandatory, ParameterSetName = 'FileContentDependencyLocalScript')]
        [string]$ScriptFilePath,
        
        [switch]$DoNotUseCredSsp
    )
    
    Write-LogFunctionEntry
    
    $activity = New-Object -TypeName AutomatedLab.PostInstallationActivity
    
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
    
    $activity.DoNotUseCredSsp = $DoNotUseCredSsp
    
    Write-LogFunctionExit -ReturnValue $activity
    return $activity
}
#endregion Get-PostInstallationActivity
#endregion Machine Definition Functions

#region Get-DiskSpeed
function Get-DiskSpeed
{
    # .ExternalHelp AutomatedLabDefinition.Help.xml
    
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
            ReadRandom = $readThroughoutRandom
            WriteRandom = $writeThroughoutRandom
    })
    
    $result

    Write-LogFunctionExit
}
#endregion

#region Set-LabLocalVirtualMachineDiskAuto
function Set-LabLocalVirtualMachineDiskAuto
{
    # .ExternalHelp AutomatedLabDefinition.Help.xml
    [cmdletBinding()]
    param
    (
        [int64]$SpaceNeeded
    )

    $type = Get-Type -GenericType AutomatedLab.ListXmlStore -T AutomatedLab.LocalDisk
    $drives = New-Object $type
    
    #Retrieve drives with enough space for placement of VMs
    foreach ($drive in (Get-LabVolumesOnPhysicalDisks | Where-Object FreeSpace -ge $SpaceNeeded))
    {
        $drives.Add($drive)
    }
    
    #read the cache
    try
    {
        $importMethodInfo = $type.GetMethod('ImportFromRegistry', [System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Static)
        $cachedDrives = $importMethodInfo.Invoke($null, ('Cache', 'LocalDisks'))
        Write-Verbose "Read $($cachedDrives.Count) drive infos from the cache"
    }
    catch
    {
        Write-Verbose 'Could not read info from the cache'
    }

    Write-Debug -Message "Drive letters placed on physical drives: $($drives.DriveLetter -Join ', ')"
    foreach ($drive in $drives)
    {
        Write-Debug -Message "Drive $drive free space: $($drive.FreeSpaceGb)GB)"
    }
        
    if (-not $drives)
    {
        return $false
    }
        
    #Measure speed on drives found
    Write-Verbose -Message 'Measuring speed on fixed drives...'
    
    for ($i = 0; $i -lt $drives.Count; $i++)
    {
        $drive = $drives[$i]

        if ($cachedDrives -contains $drive)
        {
            $drive = ($cachedDrives -eq $drive)[0]
            $drives[$drives.IndexOf($drive)] = $drive
            Write-Verbose -Message "(cached) Measurements for drive $drive (serial: $($drive.Serial)) (signature: $($drive.Signature)): Read=$([int]($drive.ReadSpeed)) MB/s  Write=$([int]($drive.WriteSpeed)) MB/s  Total=$([int]($drive.TotalSpeed)) MB/s"
        }
        else
        {
            $result = Get-DiskSpeed -DriveLetter $drive.DriveLetter
            $drive.ReadSpeed = $result.ReadRandom
            $drive.WriteSpeed = $result.WriteRandom
                    
            Write-Verbose -Message "Measurements for drive $drive (serial: $($drive.Serial)) (signature: $($drive.Signature)): Read=$([int]($drive.ReadSpeed)) MB/s  Write=$([int]($drive.WriteSpeed)) MB/s  Total=$([int]($drive.TotalSpeed)) MB/s"
        }
    }
    $drives.ExportToRegistry('Cache', 'LocalDisks')
            
    #creating a new list is required as otherwise $drives would be converted into an Object[]
    $drives = $drives | Sort-Object -Property TotalSpeed -Descending
    $bootDrive = $drives | Where-Object DriveLetter -eq $env:SystemDrive[0]
    if ($bootDrive)
    {
        Write-Verbose -Message "Boot drive is drive '$bootDrive'"
    }
    else
    {
        Write-Verbose -Message 'Boot drive is not part of the selected drive'
    }
    
    if ($drives[0] -ne $bootDrive)
    {
        #Fastest drive is not the boot drive. Selecting this drive!
        Write-Verbose -Message "Selecing drive $($drives[0].DriveLetter) for VMs based on speed and NOT being the boot drive"
        $script:lab.Target.Path = "$($drives[0].DriveLetter):\AutomatedLab-VMs"
    }
    else
    {
        if ($drives.Count -lt 2)
        {
            Write-Verbose "Selecing drive $($drives[0].DriveLetter) for VMs as it is the only one"
            $script:lab.Target.Path = "$($drives[0].DriveLetter):\AutomatedLab-VMs"
        }
        #Fastest drive is the boot drive. If speed on next fastest drive is close to the boot drive in speed (within 50%), select this drive now instead of the boot drive
        #If not, select the boot drive
        elseif ((($drives[1].TotalSpeed - $drives[0].TotalSpeed) / $drives[1].TotalSpeed * 100) -lt 50)
        {
            Write-Verbose "Selecing drive $($drives[1].DriveLetter) for VMs based on speed and NOT being the boot drive"
            $script:lab.Target.Path = "$($drives[1].DriveLetter):\AutomatedLab-VMs"
        }
        else
        {
            Write-Verbose "Selecing drive $($drives[0].DriveLetter) for VMs based on speed though this drive is actually the boot drive but is much faster than second fastest drive ($($drives[1].DriveLetter))"
            $script:lab.Target.Path = "$($drives[0].DriveLetter):\AutomatedLab-VMs"
        }
    }
}
#endregion Set-LabLocalVirtualMachineDiskAuto

#region Get-LabVirtualNetwork
function Get-LabVirtualNetwork
{
    # .ExternalHelp AutomatedLabDefinition.Help.xml
    
    [cmdletBinding()]
    
    $virtualnetworks = @()

    $switches = Get-VMSwitch

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
    # .ExternalHelp AutomatedLabDefinition.Help.xml
    $defaultAddressSpace = $PSCmdlet.MyInvocation.MyCommand.Module.PrivateData.DefaultAddressSpace
    
    if (-not $defaultAddressSpace)
    {
        Write-Error 'Could not get the PrivateData value DefaultAddressSpace. Cannot find an available address space.'
        return
    }
    
    $existingHyperVVirtualSwitches = Get-LabVirtualNetwork

    $networkFound = $false
    $addressSpace = [AutomatedLab.IPNetwork]$defaultAddressSpace

    if ($null -eq $reservedAddressSpaces) { $script:reservedAddressSpaces = @() }

    do
    {
        $addressSpace = $addressSpace.Increment()
                    
        $conflictingSwitch = $existingHyperVVirtualSwitches | Where-Object AddressSpace -eq $addressSpace
        if ($conflictingSwitch)
        {
            Write-Verbose -Message "Network '$addressSpace' is in use by existing Hyper-V virtual switch '$conflictingSwitch'"
            continue
        }

        if ($addressSpace -in $reservedAddressSpaces)
        {
            Write-Verbose -Message "Network '$addressSpace' has already been defined in this lab"
            continue
        }

        if ($addressSpace.IpAddress -in (Get-NetIPAddress -AddressFamily IPv4).IPAddress)
        {
            Write-Verbose -Message "Network '$addressSpace' is in use locally"
            continue
        }

        if (Get-NetRoute -DestinationPrefix $addressSpace.ToString() -ErrorAction SilentlyContinue)
        {
            Write-Verbose -Message "Network '$addressSpace' is routable"
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
    # .ExternalHelp AutomatedLabDefinition.Help.xml
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
#endregion Internal
