#region GPO Type
$gpoType = @'
using System;
using System.Collections.Generic;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using Microsoft.Win32;

namespace GPO
{
    /// <summary>
    /// Represent the result of group policy operations.
    /// </summary>
    public enum ResultCode
    {
        Succeed = 0,
        CreateOrOpenFailed = -1,
        SetFailed = -2,
        SaveFailed = -3
    }

    /// <summary>
    /// The WinAPI handler for GroupPlicy operations.
    /// </summary>
    public class WinAPIForGroupPolicy
    {
        // Group Policy Object open / creation flags
        const UInt32 GPO_OPEN_LOAD_REGISTRY = 0x00000001;    // Load the registry files
        const UInt32 GPO_OPEN_READ_ONLY = 0x00000002;    // Open the GPO as read only

        // Group Policy Object option flags
        const UInt32 GPO_OPTION_DISABLE_USER = 0x00000001;   // The user portion of this GPO is disabled
        const UInt32 GPO_OPTION_DISABLE_MACHINE = 0x00000002;   // The machine portion of this GPO is disabled

        const UInt32 REG_OPTION_NON_VOLATILE = 0x00000000;

        const UInt32 ERROR_MORE_DATA = 234;

        // You can find the Guid in <Gpedit.h>
        static readonly Guid REGISTRY_EXTENSION_GUID = new Guid("35378EAC-683F-11D2-A89A-00C04FBBCFA2");
        static readonly Guid CLSID_GPESnapIn = new Guid("8FC0B734-A0E1-11d1-A7D3-0000F87571E3");

        /// <summary>
        /// Group Policy Object type.
        /// </summary>
        enum GROUP_POLICY_OBJECT_TYPE
        {
            GPOTypeLocal = 0,                       // Default GPO on the local machine
            GPOTypeRemote,                          // GPO on a remote machine
            GPOTypeDS,                              // GPO in the Active Directory
            GPOTypeLocalUser,                       // User-specific GPO on the local machine
            GPOTypeLocalGroup                       // Group-specific GPO on the local machine
        }

        #region COM

        /// <summary>
        /// Group Policy Interface definition from COM.
        /// You can find the Guid in <Gpedit.h>
        /// </summary>
        [Guid("EA502723-A23D-11d1-A7D3-0000F87571E3"),
        InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
        interface IGroupPolicyObject
        {
            void New(
            [MarshalAs(UnmanagedType.LPWStr)] String pszDomainName,
            [MarshalAs(UnmanagedType.LPWStr)] String pszDisplayName,
            UInt32 dwFlags);

            void OpenDSGPO(
                [MarshalAs(UnmanagedType.LPWStr)] String pszPath,
                UInt32 dwFlags);

            void OpenLocalMachineGPO(UInt32 dwFlags);

            void OpenRemoteMachineGPO(
                [MarshalAs(UnmanagedType.LPWStr)] String pszComputerName,
                UInt32 dwFlags);

            void Save(
                [MarshalAs(UnmanagedType.Bool)] bool bMachine,
                [MarshalAs(UnmanagedType.Bool)] bool bAdd,
                [MarshalAs(UnmanagedType.LPStruct)] Guid pGuidExtension,
                [MarshalAs(UnmanagedType.LPStruct)] Guid pGuid);

            void Delete();

            void GetName(
                [MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszName,
                Int32 cchMaxLength);

            void GetDisplayName(
                [MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszName,
                Int32 cchMaxLength);

            void SetDisplayName([MarshalAs(UnmanagedType.LPWStr)] String pszName);

            void GetPath(
                [MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszPath,
                Int32 cchMaxPath);

            void GetDSPath(
                UInt32 dwSection,
                [MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszPath,
                Int32 cchMaxPath);

            void GetFileSysPath(
                UInt32 dwSection,
                [MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszPath,
                Int32 cchMaxPath);

            UInt32 GetRegistryKey(UInt32 dwSection);

            Int32 GetOptions();

            void SetOptions(UInt32 dwOptions, UInt32 dwMask);

            void GetType(out GROUP_POLICY_OBJECT_TYPE gpoType);

            void GetMachineName(
                [MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszName,
                Int32 cchMaxLength);

            UInt32 GetPropertySheetPages(out IntPtr hPages);
        }

        /// <summary>
        /// Group Policy Class definition from COM.
        /// You can find the Guid in <Gpedit.h>
        /// </summary>
        [ComImport, Guid("EA502722-A23D-11d1-A7D3-0000F87571E3")]
        class GroupPolicyObject { }

        #endregion

        #region WinAPI You can find definition of API for C# on: http://pinvoke.net/

        /// <summary>
        /// Opens the specified registry key. Note that key names are not case sensitive.
        /// </summary>
        /// See http://msdn.microsoft.com/en-us/library/ms724897(VS.85).aspx for more info about the parameters.<br/>
        [DllImport("advapi32.dll", CharSet = CharSet.Auto)]
        public static extern Int32 RegOpenKeyEx(
        UIntPtr hKey,
        String subKey,
        Int32 ulOptions,
        RegSAM samDesired,
        out UIntPtr hkResult);

        /// <summary>
        /// Retrieves the type and data for the specified value name associated with an open registry key.
        /// </summary>
        /// See http://msdn.microsoft.com/en-us/library/ms724911(VS.85).aspx for more info about the parameters and return value.<br/>
        [DllImport("advapi32.dll", CharSet = CharSet.Unicode, EntryPoint = "RegQueryValueExW", SetLastError = true)]
        static extern Int32 RegQueryValueEx(
        UIntPtr hKey,
        String lpValueName,
        Int32 lpReserved,
        out UInt32 lpType,
        [Out] byte[] lpData,
        ref UInt32 lpcbData);

        /// <summary>
        /// Sets the data and type of a specified value under a registry key.
        /// </summary>
        /// See http://msdn.microsoft.com/en-us/library/ms724923(VS.85).aspx for more info about the parameters and return value.<br/>
        [DllImport("advapi32.dll", SetLastError = true)]
        static extern Int32 RegSetValueEx(
        UInt32 hKey,
        [MarshalAs(UnmanagedType.LPStr)] String lpValueName,
        Int32 Reserved,
        Microsoft.Win32.RegistryValueKind dwType,
        IntPtr lpData,
        Int32 cbData);

        /// <summary>
        /// Creates the specified registry key. If the key already exists, the function opens it. Note that key names are not case sensitive.
        /// </summary>
        /// See http://msdn.microsoft.com/en-us/library/ms724844(v=VS.85).aspx for more info about the parameters and return value.<br/>
        [DllImport("advapi32.dll", SetLastError = true)]
        static extern Int32 RegCreateKeyEx(
        UInt32 hKey,
        String lpSubKey,
        UInt32 Reserved,
        String lpClass,
        RegOption dwOptions,
        RegSAM samDesired,
        IntPtr lpSecurityAttributes,
        out UInt32 phkResult,
        out RegResult lpdwDisposition);

        /// <summary>
        /// Closes a handle to the specified registry key.
        /// </summary>
        /// See http://msdn.microsoft.com/en-us/library/ms724837(VS.85).aspx for more info about the parameters and return value.<br/>
        [DllImport("advapi32.dll", SetLastError = true)]
        static extern Int32 RegCloseKey(
        UInt32 hKey);

        /// <summary>
        /// Deletes a subkey and its values from the specified platform-specific view of the registry. Note that key names are not case sensitive.
        /// </summary>
        /// See http://msdn.microsoft.com/en-us/library/ms724847(VS.85).aspx for more info about the parameters and return value.<br/>
        [DllImport("advapi32.dll", EntryPoint = "RegDeleteKeyEx", SetLastError = true)]
        public static extern Int32 RegDeleteKeyEx(
        UInt32 hKey,
        String lpSubKey,
        RegSAM samDesired,
        UInt32 Reserved);

        #endregion

        /// <summary>
        /// Registry creating volatile check.
        /// </summary>
        [Flags]
        public enum RegOption
        {
            NonVolatile = 0x0,
            Volatile = 0x1,
            CreateLink = 0x2,
            BackupRestore = 0x4,
            OpenLink = 0x8
        }

        /// <summary>
        /// Access mask the specifies the platform-specific view of the registry.
        /// </summary>
        [Flags]
        public enum RegSAM
        {
            QueryValue = 0x00000001,
            SetValue = 0x00000002,
            CreateSubKey = 0x00000004,
            EnumerateSubKeys = 0x00000008,
            Notify = 0x00000010,
            CreateLink = 0x00000020,
            WOW64_32Key = 0x00000200,
            WOW64_64Key = 0x00000100,
            WOW64_Res = 0x00000300,
            Read = 0x00020019,
            Write = 0x00020006,
            Execute = 0x00020019,
            AllAccess = 0x000f003f
        }

        /// <summary>
        /// Structure for security attributes.
        /// </summary>
        [StructLayout(LayoutKind.Sequential)]
        public struct SECURITY_ATTRIBUTES
        {
            public Int32 nLength;
            public IntPtr lpSecurityDescriptor;
            public Int32 bInheritHandle;
        }

        /// <summary>
        /// Flag returned by calling RegCreateKeyEx.
        /// </summary>
        public enum RegResult
        {
            CreatedNewKey = 0x00000001,
            OpenedExistingKey = 0x00000002
        }

        /// <summary>
        /// Class to create an object to handle the group policy operation.
        /// </summary>
        public class GroupPolicyObjectHandler
        {
            public const Int32 REG_NONE = 0;
            public const Int32 REG_SZ = 1;
            public const Int32 REG_EXPAND_SZ = 2;
            public const Int32 REG_BINARY = 3;
            public const Int32 REG_DWORD = 4;
            public const Int32 REG_DWORD_BIG_ENDIAN = 5;
            public const Int32 REG_MULTI_SZ = 7;
            public const Int32 REG_QWORD = 11;

            // Group Policy interface handler
            IGroupPolicyObject iGroupPolicyObject;
            // Group Policy object handler.
            GroupPolicyObject groupPolicyObject;

            #region constructor

            /// <summary>
            /// Constructor.
            /// </summary>
            /// <param name="remoteMachineName">Target machine name to operate group policy</param>
            /// <exception cref="System.Runtime.InteropServices.COMException">Throw when com execution throws exceptions</exception>
            public GroupPolicyObjectHandler(String remoteMachineName)
            {
                groupPolicyObject = new GroupPolicyObject();
                iGroupPolicyObject = (IGroupPolicyObject)groupPolicyObject;
                try
                {
                    if (String.IsNullOrEmpty(remoteMachineName))
                    {
                        iGroupPolicyObject.OpenLocalMachineGPO(GPO_OPEN_LOAD_REGISTRY);
                    }
                    else
                    {
                        iGroupPolicyObject.OpenRemoteMachineGPO(remoteMachineName, GPO_OPEN_LOAD_REGISTRY);
                    }
                }
                catch (COMException e)
                {
                    throw e;
                }
            }

            #endregion

            #region interface related methods

            /// <summary>
            /// Retrieves the display name for the GPO.
            /// </summary>
            /// <returns>Display name</returns>
            /// <exception cref="System.Runtime.InteropServices.COMException">Throw when com execution throws exceptions</exception>
            public String GetDisplayName()
            {
                StringBuilder pszName = new StringBuilder(Byte.MaxValue);
                try
                {
                    iGroupPolicyObject.GetDisplayName(pszName, Byte.MaxValue);
                }
                catch (COMException e)
                {
                    throw e;
                }
                return pszName.ToString();
            }

            /// <summary>
            /// Retrieves the computer name of the remote GPO.
            /// </summary>
            /// <returns>Machine name</returns>
            /// <exception cref="System.Runtime.InteropServices.COMException">Throw when com execution throws exceptions</exception>
            public String GetMachineName()
            {
                StringBuilder pszName = new StringBuilder(Byte.MaxValue);
                try
                {
                    iGroupPolicyObject.GetMachineName(pszName, Byte.MaxValue);
                }
                catch (COMException e)
                {
                    throw e;
                }
                return pszName.ToString();
            }

            /// <summary>
            /// Retrieves the options for the GPO.
            /// </summary>
            /// <returns>Options flag</returns>
            /// <exception cref="System.Runtime.InteropServices.COMException">Throw when com execution throws exceptions</exception>
            public Int32 GetOptions()
            {
                try
                {
                    return iGroupPolicyObject.GetOptions();
                }
                catch (COMException e)
                {
                    throw e;
                }
            }

            /// <summary>
            /// Retrieves the path to the GPO.
            /// </summary>
            /// <returns>The path to the GPO</returns>
            /// <exception cref="System.Runtime.InteropServices.COMException">Throw when com execution throws exceptions</exception>
            public String GetPath()
            {
                StringBuilder pszName = new StringBuilder(Byte.MaxValue);
                try
                {
                    iGroupPolicyObject.GetPath(pszName, Byte.MaxValue);
                }
                catch (COMException e)
                {
                    throw e;
                }
                return pszName.ToString();
            }

            /// <summary>
            /// Retrieves a handle to the root of the registry key for the machine section.
            /// </summary>
            /// <returns>A handle to the root of the registry key for the specified GPO computer section</returns>
            /// <exception cref="System.Runtime.InteropServices.COMException">Throw when com execution throws exceptions</exception>
            public UInt32 GetMachineRegistryKey()
            {
                UInt32 handle;
                try
                {
                    handle = iGroupPolicyObject.GetRegistryKey(GPO_OPTION_DISABLE_MACHINE);
                }
                catch (COMException e)
                {
                    throw e;
                }
                return handle;
            }

            /// <summary>
            /// Retrieves a handle to the root of the registry key for the user section.
            /// </summary>
            /// <returns>A handle to the root of the registry key for the specified GPO user section</returns>
            /// <exception cref="System.Runtime.InteropServices.COMException">Throw when com execution throws exceptions</exception>
            public UInt32 GetUserRegistryKey()
            {
                UInt32 handle;
                try
                {
                    handle = iGroupPolicyObject.GetRegistryKey(GPO_OPTION_DISABLE_USER);
                }
                catch (COMException e)
                {
                    throw e;
                }
                return handle;
            }

            /// <summary>
            /// Saves the specified registry policy settings to disk and updates the revision number of the GPO.
            /// </summary>
            /// <param name="isMachine">Specifies the registry policy settings to be saved. If this parameter is TRUE, the computer policy settings are saved. Otherwise, the user policy settings are saved.</param>
            /// <param name="isAdd">Specifies whether this is an add or delete operation. If this parameter is FALSE, the last policy setting for the specified extension pGuidExtension is removed. In all other cases, this parameter is TRUE.</param>
            /// <exception cref="System.Runtime.InteropServices.COMException">Throw when com execution throws exceptions</exception>
            public void Save(bool isMachine, bool isAdd)
            {
                try
                {
                    iGroupPolicyObject.Save(isMachine, isAdd, REGISTRY_EXTENSION_GUID, CLSID_GPESnapIn);
                }
                catch (COMException e)
                {
                    throw e;
                }
            }

            #endregion

            #region customized methods

            /// <summary>
            /// Set the group policy value.
            /// </summary>
            /// <param name="isMachine">Specifies the registry policy settings to be saved. If this parameter is TRUE, the computer policy settings are saved. Otherwise, the user policy settings are saved.</param>
            /// <param name="subKey">Group policy config full path</param>
            /// <param name="valueName">Group policy config key name</param>
            /// <param name="value">If value is null, it will envoke the delete method</param>
            /// <returns>Whether the config is successfully set</returns>
            public ResultCode SetGroupPolicy(bool isMachine, String subKey, String valueName, object value)
            {
                UInt32 gphKey = (isMachine) ? GetMachineRegistryKey() : GetUserRegistryKey();
                UInt32 gphSubKey;
                UIntPtr hKey;
                RegResult flag;

                if (null == value)
                {
                    // check the key's existance
                    if (RegOpenKeyEx((UIntPtr)gphKey, subKey, 0, RegSAM.QueryValue, out hKey) == 0)
                    {
                        RegCloseKey((UInt32)hKey);
                        // delete the GPO
                        Int32 hr = RegDeleteKeyEx(
                        gphKey,
                        subKey,
                        RegSAM.Write,
                        0);
                        if (0 != hr)
                        {
                            RegCloseKey(gphKey);
                            return ResultCode.CreateOrOpenFailed;
                        }
                        Save(isMachine, false);
                    }
                    else
                    {
                        // not exist
                    }

                }
                else
                {
                    // set the GPO
                    Int32 hr = RegCreateKeyEx(
                    gphKey,
                    subKey,
                    0,
                    null,
                    RegOption.NonVolatile,
                    RegSAM.Write,
                    IntPtr.Zero,
                    out gphSubKey,
                    out flag);
                    if (0 != hr)
                    {
                        RegCloseKey(gphSubKey);
                        RegCloseKey(gphKey);
                        return ResultCode.CreateOrOpenFailed;
                    }

                    Int32 cbData = 4;
                    IntPtr keyValue = IntPtr.Zero;

                    if (value.GetType() == typeof(Int32))
                    {
                        keyValue = Marshal.AllocHGlobal(cbData);
                        Marshal.WriteInt32(keyValue, (Int32)value);
                        hr = RegSetValueEx(gphSubKey, valueName, 0, RegistryValueKind.DWord, keyValue, cbData);
                    }
                    else if (value.GetType() == typeof(String))
                    {
                        keyValue = Marshal.StringToHGlobalAnsi(value.ToString());
                        cbData = System.Text.Encoding.UTF8.GetByteCount(value.ToString()) + 1;
                        hr = RegSetValueEx(gphSubKey, valueName, 0, RegistryValueKind.String, keyValue, cbData);
                    }
                    else
                    {
                        RegCloseKey(gphSubKey);
                        RegCloseKey(gphKey);
                        return ResultCode.SetFailed;
                    }

                    if (0 != hr)
                    {
                        RegCloseKey(gphSubKey);
                        RegCloseKey(gphKey);
                        return ResultCode.SetFailed;
                    }
                    try
                    {
                        Save(isMachine, true);
                    }
                    catch (COMException e)
                    {
                        RegCloseKey(gphSubKey);
                        RegCloseKey(gphKey);
                        return ResultCode.SaveFailed;
                    }
                    RegCloseKey(gphSubKey);
                    RegCloseKey(gphKey);
                }

                return ResultCode.Succeed;
            }

            /// <summary>
            /// Get the config of the group policy.
            /// </summary>
            /// <param name="isMachine">Specifies the registry policy settings to be saved. If this parameter is TRUE, get from the computer policy settings. Otherwise, get from the user policy settings.</param>
            /// <param name="subKey">Group policy config full path</param>
            /// <param name="valueName">Group policy config key name</param>
            /// <returns>The setting of the specified config</returns>
            public object GetGroupPolicy(bool isMachine, String subKey, String valueName)
            {
                UIntPtr gphKey = (UIntPtr)((isMachine) ? GetMachineRegistryKey() : GetUserRegistryKey());
                UIntPtr hKey;
                object keyValue = null;
                UInt32 size = 1;

                if (RegOpenKeyEx(gphKey, subKey, 0, RegSAM.QueryValue, out hKey) == 0)
                {
                    UInt32 type;
                    byte[] data = new byte[size];  // to store retrieved the value's data

                    if (RegQueryValueEx(hKey, valueName, 0, out type, data, ref size) == 234)
                    {
                        //size retreived
                        data = new byte[size]; //redefine data
                    }

                    if (RegQueryValueEx(hKey, valueName, 0, out type, data, ref size) != 0)
                    {
                        return null;
                    }

                    switch (type)
                    {
                        case REG_NONE:
                        case REG_BINARY:
                            keyValue = data;
                            break;
                        case REG_DWORD:
                            keyValue = (((data[0] | (data[1] << 8)) | (data[2] << 16)) | (data[3] << 24));
                            break;
                        case REG_DWORD_BIG_ENDIAN:
                            keyValue = (((data[3] | (data[2] << 8)) | (data[1] << 16)) | (data[0] << 24));
                            break;
                        case REG_QWORD:
                            {
                                UInt32 numLow = (UInt32)(((data[0] | (data[1] << 8)) | (data[2] << 16)) | (data[3] << 24));
                                UInt32 numHigh = (UInt32)(((data[4] | (data[5] << 8)) | (data[6] << 16)) | (data[7] << 24));
                                keyValue = (long)(((ulong)numHigh << 32) | (ulong)numLow);
                                break;
                            }
                        case REG_SZ:
                            var s = Encoding.Unicode.GetString(data, 0, (Int32)size);
                            keyValue = s.Substring(0, s.Length - 1);
                            break;
                        case REG_EXPAND_SZ:
                            keyValue = Environment.ExpandEnvironmentVariables(Encoding.Unicode.GetString(data, 0, (Int32)size));
                            break;
                        case REG_MULTI_SZ:
                            {
                                List<string> strings = new List<String>();
                                String packed = Encoding.Unicode.GetString(data, 0, (Int32)size);
                                Int32 start = 0;
                                Int32 end = packed.IndexOf("", start);
                                while (end > start)
                                {
                                    strings.Add(packed.Substring(start, end - start));
                                    start = end + 1;
                                    end = packed.IndexOf("", start);
                                }
                                keyValue = strings.ToArray();
                                break;
                            }
                        default:
                            throw new NotSupportedException();
                    }

                    RegCloseKey((UInt32)hKey);
                }

                return keyValue;
            }

            #endregion

        }
    }

    public class Helper
    {
        private static object _returnValueFromSet, _returnValueFromGet;

        /// <summary>
        /// Set policy config
        /// It will start a single thread to set group policy.
        /// </summary>
        /// <param name="isMachine">Whether is machine config</param>
        /// <param name="configFullPath">The full path configuration</param>
        /// <param name="configKey">The configureation key name</param>
        /// <param name="value">The value to set, boxed with proper type [ String, Int32 ]</param>
        /// <returns>Whether the config is successfully set</returns>
        [MethodImplAttribute(MethodImplOptions.Synchronized)]
        public static ResultCode SetGroupPolicy(bool isMachine, String configFullPath, String configKey, object value)
        {
            Thread worker = new Thread(SetGroupPolicy);
            worker.SetApartmentState(ApartmentState.STA);
            worker.Start(new object[] { isMachine, configFullPath, configKey, value });
            worker.Join();
            return (ResultCode)_returnValueFromSet;
        }

        /// <summary>
        /// Thread start for seting group policy.
        /// Called by public static ResultCode SetGroupPolicy(bool isMachine, WinRMGPConfigName configName, object value)
        /// </summary>
        /// <param name="values">
        /// values[0] - isMachine<br/>
        /// values[1] - configFullPath<br/>
        /// values[2] - configKey<br/>
        /// values[3] - value<br/>
        /// </param>
        private static void SetGroupPolicy(object values)
        {
            object[] valueList = (object[])values;
            bool isMachine = (bool)valueList[0];
            String configFullPath = (String)valueList[1];
            String configKey = (String)valueList[2];
            object value = valueList[3];

            WinAPIForGroupPolicy.GroupPolicyObjectHandler gpHandler = new WinAPIForGroupPolicy.GroupPolicyObjectHandler(null);

            _returnValueFromSet = gpHandler.SetGroupPolicy(isMachine, configFullPath, configKey, value);
        }

        /// <summary>
        /// Get policy config.
        /// It will start a single thread to get group policy
        /// </summary>
        /// <param name="isMachine">Whether is machine config</param>
        /// <param name="configFullPath">The full path configuration</param>
        /// <param name="configKey">The configureation key name</param>
        /// <returns>The group policy setting</returns>
        [MethodImplAttribute(MethodImplOptions.Synchronized)]
        public static object GetGroupPolicy(bool isMachine, String configFullPath, String configKey)
        {
            Thread worker = new Thread(GetGroupPolicy);
            worker.SetApartmentState(ApartmentState.STA);
            worker.Start(new object[] { isMachine, configFullPath, configKey });
            worker.Join();
            return _returnValueFromGet;
        }

        /// <summary>
        /// Thread start for geting group policy.
        /// Called by public static object GetGroupPolicy(bool isMachine, WinRMGPConfigName configName)
        /// </summary>
        /// <param name="values">
        /// values[0] - isMachine<br/>
        /// values[1] - configFullPath<br/>
        /// values[2] - configKey<br/>
        /// </param>
        public static void GetGroupPolicy(object values)
        {
            object[] valueList = (object[])values;
            bool isMachine = (bool)valueList[0];
            String configFullPath = (String)valueList[1];
            String configKey = (String)valueList[2];

            WinAPIForGroupPolicy.GroupPolicyObjectHandler gpHandler = new WinAPIForGroupPolicy.GroupPolicyObjectHandler(null);

            _returnValueFromGet = gpHandler.GetGroupPolicy(isMachine, configFullPath, configKey);
        }
    }
}
'@
#endregion

#region Get-Type (helper function for creating generic types)
function Get-Type
{
    # .ExternalHelp AutomatedLab.Help.xml
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
    # .ExternalHelp AutomatedLab.Help.xml
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
Set-Alias -Name ?? -Value Invoke-Ternary -Option AllScope -Description "Ternary Operator like '?' in C#" -Scope Global
#endregion

#region Test-IsAdministrator
function Test-IsAdministrator
{
    # .ExternalHelp AutomatedLab.Help.xml
    param ()
    
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object -TypeName Security.Principal.WindowsPrincipal -ArgumentList $currentUser).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}
#endregion

#region Get-LabHyperVAvailableMemory
function Get-LabHyperVAvailableMemory
{
    # .ExternalHelp AutomatedLab.Help.xml
    [int](((Get-WmiObject -Namespace Root\Cimv2 -Class win32_operatingsystem).TotalVisibleMemorySize) / 1kb)
}
#endregion Get-LabHyperVAvailableMemory

#region Reset-AutomatedLab
function Reset-AutomatedLab
{
    # .ExternalHelp AutomatedLab.Help.xml
    Remove-Lab
    Remove-Module *
}
#endregion Reset-AutomatedLab

#region Save-Hashes
function Save-Hashes
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletbinding()]
    param
    (
        $Filename = 'C:\ALFiles.txt',
        $FolderName
    )
    
    $ModulePath = "$([environment]::getfolderpath('mydocuments'))\WindowsPowerShell\Modules"
    $Folders = 'AutomatedLab', 'AutomatedLabDefinition', 'AutomatedLabUnattended', 'AutomatedLabWorker', 'HostsFile', 'PSFileTransfer', 'PSLog'
    
    foreach ($Folder in $Folders)
    {
        Get-FileHash -Path "$ModulePath\$Folder\*" | Select-Object Algorithm, Hash, @{name='Path';expression={$_.Path.Replace($ModulePath, '<MODULEPATH>')}} | Export-Csv -Path $Filename -Append
    }

    if ($FolderName)
    {
        foreach ($Folder in $Foldername)
        {
            Get-ChildItem -Path C:\LabSources\Tools\PSv4Part1 -Recurse -Exclude '*.ISO' | Get-FileHash | Export-Csv -Path $Filename -Append
        }
    }
}
#endregion Save-Hashes

#region Test-FileHashes
function Test-FileHashes
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletbinding()]
    param
    (
        $Filename = 'C:\ALFiles.txt'
    )
    
    $ModulePath = "$([environment]::getfolderpath('mydocuments'))\WindowsPowerShell\Modules"
    
    $StoredHashes = Import-Csv -Path $Filename
    
    $Issues = $False
    foreach ($File in $StoredHashes)
    {
        if (-not (Test-Path $File.path.replace('<MODULEPATH>', $ModulePath)))
        {
            "'$File' is missing"
            $Issues = $True
        }
        else
        {
            if ((Get-FileHash -Path $File.path.replace('<MODULEPATH>', $ModulePath)).hash -ne $File.Hash)
            {
                "'$File.Path' has wrong hash and is thereby not the file you think it is"
                $Issues = $True
            }
        }
    }
    
    $Issues
}
#endregion Test-FileHashes

#region Save-FileList
function Save-FileList
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletbinding()]
    param
    (
        $Filename = 'C:\ALfiles.txt'
    )
    
    Get-ChildItem $ModulePath -Recurse -Directory -Include 'AutomatedLab', 'AutomatedLabDefinition', 'AutomatedLabUnattended', 'AutomatedLabWorker', 'HostsFile', 'PSFileTransfer', 'PSLog' | % {Get-ChildItem $_.FullName | Select-Object FullName} | Export-Csv -Path $Filename
}
#endregion Save-FileList

#region Test-FileList
function Test-FileList
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletbinding()]
    param
    (
        $Filename = 'C:\ALfiles.txt'
    )
    
    $StoredFiles = Import-Csv -Path $Filename
    $Files = Get-ChildItem $ModulePath -Recurse -Directory -Include 'AutomatedLab', 'AutomatedLabDefinition', 'AutomatedLabUnattended', 'AutomatedLabWorker', 'HostsFile', 'PSFileTransfer', 'PSLog' | % {Get-ChildItem $_.FullName | Select-Object FullName}
    
    if (Compare-Object -ReferenceObject $StoredFiles -DifferenceObject $Files)
    {
        $true
    }
    else
    {
        $false
    }
}
#endregion Test-FileList

#region Test-FolderExist
function Test-FolderExist
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletbinding()]
    param
    (
        $FolderName
    )
    
    if (-not (Test-Path -Path $FolderName))
    {
        throw "The folder '$FolderName' is missing or is at the wrong level. This folder is required for setting up this lab"
    }
}
#endregion Test-FolderExist

#region Test-FolderNotExist
function Test-FolderNotExist
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletbinding()]
    param
    (
        $FolderName
    )
    
    if (Test-Path -Path $FolderName)
    {
        throw "The folder '$FolderName' exist while it should NOT exist"
    }
}
#endregion Test-FolderNotExist

#region Restart-ServiceResilient
function Restart-ServiceResilient
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletbinding()]
    param
    (
        [string[]]$ComputerName,
        $ServiceName,
        [switch]$NoNewLine
    )
    
    Write-LogFunctionEntry
    
    $jobs = Invoke-LabCommand -ComputerName $ComputerName -AsJob -PassThru -NoDisplay -ActivityName "Restart service '$ServiceName' on computers '$($ComputerName -join ', ')'" -ScriptBlock `
    {
        param
        (
            [string]$ServiceName
        )
        
        function Get-ServiceRestartInfo
        {
            param
            (
                [string]$ServiceName,
                [switch]$WasStopped,
                [switch]$WasStarted,
                [double]$Index
            )
    
            $serviceDisplayName = (Get-Service $ServiceName).DisplayName
    
            $newestEvent = "($((Get-EventLog -LogName System -newest 1).Index)) " + (Get-EventLog -LogName System -newest 1).Message
            Write-Debug -Message "$(Get-Date -Format 'mm:dd:ss') - Get-ServiceRestartInfo - ServiceName: $ServiceName ($serviceDisplayName) - WasStopped: $WasStopped - WasStarted:$WasStarted - Index: $Index - Newest event: $newestEvent"
    
    
            $result = $true
    
            if ($WasStopped)
            {
                $events = @(Get-EventLog -LogName System -Index ($Index..($Index+10000)) | Where-Object {$_.Message -like "*$serviceDisplayName*entered*stopped*"})
                Write-Debug -Message "$(Get-Date -Format 'mm:dd:ss') - Events found: $($events.count)"
                $result = ($events.count -gt 0)
            }
            if ($WasStarted)
            {
                $events = @(Get-EventLog -LogName System -Index ($Index..($Index+10000)) | Where-Object {$_.Message -like "*$serviceDisplayName*entered*running*"})
                Write-Debug -Message "$(Get-Date -Format 'mm:dd:ss') - Events found: $($events.count)"
                $result = ($events.count -gt 0)
            }
    
            Write-Debug -Message "$(Get-Date -Format 'mm:dd:ss') - Result:$result"
            $result
        }


        $BackupVerbosePreference = $VerbosePreference
        $BackupDebugPreference   = $DebugPreference
        $VerbosePreference = 'Continue'
        $DebugPreference   = 'Continue'

        $ServiceName = 'nlasvc'

        $dependentServices = Get-Service -Name $ServiceName -DependentServices | Where-Object {$_.Status -eq 'Running'} | Select-Object -ExpandProperty Name
        Write-Verbose -Message "$(Get-Date -Format 'mm:dd:ss') - Dependent services: '$($dependentServices -join ',')'"


        $serviceDisplayName = (Get-Service $ServiceName).DisplayName
        if ((Get-Service -Name "$ServiceName").Status -eq 'Running')
        {
            $newestEventLogIndex = (Get-EventLog -LogName System -Newest 1).Index
            $retries = 5
            do
            {
                Write-Verbose -Message "$(Get-Date -Format 'mm:dd:ss') - Trying to stop service '$ServiceName'"
                $EAPbackup = $ErrorActionPreference
                $WAPbackup = $WarningPreference
        
                $ErrorActionPreference = 'SilentlyContinue'
                $WarningPreference     = 'SilentlyContinue'
                Stop-Service -Name $ServiceName -Force
                $ErrorActionPreference = $EAPbackup
                $WarningPreference = $WAPbackup
        
                $retries--
                Start-Sleep -Seconds 1
            }
            until ((Get-ServiceRestartInfo -ServiceName $ServiceName -WasStopped -Index $newestEventLogIndex) -or $retries -le 0)
        }
            
        if ($retries -gt 0)
        {
            Write-Verbose -Message "$(Get-Date -Format 'mm:dd:ss') - Service '$ServiceName' has been stopped"
        }
        else
        {
            Write-Verbose -Message "$(Get-Date -Format 'mm:dd:ss') - Service '$ServiceName' could NOT be stopped"
            return
        }


        if (-not (Get-ServiceRestartInfo -ServiceName $ServiceName -WasStarted -Index $newestEventLogIndex))
        {
            #if service did not start by itself
            $newestEventLogIndex = (Get-EventLog -LogName System -Newest 1).Index
            $retries = 5
            do
            {
                Write-Verbose -Message "$(Get-Date -Format 'mm:dd:ss') - Trying to start service '$ServiceName'"
                Start-Service -Name $ServiceName -ErrorAction SilentlyContinue
                $retries--
                if (-not (Get-ServiceRestartInfo -ServiceName $ServiceName -WasStarted -Index $newestEventLogIndex))
                {
                    Start-Sleep -Seconds 1
                }
            }
            until ((Get-ServiceRestartInfo -ServiceName $ServiceName -WasStarted -Index $newestEventLogIndex) -or $retries -le 0)
        }


        if ($retries -gt 0)
        {
            Write-Verbose -Message "$(Get-Date -Format 'mm:dd:ss') - Service '$ServiceName' was started"
        }
        else
        {
            Write-Verbose -Message "$(Get-Date -Format 'mm:dd:ss') - Service '$ServiceName' could NOT be started"
            return
        }
        
        foreach ($dependentService in $dependentServices)
        {
            if (Get-ServiceRestartInfo -ServiceName $dependentService -WasStarted -Index $newestEventLogIndex)
            {
                Write-Debug -Message "$(Get-Date -Format 'mm:dd:ss') - Dependent service '$dependentService' has already auto-started"
            }
            else
            {
                $newestEventLogIndex = (Get-EventLog -LogName System -Newest 1).Index
                $retries = 5
                do
                {
                    Write-Debug -Message "$(Get-Date -Format 'mm:dd:ss') - Trying to start depending service '$dependentService'"
                    Start-Service $dependentService -ErrorAction SilentlyContinue
                    $retries--
                }
                until ((Get-ServiceRestartInfo -ServiceName $ServiceName -WasStarted -Index $newestEventLogIndex) -or $retries -le 0)

                if (Get-ServiceRestartInfo -ServiceName $ServiceName -WasStarted -Index $newestEventLogIndex)
                {
                    Write-Debug -Message "$(Get-Date -Format 'mm:dd:ss') - Dependent service '$ServiceName' was started"
                }
                else
                {
                    Write-Debug -Message "$(Get-Date -Format 'mm:dd:ss') - Dependent service '$ServiceName' could NOT be started"
                }
            }
        }
        
        $VerbosePreference = $BackupVerbosePreference
        $DebugPreference   = $BackupDebugPreference
    } -ArgumentList $ServiceName
    
    Wait-LWLabJob -Job $jobs -NoDisplay -Timeout 30 -NoNewLine:$NoNewLine
    
    Write-LogFunctionExit
}
#endregion Restart-ServiceResilient

#region Remove-DeploymentFiles
function Remove-DeploymentFiles
{
    # .ExternalHelp AutomatedLab.Help.xml
    Invoke-LabCommand -ComputerName (Get-LabMachine) -ActivityName 'Remove deployment files (files used during deployment)' -AsJob -NoDisplay -ScriptBlock `
    {
        Remove-Item -Path c:\unattend.xml
        Remove-Item -Path c:\WSManRegKey.reg
        Remove-Item -Path c:\DeployDebug -Recurse
    }
}
#endregion Remove-DeploymentFiles

#region Enable-LabVMFirewallGroup
function Enable-LabVMFirewallGroup
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [Parameter(Mandatory)]
        [string[]]$FirewallGroup
    )
    
    Write-LogFunctionEntry
    
    $machine = Get-LabMachine -ComputerName $ComputerName

    Invoke-LabCommand -ComputerName $machine -ActivityName 'Enable firewall group' -NoDisplay -ScriptBlock `
    {
        param
        (
            [string]$FirewallGroup
        )
        
        $FirewallGroups = $FirewallGroup.Split(';')
        
        foreach ($group in $FirewallGroups)
        {
            Write-Verbose -Message "Enable firewall group '$group' on '$(hostname)'"
            netsh.exe advfirewall firewall set rule group="$group" new enable=Yes
        }
    } -ArgumentList ($FirewallGroup -join ';')
    
    Write-LogFunctionExit
}
#endregion Enable-LabVMFirewallGroup

#region Disable-LabVMFirewallGroup
function Disable-LabVMFirewallGroup
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [Parameter(Mandatory)]
        [string[]]$FirewallGroup
    )
    
    Write-LogFunctionEntry
    
    $machine = Get-LabMachine -ComputerName $ComputerName

    Invoke-LabCommand -ComputerName $machine -ActivityName 'Disable firewall group' -NoDisplay -ScriptBlock `
    {
        param
        (
            [string]$FirewallGroup
        )
        
        $FirewallGroups = $FirewallGroup.Split(';')
        
        foreach ($group in $FirewallGroups)
        {
            Write-Verbose -Message "Disable firewall group '$group' on '$(hostname)'"
            netsh.exe advfirewall firewall set rule group="$group" new enable=No
        }
    } -ArgumentList ($FirewallGroup -join ';')
    
    Write-LogFunctionExit
}
#endregion Disable-LabVMFirewallGroup

#region Test-Port
function Test-Port
{  
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletbinding()]

    Param(  
        [Parameter(Mandatory, Position = 0)]  
        [string[]]$ComputerName,

        [Parameter(Mandatory, Position = 1)]
        [int]$Port,

        [int]$Count = 1,

        [int]$Delay = 500,
        
        [int]$TcpTimeout = 1000,
        [int]$UdpTimeout = 1000,
        [switch]$Tcp,
        [switch]$Udp
    )

    begin
    {  
        if (-not $Tcp -and -not $Udp)
        {
            $Tcp = $true
        }
        #Typically you never do this, but in this case I felt it was for the benefit of the function  
        #as any errors will be noted in the output of the report          
        $ErrorActionPreference = 'SilentlyContinue'
        $report = @()

        $sw = New-Object System.Diagnostics.Stopwatch
    }

    process
    {
        foreach ($c in $ComputerName)
        {
            for ($i = 0; $i -lt $Count; $i++) 
            {
                $result = New-Object PSObject | Select-Object Server, Port, TypePort, Open, Notes, ResponseTime
                $result.Server = $c
                $result.Port = $Port
                $result.TypePort = 'TCP'

                if ($Tcp)
                {
                    $tcpClient = New-Object System.Net.Sockets.TcpClient
                    $sw.Start()
                    $connect = $tcpClient.BeginConnect($c, $Port, $null, $null)
                    $wait = $connect.AsyncWaitHandle.WaitOne($TcpTimeout, $false)
                    
                    if(-not $wait)
                    {
                        $tcpClient.Close()
                        $sw.Stop()
                        Write-Verbose 'Connection Timeout'

                        $result.Open = $false
                        $result.Notes = 'Connection to Port Timed Out'
                        $result.ResponseTime = $sw.ElapsedMilliseconds
                    }
                    else
                    {
                        [void]$tcpClient.EndConnect($connect)
                        $tcpClient.Close()
                        $sw.Stop()

                        $result.Open = $true
                    }

                    $result.ResponseTime = $sw.ElapsedMilliseconds
                }
                if ($Udp)
                {
                    $udpClient = New-Object System.Net.Sockets.UdpClient
                    $udpClient.Client.ReceiveTimeout = $UdpTimeout

                    $a = New-Object System.Text.ASCIIEncoding
                    $byte = $a.GetBytes("$(Get-Date)")

                    $result.Server = $c
                    $result.Port = $Port
                    $result.TypePort = 'UDP'

                    Write-Verbose 'Making UDP connection to remote server'
                    $sw.Start()
                    $udpClient.Connect($c, $Port)
                    Write-Verbose 'Sending message to remote host'
                    [void]$udpClient.Send($byte, $byte.Length)
                    Write-Verbose 'Creating remote endpoint'
                    $remoteEndpoint = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any,0)

                    try
                    {
                        Write-Verbose 'Waiting for message return'
                        $receiveBytes = $udpClient.Receive([ref]$remoteEndpoint)
                        $sw.Stop()
                        [string]$returnedData = $a.GetString($receiveBytes)
                        
                        Write-Verbose 'Connection Successful'
                            
                        $result.Open = $true
                        $result.Notes = $returnedData
                    }
                    catch
                    {
                        Write-Verbose 'Host maybe unavailable'
                        $result.Open = $false
                        $result.Notes = 'Unable to verify if port is open or if host is unavailable.'
                    }
                    finally
                    {
                        $udpClient.Close()
                        $result.ResponseTime = $sw.ElapsedMilliseconds
                    }
                }

                $sw.Reset()
                $report += $result

                Start-Sleep -Milliseconds $Delay
            }
        }
    }

    end
    {
        $report 
    }
}
#endregion Test-Port

#region Get-StringSection
function Get-StringSection
{
    # .ExternalHelp AutomatedLab.Help.xml
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$String,

        [Parameter(Mandatory)]
        [int]$SectionSize
    )

    process
    {
        0..($String.Length - 1) | 
        Group-Object -Property { [System.Math]::Truncate($_ / $SectionSize) } |
        ForEach-Object { -join $String[$_.Group] }
    }
}
#endregion Get-StringSection

#region Add-StringIncrement
function Add-StringIncrement
{
    # .ExternalHelp AutomatedLab.Help.xml
    param(
        [Parameter(Mandatory = $true)]
        [string]$String
    )
    
    $testNumberPattern = '^(?<text>.*?) (?<number>\d+)$'
    
    $result = $String -match $testNumberPattern
    
    if ($Matches.Number)
    {
        $String = $String.Substring(0, $String.Length - $Matches.Number.Length) + ([int]$Matches.Number + 1)
    }
    else
    {
        $String = $String + ' 0'
    }
    
    $String
}
#endregion Add-StringIncrement

#region Get-FullMesh
$meshType = @"
    using System;
    using System.Collections.Generic;
    using System.Linq;
    using System.Text;
    using System.Threading.Tasks;

    namespace Mesh
    {
        public class Item<T> where T : class
        {
            private T source;
            private T destination;

            public T Source
            {
                get { return source; }
                set { source = value; }
            }

            public T Destination
            {
                get { return destination; }
                set { destination = value; }
            }

            public override string ToString()
            {
                return string.Format("{0} - {1}", source.ToString(), destination.ToString());
            }

            public override int GetHashCode()
            {
                return source.GetHashCode() ^ destination.GetHashCode();
            }

            public override bool Equals(object obj)
            {
                T otherSource = null;
                T otherDestination = null;

                if (obj == null)
                    return false;

                if (obj.GetType().IsArray)
                {
                    var array = (object[])obj;
                    if (typeof(T) != array[0].GetType() || typeof(T) != array[1].GetType())
                        return false;
                    else
                    {
                        otherSource = (T)array[0];
                        otherDestination = (T)array[1];
                    }

                    if (!otherSource.Equals(this.source))
                        return false;

                    return otherDestination.Equals(this.destination);
                }
                else
                {
                    if (GetType() != obj.GetType())
                        return false;

                    Item<T> otherObject = (Item<T>)obj;

                    if (!this.destination.Equals(otherObject.destination))
                        return false;

                    return this.source.Equals(otherObject.source);
                }
            }
        }
    }
"@
function Get-FullMesh
{
    # .ExternalHelp AutomatedLab.Help.xml
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [array]$List,

        [switch]$OneWay
    )

    $mesh = New-Object System.Collections.ArrayList

    foreach ($item1 in $List)
    {
        foreach ($item2 in $list)
        {
            if ($item1 -eq $item2)
            { continue }

            if ($mesh.Contains(($item1, $item2)))
            { continue }

            if ($OneWay)
            {
                if ($mesh.Contains(($item2, $item1)))
                { continue }
            }

            $mesh.Add((New-Object (Get-Type -GenericType Mesh.Item -T string) -Property @{ Source = $item1; Destination = $item2 } )) | Out-Null
        }
    }

    $mesh
}
#endregion Get-FullMesh

#region Get-LabInternetFile
function Get-LabInternetFile
{
    # .ExternalHelp AutomatedLab.Help.xml
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri,

        [Parameter(Mandatory = $true)]
        [string]$Path,

        [switch]$Force,
        
        [switch]$PassThru
    )
    
    function Get-LabInternetFileInternal
    {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Uri,

            [Parameter(Mandatory = $true)]
            [string]$Path,

            [switch]$Force
        )
        
        $internalUri = New-Object System.Uri($Uri)
        $fileName = $internalUri.Segments[$internalUri.Segments.Count - 1]
    
        if (Test-Path -Path $Path -PathType Container)
        {
            $Path = Join-Path -Path $Path -ChildPath $fileName
        }

        if ((Test-Path -Path $Path) -and -not $Force)
        {
            Write-Warning "The file '$Path' does already exist, skipping the download"
        }
        else
        {
            if ((Test-Path -Path $Path) -and $Force)
            {
                Remove-Item -Path $Path -Force
            }
    
            Write-Verbose "Uri is '$Uri'"
            Write-Verbose "Path os '$Path'"

            try
            {
                $bytesProcessed = 0
                $request = [System.Net.WebRequest]::Create($Uri)
        
                if ($request)
                {
                    Write-Verbose 'WebRequest created'
                    $response = $request.GetResponse()
                    if ($response)
                    {
                        Write-Verbose 'Responce received'
                        $remoteStream = $response.GetResponseStream()
 
                        $localStream = [System.IO.File]::Create($Path)
 
                        $buffer = New-Object System.Byte[] 1024
                        $bytesRead = 0
 
                        do
                        {
                            $bytesRead = $remoteStream.Read($buffer, 0, $buffer.Length)
                            $localStream.Write($buffer, 0, $bytesRead)
                            $bytesProcessed += $bytesRead
                        
                            $percentageCompleted = $bytesProcessed / $response.ContentLength
                            Write-Progress -Activity "Downloading file '$fileName'" `
                            -Status ("{0:P} completed, {1:N2}MB of {2:N2}MB" -f $percentageCompleted, ($bytesProcessed / 1MB), ($response.ContentLength / 1MB)) `
                            -PercentComplete ($percentageCompleted * 100)
                        
                        } while ($bytesRead -gt 0)
                    }
                
                    $response
                }
            }
            catch
            {
                Write-Error -Exception $_.Exception
            }
            finally
            {
    
                if ($response) { $response.Close() }
                if ($remoteStream) { $remoteStream.Close() }
                if ($localStream) { $localStream.Close() }
            }
        }
    }
    
    $start = Get-Date
    
    if (Test-LabPathIsOnLabAzureLabSourcesStorage -Path $Path)
    {
        $machine = Get-LabMachine -IsRunning | Select-Object -First 1
        Write-Verbose "Target path is on AzureLabSources, invoking the copy job on the first available Azure machine."

        $result = Invoke-LabCommand -ComputerName $machine -ScriptBlock (Get-Command -Name Get-LabInternetFileInternal).ScriptBlock -ArgumentList $Uri, $Path -PassThru
    }
    else
    {
        Write-Verbose "Target path is local, invoking the copy job locally."
        $PSBoundParameters.Remove('PassThru') | Out-Null
        $result = Get-LabInternetFileInternal @PSBoundParameters
    }
    
    $end = Get-Date
    Write-Verbose "Download has taken: $($end - $start)"

    if ($PassThru)
    {
        New-Object PSObject -Property @{
            Uri = $Uri
            Path = $Path
            Length = $result.ContentLength
        }
    }
}
#endregion Get-LabInternetFile

#region Unblock-LabSources
function Unblock-LabSources
{
    # .ExternalHelp AutomatedLab.Help.xml
    param(
        [string]$Path = $global:labSources
    )

    Write-LogFunctionEntry

    $lab = Get-Lab -ErrorAction SilentlyContinue
    if(-not $lab)
    {
        $lab = Get-LabDefinition -ErrorAction SilentlyContinue
    }

    if($lab.DefaultVirtualizationEngine -eq 'Azure' -and $Path.StartsWith("\\"))
    {
        Write-Verbose 'Skipping the unblocking of lab sources since we are on Azure and lab sources are unblocked during Sync-LabAzureLabSources'
        return
    }

    if (-not (Test-Path -Path $Path))
    {
        Write-Error "The path '$Path' could not be found"
        return
    }

    $type = Get-Type -GenericType AutomatedLab.DictionaryXmlStore -T String, DateTime    

    try
    {
        $cache = $type::ImportFromRegistry('Cache', 'Timestamps')
        Write-Verbose 'Imported Cache\Timestamps from regirtry'
    }
    catch
    {
        $cache = New-Object $type
        Write-Verbose 'No entry found in the regirtry at Cache\Timestamps'
    }

    if (-not $cache['LabSourcesLastUnblock'] -or $cache['LabSourcesLastUnblock'] -lt (Get-Date).AddDays(-1))
    {
        Write-Verbose 'Last unblock more than 24 hours ago, unblocking files'
        Get-ChildItem -Path $Path -Recurse | Unblock-File
        $cache['LabSourcesLastUnblock'] = Get-Date
        $cache.ExportToRegistry('Cache', 'Timestamps')
        Write-Verbose 'LabSources folder unblocked and new timestamp written to Cache\Timestamps'
    }
    else
    {
        Write-Verbose 'Last unblock less than 24 hours ago, doing nothing'
    }

    Write-LogFunctionExit
}
#endregion Unblock-LabSources

#region Add-FunctionToPSSession
function Add-FunctionToPSSession
{
    # .ExternalHelp AutomatedLab.Help.xml
    [CmdletBinding(
            SupportsShouldProcess   = $false,
            ConfirmImpact           = 'None'
    )]

    param
    ( 
        [Parameter(
                HelpMessage	= 'Provide the session(s) to load the functions into', 
                Mandatory	= $true,
                Position	= 0
        )]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Runspaces.PSSession[]] 
        $Session,

        [Parameter( 
                HelpMessage			= 'Provide the function info to load into the session(s)', 
                Mandatory			= $true, 
                Position			= 1, 
                ValueFromPipeline	= $true 
        )]
        [ValidateNotNull()]
        [System.Management.Automation.FunctionInfo]
        $FunctionInfo
    )

    begin 
    {
        $cmdName = (Get-PSCallStack)[0].Command
        Write-Debug "[$cmdName] Entering function"

        $scriptBlock = 
        {
            param([string]$Path,[string]$Definition)
            $null = Set-Item -Path Function:\$Path -Value $Definition
        }
    }

    process
    {
        Invoke-Command -Session $Session -ScriptBlock $scriptBlock -ArgumentList $FunctionInfo.Name,$FunctionInfo.Definition
    }

    end
    {
        Write-Debug "[$cmdName] Exiting function"
    }
}
#endregion Add-FunctionToPSSession

#region Add-VariableToPSSession
function Add-VariableToPSSession
{
    # .ExternalHelp AutomatedLab.Help.xml
    [CmdletBinding(
            SupportsShouldProcess   = $false,
            ConfirmImpact           = 'None'
    )]

    param
    ( 
        [Parameter(
                HelpMessage	= 'Provide the session(s) to load the functions into', 
                Mandatory	= $true,
                Position	= 0
        )]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Runspaces.PSSession[]] 
        $Session,

        [Parameter( 
                HelpMessage			= 'Provide the variable info to load into the session(s)', 
                Mandatory			= $true, 
                Position			= 1, 
                ValueFromPipeline	= $true 
        )]
        [ValidateNotNull()]
        [System.Management.Automation.PSVariable]
        $PSVariable
    )

    begin 
    {
        $cmdName = (Get-PSCallStack)[0].Command
        Write-Debug "[$cmdName] Entering function"

        $scriptBlock = 
        {
            param([string]$Path,[object]$Value)
            $null = Set-Item -Path Variable:\$Path -Value $Value
        }
    }

    process
    {
        if ($PSVariable.Name -eq 'PSBoundParameters')
        {
            Invoke-Command -Session $Session -ScriptBlock $scriptBlock -ArgumentList 'ALBoundParameters', $PSVariable.Value
        }
        else
        {
            Invoke-Command -Session $Session -ScriptBlock $scriptBlock -ArgumentList $PSVariable.Name, $PSVariable.Value
        }
    }

    end
    {
        Write-Debug "[$cmdName] Exiting function"
    }
}
#endregion Add-VariableToPSSession

#region Sync-Parameter
function Sync-Parameter
{
    # .ExternalHelp AutomatedLab.Help.xml
    [Cmdletbinding()]
    param (
        [Parameter(Mandatory)]
        [System.Management.Automation.FunctionInfo]$Command,
        
        [hashtable]$Parameters
    )
    
    if (-not $PSBoundParameters.ContainsKey('Parameters'))
    {
        $Parameters = ([hashtable]$ALBoundParameters).Clone()
    }
    else
    {
        $Parameters = ([hashtable]$Parameters).Clone()
    }
    
    $commonParameters = [System.Management.Automation.Internal.CommonParameters].GetProperties().Name
    $commandParameterKeys = $Command.Parameters.Keys.GetEnumerator() | ForEach-Object { $_ }
    $parameterKeys = $Parameters.Keys.GetEnumerator() | ForEach-Object { $_ }
    
    $keysToRemove = Compare-Object -ReferenceObject $commandParameterKeys -DifferenceObject $parameterKeys |
    Select-Object -ExpandProperty InputObject

    $keysToRemove = $keysToRemove + $commonParameters | Select-Object -Unique #remove the common parameters
    
    foreach ($key in $keysToRemove)
    {
        $Parameters.Remove($key)
    }
    
    if ($PSBoundParameters.ContainsKey('Parameters'))
    {
        $Parameters
    }
    else
    {
        $global:ALBoundParameters = $Parameters
    }
}
#endregion Sync-Parameter

function Set-LabVMDescription
{
    # .ExternalHelp AutomatedLab.Help.xml
    [CmdletBinding()]
    param (
        [hashtable]$Hashtable,
        
        [string]$ComputerName
    )
    
    Write-LogFunctionEntry
    
    $t = Get-Type -GenericType AutomatedLab.SerializableDictionary -T String,String
    $d = New-Object $t
    
    foreach ($kvp in $Hashtable.GetEnumerator())
    {
        $d.Add($kvp.Key, $kvp.Value)
    }
    
    $sb = New-Object System.Text.StringBuilder
    $xmlWriterSettings = New-Object System.Xml.XmlWriterSettings
    $xmlWriterSettings.ConformanceLevel = 'Auto'
    $xmlWriter = [System.Xml.XmlWriter]::Create($sb, $xmlWriterSettings)

    $d.WriteXml($xmlWriter)
    
    Set-VM -Name $ComputerName -Notes $sb.ToString()
    
    Write-LogFunctionExit
}

function Get-LabSourcesLocationInternal
{
    param
    (
        [switch]$Local
    )
    $lab = Get-Lab -ErrorAction SilentlyContinue
    $labDefinition = Get-LabDefinition -ErrorAction SilentlyContinue

    $defaultEngine = 'HyperV'
    if ($lab)
    {
        $defaultEngine = $lab.DefaultVirtualizationEngine
    }
    elseif ($labDefinition)
    {
        $defaultEngine = $labDefinition.DefaultVirtualizationEngine
    }

    if ($defaultEngine -eq 'HyperV' -or $Local)
    {
        $hardDrives = (Get-WmiObject -NameSpace Root\CIMv2 -Class Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3}).DeviceID | Sort-Object -Descending

        foreach ($drive in $hardDrives)
        {
            if (Test-Path -Path "$drive\LabSources")
            {
                "$drive\LabSources"
            }
        }
    }
    elseif ($defaultEngine -eq 'Azure')
    {
        try
        {
            (Get-LabAzureLabSourcesStorage -ErrorAction Stop).Path
        }
        catch
        {
            Get-LabSourcesLocationInternal -Local
        }
    }
    else
    {
        Get-LabSourcesLocationInternal -Local
    }
}

Add-Type -TypeDefinition $meshType
Add-Type -TypeDefinition $gpoType -IgnoreWarnings