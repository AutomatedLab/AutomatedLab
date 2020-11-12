#region Internals
#region .net Types
$certStoreTypes = @'
using System;
using System.Runtime.InteropServices;

namespace System.Security.Cryptography.X509Certificates
{
    public class Win32
    {
        [DllImport("crypt32.dll", EntryPoint="CertOpenStore", CharSet=CharSet.Auto, SetLastError=true)]
        public static extern IntPtr CertOpenStore(
            int storeProvider,
            int encodingType,
            IntPtr hcryptProv,
            int flags,
            String pvPara);

        [DllImport("crypt32.dll", EntryPoint="CertCloseStore", CharSet=CharSet.Auto, SetLastError=true)]
        [return : MarshalAs(UnmanagedType.Bool)]
        public static extern bool CertCloseStore(
            IntPtr storeProvider,
            int flags);
    }

    public enum CertStoreLocation
    {
        CERT_SYSTEM_STORE_CURRENT_USER = 0x00010000,
        CERT_SYSTEM_STORE_LOCAL_MACHINE = 0x00020000,
        CERT_SYSTEM_STORE_SERVICES = 0x00050000,
        CERT_SYSTEM_STORE_USERS = 0x00060000
    }

    [Flags]
    public enum CertStoreFlags
    {
        CERT_STORE_NO_CRYPT_RELEASE_FLAG = 0x00000001,
        CERT_STORE_SET_LOCALIZED_NAME_FLAG = 0x00000002,
        CERT_STORE_DEFER_CLOSE_UNTIL_LAST_FREE_FLAG = 0x00000004,
        CERT_STORE_DELETE_FLAG = 0x00000010,
        CERT_STORE_SHARE_STORE_FLAG = 0x00000040,
        CERT_STORE_SHARE_CONTEXT_FLAG = 0x00000080,
        CERT_STORE_MANIFOLD_FLAG = 0x00000100,
        CERT_STORE_ENUM_ARCHIVED_FLAG = 0x00000200,
        CERT_STORE_UPDATE_KEYID_FLAG = 0x00000400,
        CERT_STORE_BACKUP_RESTORE_FLAG = 0x00000800,
        CERT_STORE_READONLY_FLAG = 0x00008000,
        CERT_STORE_OPEN_EXISTING_FLAG = 0x00004000,
        CERT_STORE_CREATE_NEW_FLAG = 0x00002000,
        CERT_STORE_MAXIMUM_ALLOWED_FLAG = 0x00001000
    }

    public enum CertStoreProvider
    {
        CERT_STORE_PROV_MSG                = 1,
        CERT_STORE_PROV_MEMORY             = 2,
        CERT_STORE_PROV_FILE               = 3,
        CERT_STORE_PROV_REG                = 4,
        CERT_STORE_PROV_PKCS7              = 5,
        CERT_STORE_PROV_SERIALIZED         = 6,
        CERT_STORE_PROV_FILENAME_A         = 7,
        CERT_STORE_PROV_FILENAME_W         = 8,
        CERT_STORE_PROV_FILENAME           = CERT_STORE_PROV_FILENAME_W,
        CERT_STORE_PROV_SYSTEM_A           = 9,
        CERT_STORE_PROV_SYSTEM_W           = 10,
        CERT_STORE_PROV_SYSTEM             = CERT_STORE_PROV_SYSTEM_W,
        CERT_STORE_PROV_COLLECTION         = 11,
        CERT_STORE_PROV_SYSTEM_REGISTRY_A  = 12,
        CERT_STORE_PROV_SYSTEM_REGISTRY_W  = 13,
        CERT_STORE_PROV_SYSTEM_REGISTRY    = CERT_STORE_PROV_SYSTEM_REGISTRY_W,
        CERT_STORE_PROV_PHYSICAL_W         = 14,
        CERT_STORE_PROV_PHYSICAL           = CERT_STORE_PROV_PHYSICAL_W,
        CERT_STORE_PROV_SMART_CARD_W       = 15,
        CERT_STORE_PROV_SMART_CARD         = CERT_STORE_PROV_SMART_CARD_W,
        CERT_STORE_PROV_LDAP_W             = 16,
        CERT_STORE_PROV_LDAP               = CERT_STORE_PROV_LDAP_W
    }
}
'@

$pkiInternalsTypes = @'
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Security;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using System.Text.RegularExpressions;

namespace Pki
{
    public static class Period
    {
        public static TimeSpan ToTimeSpan(byte[] value)
        {
            var period = BitConverter.ToInt64(value, 0); period /= -10000000;
            return TimeSpan.FromSeconds(period);
        }

        public static byte[] ToByteArray(TimeSpan value)
        {
            var period = value.TotalSeconds;
            period *= -10000000;
            return BitConverter.GetBytes((long)period);
        }
    }
}

namespace Pki.CATemplate
{
    /// <summary>
    /// 2.27 msPKI-Private-Key-Flag Attribute
    /// https://msdn.microsoft.com/en-us/library/cc226547.aspx
    /// </summary>
    [Flags]
    public enum PrivateKeyFlags
    {
        None = 0, //This flag indicates that attestation data is not required when creating the certificate request. It also instructs the server to not add any attestation OIDs to the issued certificate. For more details, see [MS-WCCE] section 3.2.2.6.2.1.4.5.7.
        RequireKeyArchival = 1, //This flag instructs the client to create a key archival certificate request, as specified in [MS-WCCE] sections 3.1.2.4.2.2.2.8 and 3.2.2.6.2.1.4.5.7.
        AllowKeyExport = 16, //This flag instructs the client to allow other applications to copy the private key to a .pfx file, as specified in [PKCS12], at a later time.
        RequireStrongProtection = 32, //This flag instructs the client to use additional protection for the private key.
        RequireAlternateSignatureAlgorithm = 64, //This flag instructs the client to use an alternate signature format. For more details, see [MS-WCCE] section 3.1.2.4.2.2.2.8.
        ReuseKeysRenewal = 128, //This flag instructs the client to use the same key when renewing the certificate.<35>
        UseLegacyProvider = 256, //This flag instructs the client to process the msPKI-RA-Application-Policies attribute as specified in section 2.23.1.<36>
        TrustOnUse = 512, //This flag indicates that attestation based on the user's credentials is to be performed. For more details, see [MS-WCCE] section 3.2.2.6.2.1.4.5.7.
        ValidateCert = 1024, //This flag indicates that attestation based on the hardware certificate of the Trusted Platform Module (TPM) is to be performed. For more details, see [MS-WCCE] section 3.2.2.6.2.1.4.5.7.
        ValidateKey = 2048, //This flag indicates that attestation based on the hardware key of the TPM is to be performed. For more details, see [MS-WCCE] section 3.2.2.6.2.1.4.5.7.
        Preferred = 4096, //This flag informs the client that it SHOULD include attestation data if it is capable of doing so when creating the certificate request. It also instructs the server that attestation may or may not be completed before any certificates can be issued. For more details, see [MS-WCCE] sections 3.1.2.4.2.2.2.8 and 3.2.2.6.2.1.4.5.7.
        Required = 8192, //This flag informs the client that attestation data is required when creating the certificate request. It also instructs the server that attestation must be completed before any certificates can be issued. For more details, see [MS-WCCE] sections 3.1.2.4.2.2.2.8 and 3.2.2.6.2.1.4.5.7.
        WithoutPolicy = 16384, //This flag instructs the server to not add any certificate policy OIDs to the issued certificate even though attestation SHOULD be performed. For more details, see [MS-WCCE] section 3.2.2.6.2.1.4.5.7.
        xxx = 0x000F0000
    }

    [Flags]
    public enum KeyUsage
    {
        DIGITAL_SIGNATURE = 0x80,
        NON_REPUDIATION = 0x40,
        KEY_ENCIPHERMENT = 0x20,
        DATA_ENCIPHERMENT = 0x10,
        KEY_AGREEMENT = 0x8,
        KEY_CERT_SIGN = 0x4,
        CRL_SIGN = 0x2,
        ENCIPHER_ONLY_KEY_USAGE = 0x1,
        DECIPHER_ONLY_KEY_USAGE = (0x80 << 8),
        NO_KEY_USAGE = 0x0
    }

    public enum KeySpec
    {
        KeyExchange = 1, //Keys used to encrypt/decrypt session keys
        Signature = 2 //Keys used to create and verify digital signatures.
    }

    /// <summary>
    /// 2.26 msPKI-Enrollment-Flag Attribute
    /// https://msdn.microsoft.com/en-us/library/cc226546.aspx
    /// </summary>
    [Flags]
    public enum EnrollmentFlags
    {
        None = 0,
        IncludeSymmetricAlgorithms = 1, //This flag instructs the client and server to include a Secure/Multipurpose Internet Mail Extensions (S/MIME) certificate extension, as specified in RFC4262, in the request and in the issued certificate.
        CAManagerApproval = 2, // This flag instructs the CA to put all requests in a pending state.
        KraPublish = 4, // This flag instructs the CA to publish the issued certificate to the key recovery agent (KRA) container in Active Directory.
        DsPublish = 8, // This flag instructs clients and CA servers to append the issued certificate to the userCertificate attribute, as specified in RFC4523, on the user object in Active Directory.
        AutoenrollmentCheckDsCert = 16, // This flag instructs clients not to do autoenrollment for a certificate based on this template if the user's userCertificate attribute (specified in RFC4523) in Active Directory has a valid certificate based on the same template.
        Autoenrollment = 32, //This flag instructs clients to perform autoenrollment for the specified template.
        ReenrollExistingCert = 64, //This flag instructs clients to sign the renewal request using the private key of the existing certificate.
        RequireUserInteraction = 256, // This flag instructs the client to obtain user consent before attempting to enroll for a certificate that is based on the specified template.
        RemoveInvalidFromStore = 1024, // This flag instructs the autoenrollment client to delete any certificates that are no longer needed based on the specific template from the local certificate storage.
        AllowEnrollOnBehalfOf = 2048, //This flag instructs the server to allow enroll on behalf of(EOBO) functionality.
        IncludeOcspRevNoCheck = 4096, // This flag instructs the server to not include revocation information and add the id-pkix-ocsp-nocheck extension, as specified in RFC2560 section 4.2.2.2.1, to the certificate that is issued. Windows Server 2003 - this flag is not supported.
        ReuseKeyTokenFull = 8192, //This flag instructs the client to reuse the private key for a smart card-based certificate renewal if it is unable to create a new private key on the card.Windows XP, Windows Server 2003 - this flag is not supported. NoRevocationInformation 16384 This flag instructs the server to not include revocation information in the issued certificate. Windows Server 2003, Windows Server 2008 - this flag is not supported.
        BasicConstraintsInEndEntityCerts = 32768, //This flag instructs the server to include Basic Constraints extension in the end entity certificates. Windows Server 2003, Windows Server 2008 - this flag is not supported.
        IgnoreEnrollOnReenrollment = 65536, //This flag instructs the CA to ignore the requirement for Enroll permissions on the template when processing renewal requests. Windows Server 2003, Windows Server 2008, Windows Server 2008 R2 - this flag is not supported.
        IssuancePoliciesFromRequest = 131072 //This flag indicates that the certificate issuance policies to be included in the issued certificate come from the request rather than from the template. The template contains a list of all of the issuance policies that the request is allowed to specify; if the request contains policies that are not listed in the template, then the request is rejected. Windows Server 2003, Windows Server 2008, Windows Server 2008 R2 - this flag is not supported.
    }

    /// <summary>
    /// 2.28 msPKI-Certificate-Name-Flag Attribute
    /// https://msdn.microsoft.com/en-us/library/cc226548.aspx
    /// </summary>
    [Flags]
    public enum NameFlags
    {
        EnrolleeSuppliesSubject = 1, //This flag instructs the client to supply subject information in the certificate request
        OldCertSuppliesSubjectAndAltName = 8, //This flag instructs the client to reuse values of subject name and alternative subject name extensions from an existing valid certificate when creating a certificate renewal request. Windows Server 2003, Windows Server 2008 - this flag is not supported.
        EnrolleeSuppluiesAltSubject = 65536, //This flag instructs the client to supply subject alternate name information in the certificate request.
        AltSubjectRequireDomainDNS = 4194304, //This flag instructs the CA to add the value of the requester's FQDN and NetBIOS name to the Subject Alternative Name extension of the issued certificate.
        AltSubjectRequireDirectoryGUID = 16777216, //This flag instructs the CA to add the value of the objectGUID attribute from the requestor's user object in Active Directory to the Subject Alternative Name extension of the issued certificate.
        AltSubjectRequireUPN = 33554432, //This flag instructs the CA to add the value of the UPN attribute from the requestor's user object in Active Directory to the Subject Alternative Name extension of the issued certificate.
        AltSubjectRequireEmail = 67108864, //This flag instructs the CA to add the value of the e-mail attribute from the requestor's user object in Active Directory to the Subject Alternative Name extension of the issued certificate.
        AltSubjectRequireDNS = 134217728, //This flag instructs the CA to add the value obtained from the DNS attribute of the requestor's user object in Active Directory to the Subject Alternative Name extension of the issued certificate.
        SubjectRequireDNSasCN = 268435456, //This flag instructs the CA to add the value obtained from the DNS attribute of the requestor's user object in Active Directory as the CN in the subject of the issued certificate.
        SubjectRequireEmail = 536870912, //This flag instructs the CA to add the value of the e-mail attribute from the requestor's user object in Active Directory as the subject of the issued certificate.
        SubjectRequireCommonName = 1073741824, //This flag instructs the CA to set the subject name to the requestor's CN from Active Directory.
        SubjectrequireDirectoryPath = -2147483648 //This flag instructs the CA to set the subject name to the requestor's distinguished name (DN) from Active Directory.
    }

    /// <summary>
    /// 2.4 flags Attribute
    /// https://msdn.microsoft.com/en-us/library/cc226550.aspx
    /// </summary>
    [Flags]
    public enum Flags
    {
        Undefined = 1, //Undefined.
        AddEmail = 2, //Reserved. All protocols MUST ignore this flag.
        Undefined2 = 4, //Undefined.
        DsPublish = 8, //Reserved. All protocols MUST ignore this flag.
        AllowKeyExport = 16, //Reserved. All protocols MUST ignore this flag.
        Autoenrollment = 32, //This flag indicates whether clients can perform autoenrollment for the specified template.
        MachineType = 64, //This flag indicates that this certificate template is for an end entity that represents a machine.
        IsCA = 128, //This flag indicates a certificate request for a CA certificate.
        AddTemplateName = 512, //This flag indicates that a certificate based on this section needs to include a template name certificate extension.
        DoNotPersistInDB = 1024, //This flag indicates that the record of a certificate request for a certificate that is issued need not be persisted by the CA. Windows Server 2003, Windows Server 2008 - this flag is not supported.
        IsCrossCA = 2048, //This flag indicates a certificate request for cross-certifying a certificate.
        IsDefault = 65536, //This flag indicates that the template SHOULD not be modified in any way.
        IsModified = 131072 //This flag indicates that the template MAY be modified if required.
    }
}

namespace Pki.Certificates
{
    public enum CertificateType
    {
        Cer,
        Pfx
    }

    public class CertificateInfo
    {
        private X509Certificate2 certificate;
        private byte[] rawContentBytes;


        public string ComputerName { get; set; }
        public string Location { get; set; }
        public string ServiceName { get; set; }
        public string Store { get; set; }
        public string Password { get; set; }


        public X509Certificate2 Certificate
        {
            get { return certificate; }
        }

        public List<string> DnsNameList
        {
            get
            {
                return ParseSujectAlternativeNames(Certificate).ToList();
            }
        }

        public string Thumbprint
        {
            get
            {
                return Certificate.Thumbprint;
            }
        }

        public byte[] CertificateBytes
        {
            get
            {
                return certificate.RawData;
            }
        }

        public byte[] RawContentBytes
        {
            get
            {
                return rawContentBytes;
            }
        }

        public CertificateInfo(X509Certificate2 certificate)
        {
            this.certificate = certificate;
            rawContentBytes = new byte[0];
        }

        public CertificateInfo(byte[] bytes)
        {
            rawContentBytes = bytes;
            certificate = new X509Certificate2(rawContentBytes);
        }

        public CertificateInfo(byte[] bytes, SecureString password)
        {
            rawContentBytes = bytes;
            certificate = new X509Certificate2(rawContentBytes, password, X509KeyStorageFlags.Exportable);
            Password = ConvertToString(password);
        }

        public CertificateInfo(string fileName)
        {
            rawContentBytes = File.ReadAllBytes(fileName);
            certificate = new X509Certificate2(rawContentBytes);
        }

        public CertificateInfo(string fileName, SecureString password)
        {
            rawContentBytes = File.ReadAllBytes(fileName);
            certificate = new X509Certificate2(rawContentBytes, password, X509KeyStorageFlags.Exportable);
            Password = ConvertToString(password);
        }

        public X509ContentType Type
        {
            get
            {
                if (rawContentBytes.Length > 0)
                    return X509Certificate2.GetCertContentType(rawContentBytes);
                else
                    return X509Certificate2.GetCertContentType(CertificateBytes);
            }
        }

        public static IEnumerable<string> ParseSujectAlternativeNames(X509Certificate2 cert)
        {
            Regex sanRex = new Regex(@"^DNS Name=(.*)", RegexOptions.Compiled | RegexOptions.CultureInvariant);

            var sanList = from X509Extension ext in cert.Extensions
                          where ext.Oid.FriendlyName.Equals("Subject Alternative Name", StringComparison.Ordinal)
                          let data = new AsnEncodedData(ext.Oid, ext.RawData)
                          let text = data.Format(true)
                          from line in text.Split(new char[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries)
                          let match = sanRex.Match(line)
                          where match.Success && match.Groups.Count > 0 && !string.IsNullOrEmpty(match.Groups[1].Value)
                          select match.Groups[1].Value;

            return sanList;
        }

        private string ConvertToString(SecureString s)
        {
            var bstr = System.Runtime.InteropServices.Marshal.SecureStringToBSTR(s);
            return System.Runtime.InteropServices.Marshal.PtrToStringAuto(bstr);
        }
    }
}
'@

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
#endregion .net Types

$ApplicationPolicies = @{
    # Remote Desktop
    'Remote Desktop' = '1.3.6.1.4.1.311.54.1.2'
    # Windows Update
    'Windows Update' = '1.3.6.1.4.1.311.76.6.1'
    # Windows Third Party Applicaiton Component
    'Windows Third Party Application Component' = '1.3.6.1.4.1.311.10.3.25'
    # Windows TCB Component
    'Windows TCB Component' = '1.3.6.1.4.1.311.10.3.23'
    # Windows Store
    'Windows Store' = '1.3.6.1.4.1.311.76.3.1'
    # Windows Software Extension verification
    ' Windows Software Extension Verification' = '1.3.6.1.4.1.311.10.3.26'
    # Windows RT Verification
    'Windows RT Verification' = '1.3.6.1.4.1.311.10.3.21'
    # Windows Kits Component
    'Windows Kits Component' = '1.3.6.1.4.1.311.10.3.20'
    # ROOT_PROGRAM_NO_OCSP_FAILOVER_TO_CRL
    'No OCSP Failover to CRL' = '1.3.6.1.4.1.311.60.3.3'
    # ROOT_PROGRAM_AUTO_UPDATE_END_REVOCATION
    'Auto Update End Revocation' = '1.3.6.1.4.1.311.60.3.2'
    # ROOT_PROGRAM_AUTO_UPDATE_CA_REVOCATION
    'Auto Update CA Revocation' = '1.3.6.1.4.1.311.60.3.1'
    # Revoked List Signer
    'Revoked List Signer' = '1.3.6.1.4.1.311.10.3.19'
    # Protected Process Verification
    'Protected Process Verification' = '1.3.6.1.4.1.311.10.3.24'
    # Protected Process Light Verification
    'Protected Process Light Verification' = '1.3.6.1.4.1.311.10.3.22'
    # Platform Certificate
    'Platform Certificate' = '2.23.133.8.2'
    # Microsoft Publisher
    'Microsoft Publisher' = '1.3.6.1.4.1.311.76.8.1'
    # Kernel Mode Code Signing
    'Kernel Mode Code Signing' = '1.3.6.1.4.1.311.6.1.1'
    # HAL Extension
    'HAL Extension' = '1.3.6.1.4.1.311.61.5.1'
    # Endorsement Key Certificate
    'Endorsement Key Certificate' = '2.23.133.8.1'
    # Early Launch Antimalware Driver
    'Early Launch Antimalware Driver' = '1.3.6.1.4.1.311.61.4.1'
    # Dynamic Code Generator
    'Dynamic Code Generator' = '1.3.6.1.4.1.311.76.5.1'
    # Domain Name System (DNS) Server Trust
    'DNS Server Trust' = '1.3.6.1.4.1.311.64.1.1'
    # Document Encryption
    'Document Encryption' = '1.3.6.1.4.1.311.80.1'
    # Disallowed List
    'Disallowed List' = '1.3.6.1.4.1.10.3.30'
    # Attestation Identity Key Certificate
    # System Health Authentication
    'System Health Authentication' = '1.3.6.1.4.1.311.47.1.1'
    # Smartcard Logon
    'IdMsKpScLogon' = '1.3.6.1.4.1.311.20.2.2'
    # Certificate Request Agent
    'ENROLLMENT_AGENT' = '1.3.6.1.4.1.311.20.2.1'
    # CTL Usage
    'AUTO_ENROLL_CTL_USAGE' = '1.3.6.1.4.1.311.20.1'
    # Private Key Archival
    'KP_CA_EXCHANGE' = '1.3.6.1.4.1.311.21.5'
    # Key Recovery Agent
    'KP_KEY_RECOVERY_AGENT' = '1.3.6.1.4.1.311.21.6'
    # Secure Email
    'PKIX_KP_EMAIL_PROTECTION' = '1.3.6.1.5.5.7.3.4'
    # IP Security End System
    'PKIX_KP_IPSEC_END_SYSTEM' = '1.3.6.1.5.5.7.3.5'
    # IP Security Tunnel Termination
    'PKIX_KP_IPSEC_TUNNEL' = '1.3.6.1.5.5.7.3.6'
    # IP Security User
    'PKIX_KP_IPSEC_USER' = '1.3.6.1.5.5.7.3.7'
    # Time Stamping
    'PKIX_KP_TIMESTAMP_SIGNING' = '1.3.6.1.5.5.7.3.8'
    # OCSP Signing
    'KP_OCSP_SIGNING' = '1.3.6.1.5.5.7.3.9'
    # IP security IKE intermediate
    'IPSEC_KP_IKE_INTERMEDIATE' = '1.3.6.1.5.5.8.2.2'
    # Microsoft Trust List Signing
    'KP_CTL_USAGE_SIGNING' = '1.3.6.1.4.1.311.10.3.1'
    # Microsoft Time Stamping
    'KP_TIME_STAMP_SIGNING' = '1.3.6.1.4.1.311.10.3.2'
    # Windows Hardware Driver Verification
    'WHQL_CRYPTO' = '1.3.6.1.4.1.311.10.3.5'
    # Windows System Component Verification
    'NT5_CRYPTO' = '1.3.6.1.4.1.311.10.3.6'
    # OEM Windows System Component Verification
    'OEM_WHQL_CRYPTO' = '1.3.6.1.4.1.311.10.3.7'
    # Embedded Windows System Component Verification
    'EMBEDDED_NT_CRYPTO' = '1.3.6.1.4.1.311.10.3.8'
    # Root List Signer
    'ROOT_LIST_SIGNER' = '1.3.6.1.4.1.311.10.3.9'
    # Qualified Subordination
    'KP_QUALIFIED_SUBORDINATION' = '1.3.6.1.4.1.311.10.3.10'
    # Key Recovery
    'KP_KEY_RECOVERY' = '1.3.6.1.4.1.311.10.3.11'
    # Document Signing
    'KP_DOCUMENT_SIGNING' = '1.3.6.1.4.1.311.10.3.12'
    # Lifetime Signing
    'KP_LIFETIME_SIGNING' = '1.3.6.1.4.1.311.10.3.13'
    'DRM' = '1.3.6.1.4.1.311.10.5.1'
    'DRM_INDIVIDUALIZATION' = '1.3.6.1.4.1.311.10.5.2'
    # Key Pack Licenses
    'LICENSES' = '1.3.6.1.4.1.311.10.6.1'
    # License Server Verification
    'LICENSE_SERVER' = '1.3.6.1.4.1.311.10.6.2'
    'Server Authentication' = '1.3.6.1.5.5.7.3.1' #The certificate can be used for OCSP authentication.
    KP_IPSEC_USER = '1.3.6.1.5.5.7.3.7' #The certificate can be used for an IPSEC user.
    'Code Signing' = '1.3.6.1.5.5.7.3.3' #The certificate can be used for signing code.
    'Client Authentication' = '1.3.6.1.5.5.7.3.2' #The certificate can be used for authenticating a client.
    KP_EFS = '1.3.6.1.4.1.311.10.3.4' #The certificate can be used to encrypt files by using the Encrypting File System.
    EFS_RECOVERY = '1.3.6.1.4.1.311.10.3.4.1' #The certificate can be used for recovery of documents protected by using Encrypting File System (EFS).
    DS_EMAIL_REPLICATION = '1.3.6.1.4.1.311.21.19' #The certificate can be used for Directory Service email replication.
    ANY_APPLICATION_POLICY = '1.3.6.1.4.1.311.10.12.1' #The applications that can use the certificate are not restricted.
}

$ExtendedKeyUsages = @{
    OldAuthorityKeyIdentifier = '.29.1'
    OldPrimaryKeyAttributes = '2.5.29.2'
    OldCertificatePolicies = '2.5.29.3'
    PrimaryKeyUsageRestriction = '2.5.29.4'
    SubjectDirectoryAttributes = '2.5.29.9'
    SubjectKeyIdentifier = '2.5.29.14'
    KeyUsage = '2.5.29.15'
    PrivateKeyUsagePeriod = '2.5.29.16'
    SubjectAlternativeName = '2.5.29.17'
    IssuerAlternativeName = '2.5.29.18'
    BasicConstraints = '2.5.29.19'
    CRLNumber = '2.5.29.20'
    Reasoncode = '2.5.29.21'
    HoldInstructionCode = '2.5.29.23'
    InvalidityDate = '2.5.29.24'
    DeltaCRLindicator = '2.5.29.27'
    IssuingDistributionPoint = '2.5.29.28'
    CertificateIssuer = '2.5.29.29'
    NameConstraints = '2.5.29.30'
    CRLDistributionPoints = '2.5.29.31'
    CertificatePolicies = '2.5.29.32'
    PolicyMappings = '2.5.29.33'
    AuthorityKeyIdentifier = '2.5.29.35'
    PolicyConstraints = '2.5.29.36'
    Extendedkeyusage = '2.5.29.37'
    FreshestCRL = '2.5.29.46'
    X509version3CertificateExtensionInhibitAny = '2.5.29.54'
}

#endregion Internals

#region Get-LabCertificate
function Get-LabCertificate
{

    [cmdletBinding(DefaultParameterSetName = 'FindCer')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'FindCer')]
        [Parameter(Mandatory = $true, ParameterSetName = 'FindPfx')]
        [string]$SearchString,

        [Parameter(Mandatory = $true, ParameterSetName = 'FindCer')]
        [Parameter(Mandatory = $true, ParameterSetName = 'FindPfx')]
        [System.Security.Cryptography.X509Certificates.X509FindType]$FindType,

        [Parameter(ParameterSetName = 'AllCer')]
        [Parameter(ParameterSetName = 'AllPfx')]
        [Parameter(ParameterSetName = 'FindCer')]
        [Parameter(ParameterSetName = 'FindPfx')]
        [System.Security.Cryptography.X509Certificates.CertStoreLocation]$Location,

        [Parameter(ParameterSetName = 'AllCer')]
        [Parameter(ParameterSetName = 'AllPfx')]
        [Parameter(ParameterSetName = 'FindCer')]
        [Parameter(ParameterSetName = 'FindPfx')]
        [System.Security.Cryptography.X509Certificates.StoreName]$Store,

        [Parameter(ParameterSetName = 'AllCer')]
        [Parameter(ParameterSetName = 'AllPfx')]
        [Parameter(ParameterSetName = 'FindCer')]
        [Parameter(ParameterSetName = 'FindPfx')]
        [string]$ServiceName,

        [Parameter(Mandatory = $true, ParameterSetName = 'AllCer')]
        [Parameter(Mandatory = $true, ParameterSetName = 'AllPfx')]
        [switch]$All,

        [Parameter(ParameterSetName = 'AllCer')]
        [Parameter(ParameterSetName = 'AllPfx')]
        [switch]$IncludeServices,

        [Parameter(Mandatory = $true, ParameterSetName = 'FindPfx')]
        [Parameter(Mandatory = $true, ParameterSetName = 'AllPfx')]
        [securestring]$Password = ('AL' | ConvertTo-SecureString -AsPlainText -Force),

        [Parameter(ParameterSetName = 'FindPfx')]
        [Parameter(ParameterSetName = 'AllPfx')]
        [switch]$ExportPrivateKey,

        [Parameter(Mandatory)]
        [string[]]$ComputerName
    )

    Write-LogFunctionEntry

    $variables = Get-Variable -Name PSBoundParameters
    $functions = Get-Command -Name Get-Certificate2, Sync-Parameter

    foreach ($computer in $ComputerName)
    {
        Invoke-LabCommand -ActivityName "Adding 'AutomatedLab.Common.dll'" -ComputerName $ComputerName -ScriptBlock {
            if ($PSEdition -eq 'core')
            {
                Add-Type -Path '/ALLibraries/core/AutomatedLab.Common.dll' -ErrorAction SilentlyContinue
            }
            elseif ([System.Environment]::OSVersion.Version -ge '6.3')
            {
                Add-Type -Path '/ALLibraries/full/AutomatedLab.Common.dll' -ErrorAction SilentlyContinue
            }
        } -NoDisplay

        Invoke-LabCommand -ActivityName 'Exporting certificates' -ComputerName $ComputerName -ScriptBlock {
            Sync-Parameter -Command (Get-Command -Name Get-Certificate2)
            Get-Certificate2 @ALBoundParameters

        } -Variable $variables -Function $functions -PassThru -NoDisplay
    }

    Write-LogFunctionExit
}
#endregion Get-LabCertificate

#region Add-LabCertificate
function Add-LabCertificate
{

    [cmdletBinding(DefaultParameterSetName = 'ByteArray')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'File')]
        [string]$Path,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ByteArray')]
        [byte[]]$RawContentBytes,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [System.Security.Cryptography.X509Certificates.StoreName]$Store,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [System.Security.Cryptography.X509Certificates.CertStoreLocation]$Location,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string]$ServiceName,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('CER', 'PFX')]
        [string]$CertificateType = 'CER',

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string]$Password = 'AL',

        [Parameter(Mandatory, ValueFromPipelineByPropertyName = $true)]
        [string[]]$ComputerName
    )

    begin
    {
        Write-LogFunctionEntry
    }

    process
    {
        $variables = Get-Variable -Name PSBoundParameters
        $functions = Get-Command -Name Add-Certificate2, Sync-Parameter

        Invoke-LabCommand -ActivityName "Adding 'AutomatedLab.Common.dll'" -ComputerName $ComputerName -ScriptBlock {
            if ($PSEdition -eq 'core')
            {
                Add-Type -Path '/ALLibraries/core/AutomatedLab.Common.dll' -ErrorAction SilentlyContinue
            }
            elseif ([System.Environment]::OSVersion.Version -ge '6.3')
            {
                Add-Type -Path '/ALLibraries/full/AutomatedLab.Common.dll' -ErrorAction SilentlyContinue
            }
        } -NoDisplay

        if ($Path)
        {
            $RawContentBytes = [System.IO.File]::ReadAllBytes($Path)
            $PSBoundParameters.Remove('Path')
            $PSBoundParameters.Add('RawContentBytes', $RawContentBytes)
        }

        Invoke-LabCommand -ActivityName 'Importing Cert file' -ComputerName $ComputerName -ScriptBlock {

            Sync-Parameter -Command (Get-Command -Name Add-Certificate2)
            Add-Certificate2 @ALBoundParameters | Out-Null

        } -Variable $variables -Function $functions -PassThru -NoDisplay

    }

    end
    {
        Write-LogFunctionExit
    }
}
#endregion Add-LabCertificate

#region New-LabCATemplate
function New-LabCATemplate
{

    [cmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TemplateName,

        [string]$DisplayName,

        [Parameter(Mandatory)]
        [string]$SourceTemplateName,

        [ValidateSet('EFS_RECOVERY', 'Auto Update CA Revocation', 'No OCSP Failover to CRL', 'OEM_WHQL_CRYPTO', 'Windows TCB Component', 'DNS Server Trust', 'Windows Third Party Application Component', 'ANY_APPLICATION_POLICY', 'KP_LIFETIME_SIGNING', 'Disallowed List', 'DS_EMAIL_REPLICATION', 'LICENSE_SERVER', 'KP_KEY_RECOVERY', 'Windows Kits Component', 'AUTO_ENROLL_CTL_USAGE', 'PKIX_KP_TIMESTAMP_SIGNING', 'Windows Update', 'Document Encryption', 'KP_CTL_USAGE_SIGNING', 'IPSEC_KP_IKE_INTERMEDIATE', 'PKIX_KP_IPSEC_TUNNEL', 'Code Signing', 'KP_KEY_RECOVERY_AGENT', 'KP_QUALIFIED_SUBORDINATION', 'Early Launch Antimalware Driver', 'Remote Desktop', 'WHQL_CRYPTO', 'EMBEDDED_NT_CRYPTO', 'System Health Authentication', 'DRM', 'PKIX_KP_EMAIL_PROTECTION', 'KP_TIME_STAMP_SIGNING', 'Protected Process Light Verification', 'Endorsement Key Certificate', 'KP_IPSEC_USER', 'PKIX_KP_IPSEC_END_SYSTEM', 'LICENSES', 'Protected Process Verification', 'IdMsKpScLogon', 'HAL Extension', 'KP_OCSP_SIGNING', 'Server Authentication', 'Auto Update End Revocation', 'KP_EFS', 'KP_DOCUMENT_SIGNING', 'Windows Store', 'Kernel Mode Code Signing', 'ENROLLMENT_AGENT', 'ROOT_LIST_SIGNER', 'Windows RT Verification', 'NT5_CRYPTO', 'Revoked List Signer', 'Microsoft Publisher', 'Platform Certificate', ' Windows Software Extension Verification', 'KP_CA_EXCHANGE', 'PKIX_KP_IPSEC_USER', 'Dynamic Code Generator', 'Client Authentication', 'DRM_INDIVIDUALIZATION')]
        [string[]]$ApplicationPolicy,

        [Pki.CATemplate.EnrollmentFlags]$EnrollmentFlags,

        [Pki.CATemplate.PrivateKeyFlags]$PrivateKeyFlags = 0,

        [Pki.CATemplate.KeyUsage]$KeyUsage = 0,

        [int]$Version = 2,

        [timespan]$ValidityPeriod,

        [timespan]$RenewalPeriod,

        [Parameter(Mandatory)]
        [string[]]$SamAccountName,

        [Parameter(Mandatory)]
        [string]$ComputerName
    )

    Write-LogFunctionEntry

    $computer = Get-LabVM -ComputerName $ComputerName
    if (-not $computer)
    {
        Write-Error "The given computer '$ComputerName' could not be found in the lab" -TargetObject $ComputerName
        return
    }

    $variables = Get-Variable -Name KeyUsage, ExtendedKeyUsages, ApplicationPolicies, pkiInternalsTypes, PSBoundParameters
    $functions = Get-Command -Name New-CATemplate, Add-CATemplateStandardPermission, Publish-CATemplate, Get-NextOid, Sync-Parameter, Find-CertificateAuthority

    Invoke-LabCommand -ActivityName "Duplicating CA template $SourceTemplateName -> $TemplateName" -ComputerName $computerName -ScriptBlock {
        Add-Type -TypeDefinition $pkiInternalsTypes

        $p = Sync-Parameter -Command (Get-Command -Name New-CATemplate) -Parameters $ALBoundParameters
        New-CATemplate @p -ErrorVariable e

        if (-not $e)
        {
            $p = Sync-Parameter -Command (Get-Command -Name Add-CATemplateStandardPermission) -Parameters $ALBoundParameters
            Add-CATemplateStandardPermission @p | Out-Null
        }
    } -Variable $variables -Function $functions -PassThru

    Sync-LabActiveDirectory -ComputerName (Get-LabVM -Role RootDC)

    Invoke-LabCommand -ActivityName "Publishing CA template $TemplateName" -ComputerName $ComputerName -ScriptBlock {

        $p = Sync-Parameter -Command (Get-Command -Name Publish-CATemplate, Find-CertificateAuthority) -Parameters $ALBoundParameters
        Publish-CATemplate @p

    } -Function $functions -Variable $variables
}
#endregion New-LabCATemplate

#region Test-LabCATemplate
function Test-LabCATemplate
{

    [cmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TemplateName,

        [Parameter(Mandatory)]
        [string]$ComputerName
    )

    Write-LogFunctionEntry

    $computer = Get-LabVM -ComputerName $ComputerName
    if (-not $computer)
    {
        Write-Error "The given computer '$ComputerName' could not be found in the lab" -TargetObject $ComputerName
        return
    }

    $variables = Get-Variable -Name PSBoundParameters
    $functions = Get-Command -Name Test-CATemplate, Sync-Parameter

    Invoke-LabCommand -ActivityName "Testing template $TemplateName" -ComputerName $ComputerName -ScriptBlock {

        $p = Sync-Parameter -Command (Get-Command -Name Test-CATemplate) -Parameters $ALBoundParameters
        Test-CATemplate @p

    } -Function $functions -Variable $variables -PassThru -NoDisplay
}
#endregion Test-LabCATemplate

#region Get-LabIssuingCA
function Get-LabIssuingCA
{

    [OutputType([AutomatedLab.Machine])]
    [cmdletBinding()]

    param(
        [string]$DomainName
    )

    $lab = Get-Lab

    if ($DomainName)
    {
        if ($DomainName -notin $lab.Domains.Name)
        {
            Write-Error "The domain '$DomainName' is not defined in the lab."
            return
        }

        $machines = (Get-LabVM -Role CaRoot, CaSubordinate) | Where-Object DomainName -eq $DomainName
    }
    else
    {
        $machines = (Get-LabVM -Role CaRoot, CaSubordinate)
    }

    if (-not $machines)
    {
        Write-Warning 'There is no Certificate Authority deployed in the lab. Cannot get an Issuing Certificate Authority.'
        return
    }

    $issuingCAs = Invoke-LabCommand -ComputerName $machines -ScriptBlock {
        Start-Service -Name CertSvc -ErrorAction SilentlyContinue
        $templates = certutil.exe -CATemplates
        if ($templates -like '*Machine*')
        {
            $env:COMPUTERNAME
        }
    } -PassThru -NoDisplay

    if (-not $issuingCAs)
    {
        Write-Error 'There was no issuing CA found'
        return
    }

    Get-LabVM -ComputerName $issuingCAs | ForEach-Object {
        $caName = Invoke-LabCommand -ComputerName $_ -ScriptBlock { ((certutil -config $args[0] -ping)[1] -split '"')[1] } -ArgumentList $_.Name -PassThru -NoDisplay

        $_ | Add-Member -Name CaName -MemberType NoteProperty -Value $caName -Force
        $_ | Add-Member -Name CaPath -MemberType ScriptProperty -Value { $this.FQDN + '\' + $this.CaName } -Force
        $_
    }
}
#endregion Get-LabIssuingCA

#region Request-LabCertificate
function Request-LabCertificate
{

    [CmdletBinding()]
    param (
        [Parameter(Mandatory, HelpMessage = 'Please enter the subject beginning with CN=')]
        [ValidatePattern('CN=')]
        [string]$Subject,

        [Parameter(HelpMessage = 'Please enter the SAN domains as a comma separated list')]
        [string[]]$SAN,

        [Parameter(HelpMessage = 'Please enter the Online Certificate Authority')]
        [string]$OnlineCA,

        [Parameter(Mandatory, HelpMessage = 'Please enter the Online Certificate Authority')]
        [string]$TemplateName,

        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [switch]$PassThru
    )

    Write-LogFunctionEntry

    $computer = Get-LabVM -ComputerName $ComputerName

    if (-not $computer.IsDomainJoined -and -not $OnlineCA)
    {
        Write-Error "Requesting a certificate from a non-domain joined machine '$ComputerName' requires the parameter OnlineCA to be used"
        return
    }
    if ($OnlineCA)
    {
        $onlineCAVM = Get-LabVM -ComputerName $OnlineCA
    }
    else
    {
        $onlineCAVM = Get-LabIssuingCA -DomainName (Get-LabVM -ComputerName $ComputerName).DomainName
    }

    # Especially on Azure, the CertSrv was sometimes stopped for no apparent reason
    Invoke-LabCommand -ComputerName $onlineCAVM -ScriptBlock { Start-Service CertSvc }

    #machine was found so only the machine name was given. Get the full CA path.
    if ($onlineCAVM)
    {
        #$OnlineCA = Get-LabIssuingCA | Where-Object Name -eq $OnlineCA | Select-Object -ExpandProperty CaPath
        $PSBoundParameters.OnlineCA = (Get-LabIssuingCA | Where-Object Name -eq $OnlineCA).CaPath
    }

    $variables = Get-Variable -Name PSBoundParameters
    $functions = Get-Command -Name Get-CATemplate, Request-Certificate, Find-CertificateAuthority, Sync-Parameter

    foreach ($computer in $ComputerName)
    {
        Invoke-LabCommand -ActivityName "Requesting certificate for template '$TemplateName'" -ComputerName $computer -ScriptBlock {

            Sync-Parameter -Command (Get-Command -Name Request-Certificate)
            Request-Certificate @ALBoundParameters

        } -Variable $variables -Function $functions -PassThru:$PassThru
    }

    Write-LogFunctionExit
}
#endregion Request-LabCertificate

#region Install-LabCA
function Install-LabCA
{

    [cmdletBinding()]
    param ([switch]$CreateCheckPoints)

    Write-LogFunctionEntry

    $roles = [AutomatedLab.Roles]::CaRoot -bor [AutomatedLab.Roles]::CaSubordinate

    $lab = Get-Lab
    if (-not $lab.Machines)
    {
        Write-LogFunctionExitWithError -Message 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }

    $machines = Get-LabVM -Role CaRoot, CaSubordinate
    if (-not $machines)
    {
        Write-ScreenInfo -Message 'There is no machine(s) with CA role' -Type Warning
        return
    }

    if (-not (Get-LabVM -Role CaRoot))
    {
        Write-ScreenInfo -Message 'Subordinate CA(s) defined but lab has no Root CA(s) defined. Skipping installation of CA(s).' -Type Error
        return
    }

    if ((Get-LabVM -Role CaRoot).Name)
    {
        Write-ScreenInfo -Message "Machines with Root CA role to be installed: '$((Get-LabVM -Role CaRoot).Name -join ', ')'" -TaskStart
    }

    #Bring the RootCA server online and start installing
    Write-ScreenInfo -Message 'Waiting for machines to start up' -NoNewline

    Start-LabVM -RoleName CaRoot, CaSubordinate -Wait -ProgressIndicator 15

    $caRootMachines = Get-LabVM -Role CaRoot -IsRunning
    if ($caRootMachines.Count -ne (Get-LabVM -Role CaRoot).Count)
    {
        Write-Error 'Not all machines of type Root CA could be started, aborting the installation'
        return
    }

    $installSequence = 0
    $jobs = @()
    foreach ($caRootMachine in $caRootMachines)
    {
        $caFeature = Invoke-LabCommand -ComputerName $caRootMachine -ActivityName "Check if CA is already installed on '$caRootMachine'" -ScriptBlock { (Get-WindowsFeature -Name 'ADCS-Cert-Authority') } -PassThru -NoDisplay
        if ($caFeature.Installed)
        {
            Write-ScreenInfo -Message "Root CA '$caRootMachine' is already installed" -Type Warning
        }
        else
        {
            $jobs += Install-LabCAMachine -Machine $caRootMachine -PassThru -PreDelaySeconds ($installSequence++*30)
        }
    }

    if ($jobs)
    {
        Write-ScreenInfo -Message 'Waiting for Root CA(s) to complete installation' -NoNewline

        Wait-LWLabJob -Job $jobs -ProgressIndicator 10 -NoDisplay

        Write-PSFMessage -Message "Getting certificates from Root CA servers and placing them in '<labfolder>\Certs' on host machine"
        Get-LabVM -Role CaRoot | Get-LabCAInstallCertificates

        Write-ScreenInfo -Message 'Publishing certificates from CA servers to all online machines' -NoNewLine
        $jobs = Publish-LabCAInstallCertificates -PassThru
        Wait-LWLabJob -Job $jobs -ProgressIndicator 20 -Timeout 30 -NoNewLine -NoDisplay

        Write-PSFMessage -Message 'Waiting for all running machines to be contactable'
        Wait-LabVM -ComputerName (Get-LabVM -All -IsRunning) -ProgressIndicator 20 -NoNewLine

        Write-PSFMessage -Message 'Invoking a GPUpdate on all running machines'
        $jobs = Invoke-LabCommand -ActivityName 'GPUpdate after Root CA install' -ComputerName (Get-LabVM -All -IsRunning) -ScriptBlock {
            gpupdate.exe /force
        } -AsJob -PassThru -NoDisplay
        Wait-LWLabJob -Job $jobs -ProgressIndicator 20 -Timeout 30 -NoDisplay
    }

    Write-ScreenInfo -Message 'Finished installation of Root CAs' -TaskEnd

    #If any Subordinate CA servers to install, bring these online and start installing
    if ($machines | Where-Object { $_.Roles.Name -eq ([AutomatedLab.Roles]::CaSubordinate) })
    {
        $caSubordinateMachines = Get-LabVM -Role CaSubordinate -IsRunning
        if ($caSubordinateMachines.Count -ne (Get-LabVM -Role CaSubordinate).Count)
        {
            Write-Error 'Not all machines of type CaSubordinate could be started, aborting the installation'
            return
        }

        Write-ScreenInfo -Message "Machines with Subordinate CA role to be installed: '$($caSubordinateMachines -join ', ')'" -TaskStart


        Write-ScreenInfo -Message 'Waiting for machines to start up' -NoNewline
        Wait-LabVM -ComputerName (Get-LabVM -Role CaSubordinate).Name -ProgressIndicator 10

        $installSequence = 0
        $jobs = @()
        foreach ($caSubordinateMachine in $caSubordinateMachines)
        {
            $caFeature = Invoke-LabCommand -ComputerName $caSubordinateMachine -ActivityName "Check if CA is already installed on '$caSubordinateMachine'" -ScriptBlock { (Get-WindowsFeature -Name 'ADCS-Cert-Authority') } -PassThru -NoDisplay
            if ($caFeature.Installed)
            {
                Write-ScreenInfo -Message "Subordinate CA '$caSubordinateMachine' is already installed" -Type Warning
            }
            else
            {
                $jobs += Install-LabCAMachine -Machine $caSubordinateMachine -PassThru -PreDelaySeconds ($installSequence++ * 30)
            }
        }

        if ($Jobs)
        {
            Write-ScreenInfo -Message 'Waiting for Subordinate CA(s) to complete installation' -NoNewline

            Start-LabVM -StartNextMachines 1

            Wait-LWLabJob -Job $jobs -ProgressIndicator 20 -NoNewLine -NoDisplay

            Write-PSFMessage -Message "- Getting certificates from CA servers and placing them in '<labfolder>\Certs' on host machine"
            Get-LabVM -Role CaRoot, CaSubordinate | Get-LabCAInstallCertificates

            Write-PSFMessage -Message '- Publishing certificates from Subordinate CA servers to all online machines'
            $jobs = Publish-LabCAInstallCertificates -PassThru
            Wait-LWLabJob -Job $jobs -ProgressIndicator 20 -Timeout 30 -NoNewLine -NoDisplay

            Write-PSFMessage -Message 'Invoking a GPUpdate on all machines that are online'
            $jobs = Invoke-LabCommand -ComputerName (Get-LabVM -All -IsRunning) -ActivityName 'GPUpdate after Root CA install' -NoDisplay -ScriptBlock { gpupdate.exe /force } -AsJob -PassThru
            Wait-LWLabJob -Job $jobs -ProgressIndicator 20 -Timeout 30 -NoDisplay
        }

        Invoke-LabCommand -ComputerName $caRootMachines -NoDisplay -ScriptBlock {
            certutil.exe -setreg ca\PolicyModules\CertificateAuthority_MicrosoftDefault.Policy\RequestDisposition 101
            Restart-Service -Name CertSvc
        }

        Write-ScreenInfo -Message 'Finished installation of Subordinate CAs' -TaskEnd
    }


    Write-LogFunctionExit
}
#endregion Install-LabCA

#region Install-LabCAMachine
function Install-LabCAMachine
{

    [CmdletBinding()]

    param (
        [Parameter(Mandatory)]
        [AutomatedLab.Machine]$Machine,

        [int]$PreDelaySeconds,

        [switch]$PassThru
    )

    Write-LogFunctionEntry

    Write-PSFMessage -Message '****************************************************'
    Write-PSFMessage -Message "Starting installation of machine: $($machine.name)"
    Write-PSFMessage -Message '****************************************************'

    $role = $machine.Roles | Where-Object { $_.Name -eq ([AutomatedLab.Roles]::CaRoot) -or $_.Name -eq ([AutomatedLab.Roles]::CaSubordinate) }

    $param = [ordered]@{ }

    #region - Locate admin username and password for machine
    if ($machine.IsDomainJoined)
    {
        $domain = $lab.Domains | Where-Object { $_.Name -eq $machine.DomainName }

        $param.Add('UserName', ('{0}\{1}' -f $domain.Name, $domain.Administrator.UserName))
        $param.Add('Password', $domain.Administrator.Password)

        $rootDc = Get-LabVM -Role RootDC | Where-Object DomainName -eq $machine.DomainName
        if ($rootDc) #if there is a root domain controller in the same domain as the machine
        {
            $rootDomain = (Get-Lab).Domains | Where-Object Name -eq $rootDc.DomainName
            $rootDomainNetBIOSName = ($rootDomain.Name -split '\.')[0]
        }
        else #else the machine is in a child domain and the parent domain need to be used for the query
        {
            $rootDomain = $lab.GetParentDomain($machine.DomainName)
            $rootDomainNetBIOSName = ($rootDomain.Name -split '\.')[0]
            $rootDc = Get-LabVM -Role RootDC | Where-Object DomainName -eq $rootDomain
        }

        $param.Add('ForestAdminUserName', ('{0}\{1}' -f $rootDomainNetBIOSName, $rootDomain.Administrator.UserName))
        $param.Add('ForestAdminPassword', $rootDomain.Administrator.Password)

        Write-Debug -Message "Machine                   : $($machine.name)"
        Write-Debug -Message "Machine Domain            : $($machine.DomainName)"
        Write-Debug -Message "Username for job          : $($param.username)"
        Write-Debug -Message "Password for job          : $($param.Password)"
        Write-Debug -Message "ForestAdmin Username      : $($param.ForestAdminUserName)"
        Write-Debug -Message "ForestAdmin Password      : $($param.ForestAdminPassword)"
    }
    else
    {
        $param.Add('UserName', ('{0}\{1}' -f $machine.Name, $machine.InstallationUser.UserName))
        $param.Add('Password', $machine.InstallationUser.Password)
    }
    $param.Add('ComputerName', $Machine.Name)
    #endregion



    #region - Determine DNS name for machine. This is used when installing Enterprise CAs
    $caDNSName = $Machine.Name
    if ($Machine.DomainName) { $caDNSName += ('.' + $Machine.DomainName) }

    if ($Machine.DomainName)
    {
        $param.Add('DomainName', $Machine.DomainName)
    }
    else
    {
        $param.Add('DomainName', '')
    }


    if ($role.Name -eq 'CaSubordinate')
    {
        if (!($role.Properties.ContainsKey('ParentCA'))) { $param.Add('ParentCA', '<auto>') }
        else { $param.Add('ParentCA', $role.Properties.ParentCA) }
        if (!($role.Properties.ContainsKey('ParentCALogicalName'))) { $param.Add('ParentCALogicalName', '<auto>') }
        else { $param.Add('ParentCALogicalName', $role.Properties.ParentCALogicalName) }
    }

    if (!($role.Properties.ContainsKey('CACommonName'))) { $param.Add('CACommonName', '<auto>') }
    else { $param.Add('CACommonName', $role.Properties.CACommonName) }
    if (!($role.Properties.ContainsKey('CAType'))) { $param.Add('CAType', '<auto>') }
    else { $param.Add('CAType', $role.Properties.CAType) }
    if (!($role.Properties.ContainsKey('KeyLength'))) { $param.Add('KeyLength', '4096') }
    else { $param.Add('KeyLength', $role.Properties.KeyLength) }

    if (!($role.Properties.ContainsKey('CryptoProviderName'))) { $param.Add('CryptoProviderName', 'RSA#Microsoft Software Key Storage Provider') }
    else { $param.Add('CryptoProviderName', $role.Properties.CryptoProviderName) }
    if (!($role.Properties.ContainsKey('HashAlgorithmName'))) { $param.Add('HashAlgorithmName', 'SHA256') }
    else { $param.Add('HashAlgorithmName', $role.Properties.HashAlgorithmName) }


    if (!($role.Properties.ContainsKey('DatabaseDirectory'))) { $param.Add('DatabaseDirectory', '<auto>') }
    else { $param.Add('DatabaseDirectory', $role.Properties.DatabaseDirectory) }
    if (!($role.Properties.ContainsKey('LogDirectory'))) { $param.Add('LogDirectory', '<auto>') }
    else { $param.Add('LogDirectory', $role.Properties.LogDirectory) }

    if (!($role.Properties.ContainsKey('ValidityPeriod'))) { $param.Add('ValidityPeriod', '<auto>') }
    else { $param.Add('ValidityPeriod', $role.Properties.ValidityPeriod) }
    if (!($role.Properties.ContainsKey('ValidityPeriodUnits'))) { $param.Add('ValidityPeriodUnits', '<auto>') }
    else { $param.Add('ValidityPeriodUnits', $role.Properties.ValidityPeriodUnits) }

    if (!($role.Properties.ContainsKey('CertsValidityPeriod'))) { $param.Add('CertsValidityPeriod', '<auto>') }
    else { $param.Add('CertsValidityPeriod', $role.Properties.CertsValidityPeriod) }
    if (!($role.Properties.ContainsKey('CertsValidityPeriodUnits'))) { $param.Add('CertsValidityPeriodUnits', '<auto>') }
    else { $param.Add('CertsValidityPeriodUnits', $role.Properties.CertsValidityPeriodUnits) }
    if (!($role.Properties.ContainsKey('CRLPeriod'))) { $param.Add('CRLPeriod', '<auto>') }
    else { $param.Add('CRLPeriod', $role.Properties.CRLPeriod) }
    if (!($role.Properties.ContainsKey('CRLPeriodUnits'))) { $param.Add('CRLPeriodUnits', '<auto>') }
    else { $param.Add('CRLPeriodUnits', $role.Properties.CRLPeriodUnits) }
    if (!($role.Properties.ContainsKey('CRLOverlapPeriod'))) { $param.Add('CRLOverlapPeriod', '<auto>') }
    else { $param.Add('CRLOverlapPeriod', $role.Properties.CRLOverlapPeriod) }
    if (!($role.Properties.ContainsKey('CRLOverlapUnits'))) { $param.Add('CRLOverlapUnits', '<auto>') }
    else { $param.Add('CRLOverlapUnits', $role.Properties.CRLOverlapUnits) }
    if (!($role.Properties.ContainsKey('CRLDeltaPeriod'))) { $param.Add('CRLDeltaPeriod', '<auto>') }
    else { $param.Add('CRLDeltaPeriod', $role.Properties.CRLDeltaPeriod) }
    if (!($role.Properties.ContainsKey('CRLDeltaPeriodUnits'))) { $param.Add('CRLDeltaPeriodUnits', '<auto>') }
    else { $param.Add('CRLDeltaPeriodUnits', $role.Properties.CRLDeltaPeriodUnits) }

    if (!($role.Properties.ContainsKey('UseLDAPAIA'))) { $param.Add('UseLDAPAIA', '<auto>') }
    else { $param.Add('UseLDAPAIA', $role.Properties.UseLDAPAIA) }
    if (!($role.Properties.ContainsKey('UseHTTPAIA'))) { $param.Add('UseHTTPAIA', '<auto>') }
    else { $param.Add('UseHTTPAIA', $role.Properties.UseHTTPAIA) }
    if (!($role.Properties.ContainsKey('AIAHTTPURL01'))) { $param.Add('AIAHTTPURL01', '<auto>') }
    else { $param.Add('AIAHTTPURL01', $role.Properties.AIAHTTPURL01) }
    if (!($role.Properties.ContainsKey('AIAHTTPURL02'))) { $param.Add('AIAHTTPURL02', '<auto>') }
    else { $param.Add('AIAHTTPURL02', $role.Properties.AIAHTTPURL02) }
    if (!($role.Properties.ContainsKey('AIAHTTPURL01UploadLocation'))) { $param.Add('AIAHTTPURL01UploadLocation', '') }
    else { $param.Add('AIAHTTPURL01UploadLocation', $role.Properties.AIAHTTPURL01UploadLocation) }
    if (!($role.Properties.ContainsKey('AIAHTTPURL02UploadLocation'))) { $param.Add('AIAHTTPURL02UploadLocation', '') }
    else { $param.Add('AIAHTTPURL02UploadLocation', $role.Properties.AIAHTTPURL02UploadLocation) }

    if (!($role.Properties.ContainsKey('UseLDAPCRL'))) { $param.Add('UseLDAPCRL', '<auto>') }
    else { $param.Add('UseLDAPCRL', $role.Properties.UseLDAPCRL) }
    if (!($role.Properties.ContainsKey('UseHTTPCRL'))) { $param.Add('UseHTTPCRL', '<auto>') }
    else { $param.Add('UseHTTPCRL', $role.Properties.UseHTTPCRL) }
    if (!($role.Properties.ContainsKey('CDPHTTPURL01'))) { $param.Add('CDPHTTPURL01', '<auto>') }
    else { $param.Add('CDPHTTPURL01', $role.Properties.CDPHTTPURL01) }
    if (!($role.Properties.ContainsKey('CDPHTTPURL02'))) { $param.Add('CDPHTTPURL02', '<auto>') }
    else { $param.Add('CDPHTTPURL02', $role.Properties.CDPHTTPURL02) }
    if (!($role.Properties.ContainsKey('CDPHTTPURL01UploadLocation'))) { $param.Add('CDPHTTPURL01UploadLocation', '') }
    else { $param.Add('CDPHTTPURL01UploadLocation', $role.Properties.CDPHTTPURL01UploadLocation) }
    if (!($role.Properties.ContainsKey('CDPHTTPURL02UploadLocation'))) { $param.Add('CDPHTTPURL02UploadLocation', '') }
    else { $param.Add('CDPHTTPURL02UploadLocation', $role.Properties.CDPHTTPURL02UploadLocation) }

    if (!($role.Properties.ContainsKey('InstallWebEnrollment'))) { $param.Add('InstallWebEnrollment', '<auto>') }
    else { $param.Add('InstallWebEnrollment', $role.Properties.InstallWebEnrollment) }
    if (!($role.Properties.ContainsKey('InstallWebRole'))) { $param.Add('InstallWebRole', '<auto>') }
    else { $param.Add('InstallWebRole', $role.Properties.InstallWebRole) }

    if (!($role.Properties.ContainsKey('CPSURL'))) { $param.Add('CPSURL', 'http://' + $caDNSName + '/cps/cps.html') }
    else { $param.Add('CPSURL', $role.Properties.CPSURL) }
    if (!($role.Properties.ContainsKey('CPSText'))) { $param.Add('CPSText', 'Certification Practice Statement') }
    else { $param.Add('CPSText', $($role.Properties.CPSText)) }

    if (!($role.Properties.ContainsKey('InstallOCSP'))) { $param.Add('InstallOCSP', '<auto>') }
    else { $param.Add('InstallOCSP', ($role.Properties.InstallOCSP -like '*Y*')) }
    if (!($role.Properties.ContainsKey('OCSPHTTPURL01'))) { $param.Add('OCSPHTTPURL01', '<auto>') }
    else { $param.Add('OCSPHTTPURL01', $role.Properties.OCSPHTTPURL01) }
    if (!($role.Properties.ContainsKey('OCSPHTTPURL02'))) { $param.Add('OCSPHTTPURL02', '<auto>') }
    else { $param.Add('OCSPHTTPURL02', $role.Properties.OCSPHTTPURL02) }

    if (-not $role.Properties.ContainsKey('DoNotLoadDefaultTemplates'))
    {
        $param.Add('DoNotLoadDefaultTemplates', '<auto>')
    }
    else
    {
        $value = if ($role.Properties.DoNotLoadDefaultTemplates -eq 'Yes') { $true } else { $false }
        $param.Add('DoNotLoadDefaultTemplates', $value)
    }

    #region - Check if any unknown parameter name was passed
    $knownParameters = @()
    $knownParameters += 'ParentCA' #(only valid for Subordinate CA. Ignored for Root CAs)
    $knownParameters += 'ParentCALogicalName' #(only valid for Subordinate CAs. Ignored for Root CAs)
    $knownParameters += 'CACommonName'
    $knownParameters += 'CAType'
    $knownParameters += 'KeyLength'
    $knownParameters += 'CryptoProviderName'
    $knownParameters += 'HashAlgorithmName'
    $knownParameters += 'DatabaseDirectory'
    $knownParameters += 'LogDirectory'
    $knownParameters += 'ValidityPeriod'
    $knownParameters += 'ValidityPeriodUnits'
    $knownParameters += 'CertsValidityPeriod'
    $knownParameters += 'CertsValidityPeriodUnits'
    $knownParameters += 'CRLPeriod'
    $knownParameters += 'CRLPeriodUnits'
    $knownParameters += 'CRLOverlapPeriod'
    $knownParameters += 'CRLOverlapUnits'
    $knownParameters += 'CRLDeltaPeriod'
    $knownParameters += 'CRLDeltaPeriodUnits'
    $knownParameters += 'UseLDAPAIA'
    $knownParameters += 'UseHTTPAIA'
    $knownParameters += 'AIAHTTPURL01'
    $knownParameters += 'AIAHTTPURL02'
    $knownParameters += 'AIAHTTPURL01UploadLocation'
    $knownParameters += 'AIAHTTPURL02UploadLocation'
    $knownParameters += 'UseLDAPCRL'
    $knownParameters += 'UseHTTPCRL'
    $knownParameters += 'CDPHTTPURL01'
    $knownParameters += 'CDPHTTPURL02'
    $knownParameters += 'CDPHTTPURL01UploadLocation'
    $knownParameters += 'CDPHTTPURL02UploadLocation'
    $knownParameters += 'InstallWebEnrollment'
    $knownParameters += 'InstallWebRole'
    $knownParameters += 'CPSURL'
    $knownParameters += 'CPSText'
    $knownParameters += 'InstallOCSP'
    $knownParameters += 'OCSPHTTPURL01'
    $knownParameters += 'OCSPHTTPURL02'
    $knownParameters += 'DoNotLoadDefaultTemplates'
    $knownParameters += 'PreDelaySeconds'
    $unkownParFound = $false
    foreach ($keySet in $role.Properties.GetEnumerator())
    {
        if ($keySet.Key -cnotin $knownParameters)
        {
            Write-ScreenInfo -Message "Parameter name '$($keySet.Key)' is unknown/ignored)" -Type Warning
            $unkownParFound = $true
        }
    }
    if ($unkownParFound)
    {
        Write-ScreenInfo -Message 'Valid parameter names are:' -Type Warning
        Foreach ($name in ($knownParameters.GetEnumerator()))
        {
            Write-ScreenInfo -Message "  $($name)" -Type Warning
        }
        Write-ScreenInfo -Message 'NOTE that all parameter names are CASE SENSITIVE!' -Type Warning
    }
    #endregion - Check if any unknown parameter names was passed

    #endregion - Parameters


    #region - Parameters debug
    Write-Debug -Message '---------------------------------------------------------------------------------------'
    Write-Debug -Message "Parameters for $($machine.name)"
    Write-Debug -Message '---------------------------------------------------------------------------------------'
    if ($machine.Roles.Properties.GetEnumerator().Count)
    {
        foreach ($r in $machine.Roles)
        {
            if (([AutomatedLab.Roles]$r.Name -band $roles) -ne 0) #if this is a CA role
            {
                foreach ($key in ($r.Properties.GetEnumerator() | Sort-Object -Property Key))
                {
                    Write-Debug -Message "  $($key.Key.PadRight(27)) $($key.Value)"
                }
            }
        }
    }
    else
    {
        Write-Debug -message '  No parameters specified'
    }
    Write-Debug -Message '---------------------------------------------------------------------------------------'
    #endregion - Parameters debug


    #region ----- Input validation (raw values) -----
    if ($role.Properties.ContainsKey('CACommonName') -and ($param.CACommonName.Length -gt 37))
    {
        Write-Error -Message "CACommonName cannot be longer than 37 characters. Specified value is: '$($param.CACommonName)'"; return
    }

    if ($role.Properties.ContainsKey('CACommonName') -and ($param.CACommonName.Length -lt 1))
    {
        Write-Error -Message "CACommonName cannot be blank. Specified value is: '$($param.CACommonName)'"; return
    }

    if ($role.Name -eq 'CaRoot')
    {
        if (-not ($param.CAType -in 'EnterpriseRootCA', 'StandAloneRootCA', '<auto>'))
        {
            Write-Error -Message "CAType needs to be 'EnterpriseRootCA' or 'StandAloneRootCA' when role is CaRoot. Specified value is: '$param.CAType'"; return
        }
    }

    if ($role.Name -eq 'CaSubordinate')
    {
        if (-not ($param.CAType -in 'EnterpriseSubordinateCA', 'StandAloneSubordinateCA', '<auto>'))
        {
            Write-Error -Message "CAType needs to be 'EnterpriseSubordinateCA' or 'StandAloneSubordinateCA' when role is CaSubordinate. Specified value is: '$param.CAType'"; return
        }
    }


    $availableCombinations = @()
    $availableCombinations += @{CryptoProviderName='Microsoft Base SMart Card Crypto Provider';           HashAlgorithmName='sha1','md2','md4','md5';                           KeyLength='1024','2048','4096'}
    $availableCombinations += @{CryptoProviderName='Microsoft Enhanced Cryptographic Provider 1.0';       HashAlgorithmName='sha1','md2','md4','md5';                           KeyLength='512','1024','2048','4096'}
    $availableCombinations += @{CryptoProviderName='ECDSA_P256#Microsoft Smart Card Key Storage Provider';HashAlgorithmName='sha256','sha384','sha512','sha1';                  KeyLength='256'}
    $availableCombinations += @{CryptoProviderName='ECDSA_P521#Microsoft Smart Card Key Storage Provider';HashAlgorithmName='sha256','sha384','sha512','sha1';                  KeyLength='521'}
    $availableCombinations += @{CryptoProviderName='RSA#Microsoft Software Key Storage Provider';         HashAlgorithmName='sha256','sha384','sha512','sha1','md5','md4','md2';KeyLength='512','1024','2048','4096'}
    $availableCombinations += @{CryptoProviderName='Microsoft Base Cryptographic Provider v1.0';          HashAlgorithmName='sha1','md2','md4','md5';                           KeyLength='512','1024','2048','4096'}
    $availableCombinations += @{CryptoProviderName='ECDSA_P521#Microsoft Software Key Storage Provider';  HashAlgorithmName='sha256','sha384','sha512','sha1';                  KeyLength='521'}
    $availableCombinations += @{CryptoProviderName='ECDSA_P256#Microsoft Software Key Storage Provider';  HashAlgorithmName='sha256','sha384','sha512','sha1';                  KeyLength='256';}
    $availableCombinations += @{CryptoProviderName='Microsoft Strong Cryptographic Provider';             HashAlgorithmName='sha1','md2','md4','md5';                           KeyLength='512','1024','2048','4096';}
    $availableCombinations += @{CryptoProviderName='ECDSA_P384#Microsoft Software Key Storage Provider';  HashAlgorithmName='sha256','sha384','sha512','sha1';                  KeyLength='384'}
    $availableCombinations += @{CryptoProviderName='Microsoft Base DSS Cryptographic Provider';           HashAlgorithmName='sha1';                                             KeyLength='512','1024'}
    $availableCombinations += @{CryptoProviderName='RSA#Microsoft Smart Card Key Storage Provider';       HashAlgorithmName='sha256','sha384','sha512','sha1','md5','md4','md2';KeyLength='1024','2048','4096'}
    $availableCombinations += @{CryptoProviderName='DSA#Microsoft Software Key Storage Provider';         HashAlgorithmName='sha1';                                             KeyLength='512','1024','2048','4096'}
    $availableCombinations += @{CryptoProviderName='ECDSA_P384#Microsoft Smart Card Key Storage Provider';HashAlgorithmName='sha256','sha384','sha512','sha1';                  KeyLength='384'}

    $combination = $availableCombinations | Where-Object {$_.CryptoProviderName -eq $param.CryptoProviderName}

    if (-not ($param.CryptoProviderName -in $combination.CryptoProviderName))
    {
        Write-Error -Message "CryptoProviderName '$($param.CryptoProviderName)' is unknown. `nList of valid options for CryptoProviderName:`n  $($availableCombinations.CryptoProviderName -join "`n  ")"; return
    }
    elseif (-not ($param.HashAlgorithmName -in $combination.HashAlgorithmName))
    {
        Write-Error -Message "HashAlgorithmName '$($param.HashAlgorithmName)' is not valid for CryptoProviderName '$($param.CryptoProviderName)'. The Crypto Provider selected supports the following Hash Algorithms:`n  $($combination.HashAlgorithmName -join "`n  ")"; return
    }
    elseif (-not ($param.KeyLength -in $combination.KeyLength))
    {
        Write-Error -Message "Keylength '$($param.KeyLength)' is not valid for CryptoProviderName '$($param.CryptoProviderName)'. The Crypto Provider selected supports the following keylengths:`n  $($combination.KeyLength -join "`n  ")"; return
    }



    if ($role.Properties.ContainsKey('DatabaseDirectory') -and -not ($param.DatabaseDirectory -match '^[C-Z]:\\'))
    {
        Write-Error -Message 'DatabaseDirectory needs to be located on a local drive (drive letter C-Z)'; return
    }

    if ($role.Properties.ContainsKey('LogDirectory') -and -not ($param.LogDirectory -match '^[C-Z]:\\'))
    {
        Write-Error -Message 'LogDirectory needs to be located on a local drive (drive letter C-Z)'; return
    }

    if (($param.UseLDAPAIA -ne '<auto>') -and ($param.UseLDAPAIA -notin ('Yes', 'No')))
    {
        Write-Error -Message "UseLDAPAIA needs to be 'Yes' or 'no'. Specified value is: '$($param.UseLDAPAIA)'"; return
    }

    if (($param.UseHTTPAIA -ne '<auto>') -and ($param.UseHTTPAIA -notin ('Yes', 'No')))
    {
        Write-Error -Message "UseHTTPAIA needs to be 'Yes' or 'no'. Specified value is: '$($param.UseHTTPAIA)'"; return
    }

    if (($param.UseLDAPCRL -ne '<auto>') -and ($param.UseLDAPCRL -notin ('Yes', 'No')))
    {
        Write-Error -Message "UseLDAPCRL needs to be 'Yes' or 'no'. Specified value is: '$($param.UseLDAPCRL)'"; return
    }

    if (($param.UseHTTPCRL -ne '<auto>') -and ($param.UseHTTPCRL -notin ('Yes', 'No')))
    {
        Write-Error -Message "UseHTTPCRL needs to be 'Yes' or 'no'. Specified value is: '$($param.UseHTTPCRL)'"; return
    }

    if (($param.InstallWebEnrollment -ne '<auto>') -and ($param.InstallWebEnrollment -notin ('Yes', 'No')))
    {
        Write-Error -Message "InstallWebEnrollment needs to be 'Yes' or 'no'. Specified value is: '$($param.InstallWebEnrollment)'"; return
    }

    if (($param.InstallWebRole -ne '<auto>') -and ($param.InstallWebRole -notin ('Yes', 'No')))
    {
        Write-Error -Message "InstallWebRole needs to be 'Yes' or 'no'. Specified value is: '$($param.InstallWebRole)'"; return
    }

    if (($param.AIAHTTPURL01 -ne '<auto>') -and ($param.AIAHTTPURL01 -notlike 'http://*'))
    {
        Write-Error -Message "AIAHTTPURL01 needs to start with 'http://' (https is not supported). Specified value is: '$($param.AIAHTTPURL01)'"; return
    }

    if (($param.AIAHTTPURL02 -ne '<auto>') -and ($param.AIAHTTPURL02 -notlike 'http://*'))
    {
        Write-Error -Message "AIAHTTPURL02 needs to start with 'http://' (https is not supported). Specified value is: '$($param.AIAHTTPURL02)'"; return
    }

    if (($param.CDPHTTPURL01 -ne '<auto>') -and ($param.CDPHTTPURL01 -notlike 'http://*'))
    {
        Write-Error -Message "CDPHTTPURL01 needs to start with 'http://' (https is not supported). Specified value is: '$($param.CDPHTTPURL01)'"; return
    }

    if (($param.CDPHTTPURL02 -ne '<auto>') -and ($param.CDPHTTPURL02 -notlike 'http://*'))
    {
        Write-Error -Message "CDPHTTPURL02 needs to start with 'http://' (https is not supported). Specified value is: '$($param.CDPHTTPURL02)'"; return
    }

    if (($role.Name -eq 'CaRoot') -and ($param.DoNotLoadDefaultTemplates -ne '<auto>') -and ($param.DoNotLoadDefaultTemplates -notin ('Yes', 'No')))
    {
        Write-Error -Message "DoNotLoadDefaultTemplates needs to be 'Yes' or 'No'. Specified value is: '$($param.DoNotLoadDefaultTemplates)'"; return
    }



    #ValidityPeriod and ValidityPeriodUnits
    if ($param.ValidityPeriodUnits -ne '<auto>')
    {
        try { $dummy = [int]$param.ValidityPeriodUnits }
        catch { Write-Error -Message 'ValidityPeriodUnits is not convertable to an integer. Please specify (enclosed as a string) a number between 1 and 2147483647'; return }
    }

    if (($param.ValidityPeriodUnits -ne '<auto>') -and ([int]$param.ValidityPeriodUnits) -lt 1)
    {
        Write-Error -Message 'ValidityPeriodUnits cannot be less than 1. Please specify (enclosed as a string) a number between 1 and 2147483647'; return
    }

    if (($param.ValidityPeriodUnits) -ne '<auto>' -and (!($role.Properties.ContainsKey('ValidityPeriod'))))
    {
        Write-Error -Message 'ValidityPeriodUnits specified (ok) while ValidityPeriod is not specified. ValidityPeriod needs to be one of "Years", "Months", "Weeks", "Days", "Hours".'; return
    }

    if ($param.ValidityPeriod -ne '<auto>' -and ($param.ValidityPeriod -notin ('Years', 'Months', 'Weeks', 'Days', 'Hours')))
    {
        Write-Error -Message "ValidityPeriod need to be one of 'Years', 'Months', 'Weeks', 'Days', 'Hours'. Specified value is: '$($param.ValidityPeriod)'"; return
    }


    #CertsValidityPeriod and CertsValidityPeriodUnits
    if ($param.CertsValidityPeriodUnits -ne '<auto>')
    {
        try { $dummy = [int]$param.CertsValidityPeriodUnits }
        catch { Write-Error -Message 'CertsValidityPeriodUnits is not convertable to an integer. Please specify (enclosed as a string) a number between 1 and 2147483647'; return }
    }

    if (($param.CertsValidityPeriodUnits) -ne '<auto>' -and (!($role.Properties.ContainsKey('CertsValidityPeriod'))))
    {
        Write-Error -Message 'CertsValidityPeriodUnits specified (ok) while CertsValidityPeriod is not specified. CertsValidityPeriod needs to be one of "Years", "Months", "Weeks", "Days", "Hours" .'; return
    }

    if ($param.CertsValidityPeriod -ne '<auto>' -and ($param.CertsValidityPeriod -notin ('Years', 'Months', 'Weeks', 'Days', 'Hours')))
    {
        Write-Error -Message "CertsValidityPeriod need to be one of 'Years', 'Months', 'Weeks', 'Days', 'Hours'. Specified value is: '$($param.CertsValidityPeriod)'"; return
    }


    #CRLPeriodUnits and CRLPeriodUnitsUnits
    if ($param.CRLPeriodUnits -ne '<auto>')
    {
        try { $dummy = [int]$param.CRLPeriodUnits }
        catch { Write-Error -Message 'CRLPeriodUnits is not convertable to an integer. Please specify (enclosed as a string) a number between 1 and 2147483647'; return }
    }

    if (($param.CRLPeriodUnits) -ne '<auto>' -and (!($role.Properties.ContainsKey('CRLPeriod'))))
    {
        Write-Error -Message 'CRLPeriodUnits specified (ok) while CRLPeriod is not specified. CRLPeriod needs to be one of "Years", "Months", "Weeks", "Days", "Hours" .'; return
    }

    if ($param.CRLPeriod -ne '<auto>' -and ($param.CRLPeriod -notin ('Years', 'Months', 'Weeks', 'Days', 'Hours')))
    {
        Write-Error -Message "CRLPeriod need to be one of 'Years', 'Months', 'Weeks', 'Days', 'Hours'. Specified value is: '$($param.CRLPeriod)'"; return
    }


    #CRLOverlapPeriod and CRLOverlapUnits
    if ($param.CRLOverlapUnits -ne '<auto>')
    {
        try { $dummy = [int]$param.CRLOverlapUnits }
        catch { Write-Error -Message 'CRLOverlapUnits is not convertable to an integer. Please specify (enclosed as a string) a number between 1 and 2147483647'; return }
    }

    if (($param.CRLOverlapUnits) -ne '<auto>' -and (!($role.Properties.ContainsKey('CRLOverlapPeriod'))))
    {
        Write-Error -Message 'CRLOverlapUnits specified (ok) while CRLOverlapPeriod is not specified. CRLOverlapPeriod needs to be one of "Years", "Months", "Weeks", "Days", "Hours" .'; return
    }

    if ($param.CRLOverlapPeriod -ne '<auto>' -and ($param.CRLOverlapPeriod -notin ('Years', 'Months', 'Weeks', 'Days', 'Hours')))
    {
        Write-Error -Message "CRLOverlapPeriod need to be one of 'Years', 'Months', 'Weeks', 'Days', 'Hours'. Specified value is: '$($param.CRLOverlapPeriod)'"; return
    }


    #CRLDeltaPeriod and CRLDeltaPeriodUnits
    if ($param.CRLDeltaPeriodUnits -ne '<auto>')
    {
        try { $dummy = [int]$param.CRLDeltaPeriodUnits }
        catch { Write-Error -Message 'CRLDeltaPeriodUnits is not convertable to an integer. Please specify (enclosed as a string) a number between 1 and 2147483647'; return }
    }

    if (($param.CRLDeltaPeriodUnits) -ne '<auto>' -and (!($role.Properties.ContainsKey('CRLDeltaPeriod'))))
    {
        Write-Error -Message 'CRLDeltaPeriodUnits specified (ok) while CRLDeltaPeriod is not specified. CRLDeltaPeriod needs to be one of "Years", "Months", "Weeks", "Days", "Hours" .'; return
    }

    if ($param.CRLDeltaPeriod -ne '<auto>' -and ($param.CRLDeltaPeriod -notin ('Years', 'Months', 'Weeks', 'Days', 'Hours')))
    {
        Write-Error -Message "CRLDeltaPeriod need to be one of 'Years', 'Months', 'Weeks', 'Days', 'Hours'. Specified value is: '$($param.CRLDeltaPeriod)'"; return
    }

    #endregion ----- Input validation (raw values) -----



    #region ----- Input validation (content analysis) -----
    if (($param.CAType -like 'Enterprise*') -and (!($machine.isDomainJoined)))
    {
        Write-Error -Message "CA Type specified is '$($param.CAType)' while machine is not domain joined. This is not possible"; return
    }

    if (($param.CAType -like 'StandAlone*') -and ($role.Properties.ContainsKey('UseLDAPAIA')) -and ($param.UseLDAPAIA))
    {
        Write-Error -Message "UseLDAPAIA is set to 'Yes' while 'CAType' is set to '$($param.CAType)'. It is not possible to use LDAP based AIA for a $($param.CAType)"; return
    }

    if (($param.CAType -like 'StandAlone*') -and ($role.Properties.ContainsKey('UseLDAPCRL')) -and ($param.UseLDAPCRL))
    {
        Write-Error -Message "UseLDAPCRL is set to 'Yes' while 'CAType' is set to '$($param.CAType)'. It is not possible to use LDAP based CRL for a $($param.CAType)"; return
    }

    if (($param.CAType -like 'StandAlone*') -and ($role.Properties.ContainsKey('InstallWebRole')) -and (!($param.InstallWebRole)))
    {
        Write-Error -Message "InstallWebRole is set to No while CAType is StandAloneCA. $($param.CAType) needs web role for hosting a CDP"
        return
    }

    if (($role.Properties.ContainsKey('OCSPHTTPURL01')) -or ($role.Properties.ContainsKey('OCSPHTTPURL02')) -or ($role.Properties.ContainsKey('InstallOCSP')))
    {
        Write-ScreenInfo -Message 'OCSP is not yet supported. OCSP parameters will be ignored and OCSP will not be installed!' -Type Warning
    }


    #if any validity parameter was defined, get these now and convert them all to hours (temporary variables)
    if ($param.ValidityPeriodUnits -ne '<auto>')
    {
        switch ($param.ValidityPeriod)
        {
            'Years'  { $validityPeriodUnitsHours = [int]$param.ValidityPeriodUnits * 365 * 24 }
            'Months' { $validityPeriodUnitsHours = [int]$param.ValidityPeriodUnits * (365/12) * 24 }
            'Weeks'  { $validityPeriodUnitsHours = [int]$param.ValidityPeriodUnits * 7 * 24 }
            'Days'   { $validityPeriodUnitsHours = [int]$param.ValidityPeriodUnits * 24 }
            'Hours'  { $validityPeriodUnitsHours = [int]$param.ValidityPeriodUnits }
        }
    }
    if ($param.CertsValidityPeriodUnits -ne '<auto>')
    {
        switch ($param.CertsValidityPeriod)
        {
            'Years'  { $certsvalidityPeriodUnitsHours = [int]$param.CertsValidityPeriodUnits * 365 * 24 }
            'Months' { $certsvalidityPeriodUnitsHours = [int]$param.CertsValidityPeriodUnits * (365/12) * 24 }
            'Weeks'  { $certsvalidityPeriodUnitsHours = [int]$param.CertsValidityPeriodUnits * 7 * 24 }
            'Days'   { $certsvalidityPeriodUnitsHours = [int]$param.CertsValidityPeriodUnits * 24 }
            'Hours'  { $certsvalidityPeriodUnitsHours = [int]$param.CertsValidityPeriodUnits }
        }
    }
    if ($param.CRLPeriodUnits -ne '<auto>')
    {
        switch ($param.CRLPeriod)
        {
            'Years'  { $cRLPeriodUnitsHours = [int]([int]$param.CRLPeriodUnits * 365 * 24) }
            'Months' { $cRLPeriodUnitsHours = [int]([int]$param.CRLPeriodUnit * (365/12) * 24) }
            'Weeks'  { $cRLPeriodUnitsHours = [int]([int]$param.CRLPeriodUnits * 7 * 24) }
            'Days'   { $cRLPeriodUnitsHours = [int]([int]$param.CRLPeriodUnits * 24) }
            'Hours'  { $cRLPeriodUnitsHours = [int]([int]$param.CRLPeriodUnits) }
        }
    }
    if ($param.CRLDeltaPeriodUnits -ne '<auto>')
    {
        switch ($param.CRLDeltaPeriod)
        {
            'Years'  { $cRLDeltaPeriodUnitsHours = [int]([int]$param.CRLDeltaPeriodUnits * 365 * 24) }
            'Months' { $cRLDeltaPeriodUnitsHours = [int]([int]$param.CRLDeltaPeriodUnits * (365/12) * 24) }
            'Weeks'  { $cRLDeltaPeriodUnitsHours = [int]([int]$param.CRLDeltaPeriodUnits * 7 * 24) }
            'Days'   { $cRLDeltaPeriodUnitsHours = [int]([int]$param.CRLDeltaPeriodUnits * 24) }
            'Hours'  { $cRLDeltaPeriodUnitsHours = [int]([int]$param.CRLDeltaPeriodUnits) }
        }
    }
    if ($param.CRLOverlapUnits -ne '<auto>')
    {
        switch ($param.CRLOverlapPeriod)
        {
            'Years'  { $CRLOverlapUnitsHours = [int]([int]$param.CRLOverlapUnits * 365 * 24) }
            'Months' { $CRLOverlapUnitsHours = [int]([int]$param.CRLOverlapUnits * (365/12) * 24) }
            'Weeks'  { $CRLOverlapUnitsHours = [int]([int]$param.CRLOverlapUnits * 7 * 24) }
            'Days'   { $CRLOverlapUnitsHours = [int]([int]$param.CRLOverlapUnits * 24) }
            'Hours'  { $CRLOverlapUnitsHours = [int]([int]$param.CRLOverlapUnits) }
        }
    }

    if ($role.Properties.ContainsKey('CRLPeriodUnits') -and ($cRLPeriodUnitsHours) -and ($validityPeriodUnitsHours) -and ($cRLPeriodUnitsHours -ge $validityPeriodUnitsHours))
    {
        Write-Error -Message "CRLPeriodUnits is longer than ValidityPeriodUnits. This is not possible. `
            Specified value for CRLPeriodUnits is: '$($param.CRLPeriodUnits) $($param.CRLPeriod)'`
        Specified value for ValidityPeriodUnits is: '$($param.ValidityPeriodUnits) $($param.ValidityPeriod)'"
        return
    }
    if ($role.Properties.ContainsKey('CertsValidityPeriodUnits') -and ($certsvalidityPeriodUnitsHours) -and ($validityPeriodUnitsHours) -and ($certsvalidityPeriodUnitsHours -ge $validityPeriodUnitsHours))
    {
        Write-Error -Message "CertsValidityPeriodUnits is longer than ValidityPeriodUnits. This is not possible. `
            Specified value for certsValidityPeriodUnits is: '$($param.CertsValidityPeriodUnits) $($param.CertsValidityPeriod)'`
        Specified value for ValidityPeriodUnits is: '$($param.ValidityPeriodUnits) $($param.ValidityPeriod)'"
        return
    }
    if ($role.Properties.ContainsKey('CRLDeltaPeriodUnits') -and ($CRLDeltaPeriodUnitsHours) -and ($cRLPeriodUnitsHours) -and ($cRLDeltaPeriodUnitsHours -ge $cRLPeriodUnitsHours))
    {
        Write-Error -Message "CRLDeltaPeriodUnits is longer than CRLPeriodUnits. This is not possible. `
            Specified value for CRLDeltaPeriodUnits is: '$($param.CRLDeltaPeriodUnits) $($param.CRLDeltaPeriod)'`
        Specified value for ValidityPeriodUnits is: '$($param.CRLPeriodUnits) $($param.CRLPeriod)'"
        return
    }
    if ($role.Properties.ContainsKey('CRLOverlapUnits') -and ($CRLOverlapUnitsHours) -and ($validityPeriodUnitsHours) -and ($CRLOverlapUnitsHours -ge $validityPeriodUnitsHours))
    {
        Write-Error -Message "CRLOverlapUnits is longer than ValidityPeriodUnits. This is not possible. `
            Specified value for CRLOverlapUnits is: '$($param.CRLOverlapUnits) $($param.CRLOverlapPeriod)'`
        Specified value for ValidityPeriodUnits is: '$($param.ValidityPeriodUnits) $($param.ValidityPeriod)'"
        return
    }
    if ($role.Properties.ContainsKey('CRLOverlapUnits') -and ($CRLOverlapUnitsHours) -and ($cRLPeriodUnitsHours) -and ($CRLOverlapUnitsHours -ge $cRLPeriodUnitsHours))
    {
        Write-Error -Message "CRLOverlapUnits is longer than CRLPeriodUnits. This is not possible. `
            Specified value for CRLOverlapUnits is: '$($param.CRLOverlapUnits) $($param.CRLOverlapPeriod)'`
        Specified value for CRLPeriodUnits is: '$($param.CRLPeriodUnits) $($param.CRLPeriod)'"
        return
    }
    if (($param.CAType -like '*root*') -and ($role.Properties.ContainsKey('ValidityPeriod')) -and ($validityPeriodUnitsHours) -and ($validityPeriodUnitsHours -gt (10 * 365 * 24)))
    {
        Write-ScreenInfo -Message "ValidityPeriod is more than 10 years. Overall validity of all issued certificates by Enterprise Root CAs will be set to specified value. `
            However, the default validity (specified by 2012/2012R2 Active Directory) of issued by Enterprise Root CAs to Subordinate CAs, is 5 years. `
        If more than 5 years is needed, a custom certificate template is needed wherein the validity can be changed." -Type Warning
    }


    #region - If DatabaseDirectory or LogDirectory is specified, Check for drive existence in the VM
    if (($param.DatabaseDirectory -ne '<auto>') -or ($param.LogDirectory -ne '<auto>'))
    {
        $caSession = New-LabPSSession -ComputerName $Machine

        if ($param.DatabaseDirectory -ne '<auto>')
        {
            $DatabaseDirectoryDrive = ($param.DatabaseDirectory.split(':')[0]) + ':'

            $disk = Invoke-LabCommand -ComputerName $Machine -ScriptBlock {
                Get-WmiObject -Namespace Root\CIMV2 -Class Win32_LogicalDisk -Filter "DeviceID = ""$DatabaseDirectoryDrive"""
            } -Variable (Get-Variable -Name DatabaseDirectoryDrive) -PassThru

            if (-not $disk -or -not $disk.DriveType -eq 3)
            {
                Write-Error -Message "Drive for Database Directory does not exist or is not a hard disk drive. Specified value is: $DatabaseDirectory"
                return
            }
        }

        if ($param.LogDirectory -ne '<auto>')
        {
            $LogDirectoryDrive = ($param.LogDirectory.split(':')[0]) + ':'
            $disk = Invoke-LabCommand -ComputerName $Machine -ScriptBlock {
                Get-WmiObject -Namespace Root\CIMV2 -Class Win32_LogicalDisk -Filter "DeviceID = ""$LogDirectoryDrive"""
            } -Variable (Get-Variable -Name LogDirectoryDrive) -PassThru
            if (-not $disk -or -not $disk.DriveType -eq 3)
            {
                Write-Error -Message "Drive for Log Directory does not exist or is not a hard disk drive. Specified value is: $LogDirectory"
                return
            }
        }
    }
    #endregion - If DatabaseDirectory or LogDirectory is specified, Check for drive existence in the VM

    #endregion ----- Input validation (content analysis) -----


    #region ----- Calculations -----

    #If ValidityPeriodUnits is not defined, define it now and Update machine property "ValidityPeriod"
    if ($param.ValidityPeriodUnits -eq '<auto>')
    {
        $param.ValidityPeriod = 'Years'
        $param.ValidityPeriodUnits = '10'
        if (!($validityPeriodUnitsHours)) { $validityPeriodUnitsHours = [int]($param.ValidityPeriodUnits) * 365 * 24 }
    }


    #If CAType is not defined, define it now
    if ($param.CAType -eq '<auto>')
    {
        if ($machine.IsDomainJoined)
        {
            if ($role.Name -eq 'CaRoot')
            {
                $param.CAType = 'EnterpriseRootCA'
                if ($VerbosePreference -ne 'SilentlyContinue') { Write-ScreenInfo -Message 'Parameter "CAType" is not specified. Automatically setting CAtype to "EnterpriseRootCA" since machine is domain joined and Root CA role is specified' -Type Warning }
            }
            else
            {
                $param.CAType = 'EnterpriseSubordinateCA'
                if ($VerbosePreference -ne 'SilentlyContinue') { Write-ScreenInfo -Message 'Parameter "CAType" is not specified. Automatically setting CAtype to "EnterpriseSubordinateCA" since machine is domain joined and Subordinate CA role is specified' -Type Warning }
            }
        }
        else
        {
            if ($role.Name -eq 'CaRoot')
            {
                $param.CAType = 'StandAloneRootCA'
                if ($VerbosePreference -ne 'SilentlyContinue') { Write-ScreenInfo -Message 'Parameter "CAType" is not specified. Automatically setting CAtype to "StandAloneRootCA" since machine is not domain joined and Root CA role is specified' -Type Warning }
            }
            else
            {
                $param.CAType = 'StandAloneSubordinateCA'
                if ($VerbosePreference -ne 'SilentlyContinue') { Write-ScreenInfo -Message 'Parameter "CAType" is not specified. Automatically setting CAtype to "StandAloneSubordinateCA" since machine is not domain joined and Subordinate CA role is specified' -Type Warning }
            }
        }
    }


    #If ParentCA is not defined, try to find it automatically
    if ($param.ParentCA -eq '<auto>')
    {
        if ($param.CAType -like '*Subordinate*') #CA is a Subordinate CA
        {
            if ($param.CAType -like 'Enterprise*')
            {
                $rootCA = [array](Get-LabVM -Role CaRoot | Where-Object DomainName -eq $machine.DomainName | Sort-Object -Property DomainName) | Select-Object -First 1

                if (-not $rootCA)
                {
                    $rootCA = [array](Get-LabVM -Role CaRoot | Where-Object { -not $_.IsDomainJoined }) | Select-Object -First 1
                }

            }
            else
            {
                $rootCA = [array](Get-LabVM -Role CaRoot | Where-Object { -not $_.IsDomainJoined }) | Select-Object -First 1
            }

            if ($rootCA)
            {
                $param.ParentCALogicalName = ($rootCA.Roles | Where-Object Name -eq CaRoot).Properties.CACommonName
                $param.ParentCA = $rootCA.Name
                Write-PSFMessage "Root CA '$($param.ParentCALogicalName)' ($($param.ParentCA)) automatically selected as parent CA"
                $ValidityPeriod = $rootCA.roles.Properties.CertsValidityPeriod
                $ValidityPeriodUnits = $rootCA.roles.Properties.CertsValidityPeriodUnits
            }
            else
            {
                Write-Error -Message 'No name for Parent CA specified and no Root CA can be located automatically. Please install a Root CA in the lab before installing a Subordinate CA'
                return
            }

            #Check if Parent CA is valid
            $caSession = New-LabPSSession -ComputerName $param.ComputerName

            Write-Debug -Message "Testing ParentCA with command: 'certutil -ping $($param.ParentCA)\$($param.ParentCALogicalName)'"


            $totalretries = 20
            $retries = 0

            Write-PSFMessage -Message "Testing Root CA availability: certutil -ping $($param.ParentCA)\$($param.ParentCALogicalName)"
            do
            {
                $result = Invoke-LabCommand -ComputerName $param.ComputerName -ScriptBlock {
                    param(
                        [string]$ParentCA,
                        [string]$ParentCALogicalName
                    )
                    Invoke-Expression -Command "certutil -ping $ParentCA\$ParentCALogicalName"
                } -ArgumentList $param.ParentCA, $param.ParentCALogicalName -PassThru -NoDisplay

                if (-not ($result | Where-Object { $_ -like '*interface is alive*' }))
                {
                    $result | ForEach-Object { Write-Debug -Message $_ }
                    $retries++
                    Write-PSFMessage -Message "Could not contact ParentCA. (Computername=$($param.ParentCA), LogicalCAName=$($param.ParentCALogicalName)). (Check $retries of $totalretries)"
                    if ($retries -lt $totalretries) { Start-Sleep -Seconds 5 }
                }
            }
            until (($result | Where-Object { $_ -like '*interface is alive*' }) -or ($retries -ge $totalretries))

            if ($result | Where-Object { $_ -like '*interface is alive*' })
            {
                Write-PSFMessage -Message "Parent CA ($($param.ParentCA)) is contactable"
            }
            else
            {
                Write-Error -Message "Parent CA ($($param.ParentCA)) is not contactable. Please install a Root CA in the lab before installing a Subordinate CA"
                return
            }
        }
        else #CA is a Root CA
        {
            $param.ParentCALogicalName = ''
            $param.ParentCA = ''
        }
    }

    #Calculate and update machine property "CACommonName" if this was not specified. Note: the first instance of a name of a Root CA server, will be used by install code for Sub CAs.
    if ($param.CACommonName -eq '<auto>')
    {
        if ($role.Name -eq 'CaRoot')        { $caBaseName = 'LabRootCA' }
        if ($role.Name -eq 'CaSubordinate') { $caBaseName = 'LabSubCA'  }

        [array]$caNamesAlreadyInUse = Invoke-LabCommand -ComputerName (Get-LabVM -Role $role.Name) -ScriptBlock {
            $name = certutil.exe -getreg CA\CommonName | Where-Object { $_ -match 'CommonName REG' }
            if ($name)
            {
                $name.Split('=')[1].Trim()
            }
        } -NoDisplay -PassThru
        $num = 0
        do
        {
            $num++
        }
        until (($caBaseName + [string]($num)) -notin ((Get-LabVM).Roles.Properties.CACommonName) -and ($caBaseName + [string]($num)) -notin $caNamesAlreadyInUse)

        $param.CACommonName = $caBaseName + ([string]$num)
        ($machine.Roles | Where-Object Name -like Ca*).Properties.Add('CACommonName', $param.CACommonName)
    }

    #Converting to correct types for some parameters
    if ($param.InstallWebEnrollment -eq '<auto>')
    {
        if ($param.CAType -like 'Enterprise*')
        {
            $param.InstallWebEnrollment = $False
        }
        else
        {
            $param.InstallWebEnrollment = $True
        }
    }
    else
    {
        $param.InstallWebEnrollment = ($param.InstallWebEnrollment -like '*Y*')
    }

    if ($param.InstallWebRole -eq '<auto>')
    {
        if ($param.CAType -like 'Enterprise*')
        {
            $param.InstallWebRole = $False
        }
        else
        {
            $param.InstallWebRole = $True
        }
    }
    else
    {
        $param.InstallWebRole = ($param.InstallWebRole -like '*Y*')
    }

    if ($param.UseLDAPAIA -eq '<auto>')
    {
        if ($param.CAType -like 'Enterprise*')
        {
            $param.UseLDAPAIA = $True
        }
        else
        {
            $param.UseLDAPAIA = $False
        }
    }
    else
    {
        $param.UseLDAPAIA = ($param.UseLDAPAIA -like '*Y*')
    }

    if ($param.UseHTTPAIA -eq '<auto>')
    {
        if ($param.CAType -like 'Enterprise*')
        {
            $param.UseHTTPAIA = $False
        }
        else
        {
            $param.UseHTTPAIA = $True
        }
    }
    else
    {
        $param.UseHTTPAIA = ($param.UseHTTPAIA -like '*Y*')
    }

    if ($param.UseLDAPCRL -eq '<auto>')
    {
        if ($param.CAType -like 'Enterprise*')
        {
            $param.UseLDAPCRL = $True
        }
        else
        {
            $param.UseLDAPCRL = $False
        }
    }
    else
    {
        $param.UseLDAPCRL = ($param.UseLDAPCRL -like '*Y*')
    }

    if ($param.UseHTTPCRL -eq '<auto>')
    {
        if ($param.CAType -like 'Enterprise*')
        {
            $param.UseHTTPCRL = $False
        }
        else
        {
            $param.UseHTTPCRL = $True
        }
    }
    else
    {
        $param.UseHTTPCRL = ($param.UseHTTPCRL -like '*Y*')
    }

    $param.InstallOCSP = $False
    $param.OCSPHTTPURL01 = ''
    $param.OCSPHTTPURL02 = ''


    $param.AIAHTTPURL01UploadLocation = ''
    $param.AIAHTTPURL02UploadLocation = ''
    $param.CDPHTTPURL01UploadLocation = ''
    $param.CDPHTTPURL02UploadLocation = ''




    if (($param.CaType -like 'StandAlone*') -and $role.Properties.ContainsKey('UseLDAPAIA') -and $param.UseLDAPAIA)
    {
        Write-Error -Message "Parameter 'UseLDAPAIA' is set to 'Yes' while 'CAType' is set to '$($param.CaType)'. It is not possible to use LDAP based AIA for a $($param.CaType)"
        return
    }
    elseif (($param.CaType -like 'StandAlone*') -and (!($role.Properties.ContainsKey('UseLDAPAIA'))))
    {
        $param.UseLDAPAIA = $False
    }

    if (($param.CaType -like 'StandAlone*') -and $role.Properties.ContainsKey('UseHTTPAIA') -and (-not $param.UseHTTPAIA))
    {
        Write-Error -Message "Parameter 'UseHTTPAIA' is set to 'No' while 'CAType' is set to '$($param.CaType)'. Only AIA possible for a $($param.CaType), is Http based AIA."
        return
    }
    elseif (($param.CaType -like 'StandAlone*') -and (!($role.Properties.ContainsKey('UseHTTPAIA'))))
    {
        $param.UseHTTPAIA = $True
    }


    if (($param.CaType -like 'StandAlone*') -and $role.Properties.ContainsKey('UseLDAPCRL') -and $param.UseLDAPCRL)
    {
        Write-Error -Message "Parameter 'UseLDAPCRL' is set to 'Yes' while 'CAType' is set to '$($param.CaType)'. It is not possible to use LDAP based CRL for a $($param.CaType)"
        return
    }
    elseif (($param.CaType -like 'StandAlone*') -and (!($role.Properties.ContainsKey('UseLDAPCRL'))))
    {
        $param.UseLDAPCRL = $False
    }

    if (($param.CaType -like 'StandAlone*') -and $role.Properties.ContainsKey('UseHTTPCRL') -and (-not $param.UseHTTPCRL))
    {
        Write-Error -Message "Parameter 'UseHTTPCRL' is set to 'No' while 'CAType' is set to '$($param.CaType)'. Only CRL possible for a $($param.CaType), is Http based CRL."
        return
    }
    elseif (($param.CaType -like 'StandAlone*') -and (!($role.Properties.ContainsKey('UseHTTPCRL'))))
    {
        $param.UseHTTPCRL = $True
    }


    #If AIAHTTPURL01 or CDPHTTPURL01 was not specified but is needed, populate these now
    if (($param.CaType -like 'StandAlone*') -and (!($role.Properties.ContainsKey('AIAHTTPURL01')) -and $param.UseHTTPAIA))
    {
        $param.AIAHTTPURL01 = ('http://' + $caDNSName + '/aia')
        $param.AIAHTTPURL02 = ''
    }

    if (($param.CaType -like 'StandAlone*') -and (!($role.Properties.ContainsKey('CDPHTTPURL01')) -and $param.UseHTTPCRL))
    {
        $param.CDPHTTPURL01 = ('http://' + $caDNSName + '/cdp')
        $param.CDPHTTPURL02 = ''
    }






    #If Enterprise  CA, and UseLDAPAia is "Yes" or not specified, set UseLDAPAIA to True
    if (($param.CaType -like 'Enterprise*') -and (!($role.Properties.ContainsKey('UseLDAPAIA'))))
    {
        $param.UseLDAPAIA = $True
    }


    #If Enterprise  CA, and UseLDAPCrl is "Yes" or not specified, set UseLDAPCrl to True
    if (($param.CaType -like 'Enterprise*') -and (!($role.Properties.ContainsKey('UseLDAPCRL'))))
    {
        $param.UseLDAPCRL = $True
    }

    #If AIAHTTPURL01 or CDPHTTPURL01 was not specified but is needed, populate these now (with empty strings)
    if (($param.CaType -like 'Enterprise*') -and (!($role.Properties.ContainsKey('AIAHTTPURL01'))))
    {
        if ($param.UseHTTPAIA)
        {
            $param.AIAHTTPURL01 = 'http://' + $caDNSName + '/aia'
            $param.AIAHTTPURL02 = ''
        }
        else
        {
            $param.AIAHTTPURL01 = ''
            $param.AIAHTTPURL02 = ''
        }
    }

    if (($param.CaType -like 'Enterprise*') -and (!($role.Properties.ContainsKey('CDPHTTPURL01'))))
    {
        if ($param.UseHTTPCRL)
        {
            $param.CDPHTTPURL01 = 'http://' + $caDNSName + '/cdp'
            $param.CDPHTTPURL02 = ''
        }
        else
        {
            $param.CDPHTTPURL01 = ''
            $param.CDPHTTPURL02 = ''
        }
    }


    function Scale-Parameters
    {
        param ([int]$hours)

        $factorYears = 24 * 365
        $factorMonths = 24 * (365/12)
        $factorWeeks = 24 * 7
        $factorDays = 24
        switch ($hours)
        {
            { $_ -ge $factorYears }
            {
                if (($hours / $factorYears) * 100%100 -le 10) { return ([string][int]($hours / $factorYears)), 'Years' }
            }
            { $_ -ge $factorMonths }
            {
                if (($hours / $factorMonths) * 100%100 -le 10) { return ([string][int]($hours / $factorMonths)), 'Months' }
            }
            { $_ -ge $factorWeeks }
            {
                if (($hours / $factorWeeks) * 100%100 -le 50) { return ([string][int]($hours / $factorWeeks)), 'Weeks' }
            }
            { $_ -ge $factorDays }
            {
                if (($hours / $factorDays) * 100%100 -le 75) { return ([string][int]($hours / $factorDays)), 'Days' }
            }
        }
        $returnHours = [int]($hours)
        if ($returnHours -lt 1) { $returnHours = 1 }
        return ([string]$returnHours), 'Hours'
    }

    #if any validity parameter was not defined, calculate these now
    if ($param.CRLPeriodUnits -eq '<auto>') { $param.CRLPeriodUnits, $param.CRLPeriod = Scale-Parameters ($validityPeriodUnitsHours/8) }
    if ($param.CRLDeltaPeriodUnits -eq '<auto>') { $param.CRLDeltaPeriodUnits, $param.CRLDeltaPeriod = Scale-Parameters ($validityPeriodUnitsHours/16) }
    if ($param.CRLOverlapUnits -eq '<auto>') { $param.CRLOverlapUnits, $param.CRLOverlapPeriod = Scale-Parameters ($validityPeriodUnitsHours/32) }
    if ($param.CertsValidityPeriodUnits -eq '<auto>')
    {
        $param.CertsValidityPeriodUnits, $param.CertsValidityPeriod = Scale-Parameters ($validityPeriodUnitsHours/2)
    }

    $role = $machine.Roles | Where-Object { ([AutomatedLab.Roles]$_.Name -band $roles) -ne 0 }
    if (($param.CAType -like '*root*') -and !($role.Properties.ContainsKey('CertsValidityPeriodUnits')))
    {
        if ($VerbosePreference -ne 'SilentlyContinue') { Write-ScreenInfo -Message "Adding parameter 'CertsValidityPeriodUnits' with value of '$($param.CertsValidityPeriodUnits)' to machine roles properties of machine $($machine.Name)" -Type Warning }
        $role.Properties.Add('CertsValidityPeriodUnits', $param.CertsValidityPeriodUnits)
    }
    if (($param.CAType -like '*root*') -and !($role.Properties.ContainsKey('CertsValidityPeriod')))
    {
        if ($VerbosePreference -ne 'SilentlyContinue') { Write-ScreenInfo -Message "Adding parameter 'CertsValidityPeriod' with value of '$($param.CertsValidityPeriod)' to machine roles properties of machine $($machine.Name)" -Type Warning }
        $role.Properties.Add('CertsValidityPeriod', $param.CertsValidityPeriod)
    }

    #If any HTTP parameter is specified and any of the DNS names in these parameters points to this CA server, install Web Role to host this
    if (!($param.InstallWebRole))
    {
        if (($param.UseHTTPAIA -or $param.UseHTTPCRL) -and `
        $param.AIAHTTPURL01 -or $param.AIAHTTPURL02 -or $param.CDPHTTPURL01 -or $param.CDPHTTPURL02)
        {
            $URLs = @()
            $ErrorActionPreferenceBackup = $ErrorActionPreference
            $ErrorActionPreference = 'SilentlyContinue'
            if ($param.AIAHTTPURL01.IndexOf('/', 2)) { $URLs += ($param.AIAHTTPURL01).Split('/')[2].Split('/')[0] }
            if ($param.AIAHTTPURL02.IndexOf('/', 2)) { $URLs += ($param.AIAHTTPURL02).Split('/')[2].Split('/')[0] }
            if ($param.CDPHTTPURL01.IndexOf('/', 2)) { $URLs += ($param.CDPHTTPURL01).Split('/')[2].Split('/')[0] }
            if ($param.CDPHTTPURL02.IndexOf('/', 2)) { $URLs += ($param.CDPHTTPURL02).Split('/')[2].Split('/')[0] }
            $ErrorActionPreference = $ErrorActionPreferenceBackup

            #$param.InstallWebRole = (($machine.Name + "." + $machine.domainname) -in $URLs)
            if (($machine.Name + '.' + $machine.domainname) -notin $URLs)
            {
                Write-ScreenInfo -Message 'Http based AIA or CDP specified but is NOT pointing to this server. Make sure to MANUALLY establish this web server and DNS name as well as copy AIA and CRL(s) to this web server' -Type Warning
            }
        }
    }


    #Setting DatabaseDirectoryh and LogDirectory to blank if automatic is selected. Hence, default locations will be used (%WINDIR%\System32\CertLog)
    if ($param.DatabaseDirectory -eq '<auto>') { $param.DatabaseDirectory = '' }
    if ($param.LogDirectory -eq '<auto>') { $param.LogDirectory = '' }


    #Test for existence of AIA location
    if (!($param.UseLDAPAia) -and !($param.UseHTTPAia)) { Write-ScreenInfo -Message 'AIA information will not be included in issued certificates because both LDAP and HTTP based AIA has been disabled' -Type Warning }

    #Test for existence of CDP location
    if (!($param.UseLDAPCrl) -and !($param.UseHTTPCrl)) { Write-ScreenInfo -Message 'CRL information will not be included in issued certificates because both LDAP and HTTP based CRLs has been disabled' -Type Warning }


    if (!($param.InstallWebRole) -and ($param.InstallWebEnrollment))
    {
        Write-Error -Message "InstallWebRole is set to No while InstallWebEnrollment is set to Yes. This is not possible. `
            Specified value for InstallWebRole is: $($param.InstallWebRole) `
        Specified value for InstallWebEnrollment is: $($param.InstallWebEnrollment)"
        return
    }



    if ('<auto>' -eq $param.DoNotLoadDefaultTemplates)
    {
        #Only for Root CA server
        if ($param.CaType -like '*Root*')
        {
            if (Get-LabVM -Role CaSubordinate -ErrorAction SilentlyContinue)
            {
                Write-ScreenInfo -Message 'Default templates will be removed (not published) except "SubCA" template, since this is an Enterprise Root CA and Subordinate CA(s) is present in the lab' -Type Verbose
                $param.DoNotLoadDefaultTemplates = $True
            }
            else
            {
                $param.DoNotLoadDefaultTemplates = $False
            }
        }
        else
        {
            $param.DoNotLoadDefaultTemplates = $False
        }
    }
    #endregion ----- Calculations -----


    $job = @()
    $targets = (Get-LabVM -Role FirstChildDC).Name
    foreach ($target in $targets)
    {
        $job += Sync-LabActiveDirectory -ComputerName $target -AsJob -PassThru
    }
    Wait-LWLabJob -Job $job -Timeout 15 -NoDisplay
    $targets = (Get-LabVM -Role DC).Name
    foreach ($target in $targets)
    {
        $job += Sync-LabActiveDirectory -ComputerName $target -AsJob -PassThru
    }
    Wait-LWLabJob -Job $job -Timeout 15 -NoDisplay

    $param.PreDelaySeconds = $PreDelaySeconds

    Write-PSFMessage -Message "Starting install of $($param.CaType) role on machine '$($machine.Name)'"
    $job = Install-LWLabCAServers @param
    if ($PassThru)
    {
        $job
    }

    Write-LogFunctionExit
}
#endregion Install-LabCAMachine

#region Get-LabCAInstallCertificates
function Get-LabCAInstallCertificates
{

    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [AutomatedLab.Machine[]]$Machines
    )

    begin
    {
        Write-LogFunctionEntry

        if (-not (Test-Path -Path "$((Get-Lab).LabPath)\Certificates"))
        {
            New-Item -Path "$((Get-Lab).LabPath)\Certificates" -ItemType Directory | Out-Null
        }
    }

    process
    {
        #Get all certificates from CA servers and place temporalily on host machine
        foreach ($machine in $machines)
        {
            $sourceFile = Invoke-LabCommand -ComputerName $machine -ScriptBlock {
                (Get-Item -Path 'C:\Windows\System32\CertSrv\CertEnroll\*.crt' |
                    Sort-Object -Property LastWritten -Descending |
                Select-Object -First 1).FullName
            } -PassThru -NoDisplay

            $tempDestination = "$((Get-Lab).LabPath)\Certificates\$($Machine).crt"

            $caSession = New-LabPSSession -ComputerName $machine.Name
            Receive-File -Source $sourceFile -Destination $tempDestination -Session $caSession
        }
    }

    end
    {
        Write-LogFunctionExit
    }

}
#endregion Get-LabCAInstallCertificates

#region Publish-LabCAInstallCertificates
function Publish-LabCAInstallCertificates
{

    param (
        [switch]$PassThru
    )

    #Install the certificates to all machines in lab

    Write-LogFunctionEntry

    $targetMachines = @()

    #Publish to all Root DC machines (only one DC from each Root domain)
    $targetMachines += Get-LabVM -All -IsRunning | Where-Object { ($_.Roles.Name -eq 'RootDC') -or ($_.Roles.Name -eq 'FirstChildDC') }

    #Also publish to any machines not domain joined
    $targetMachines += Get-LabVM -All -IsRunning | Where-Object { -not $_.IsDomainJoined }
    Write-PSFMessage -Message "Target machines for publishing: '$($targetMachines -join ', ')'"

    $machinesNotTargeted = Get-LabVM -All | Where-Object { $_.Roles.Name -notcontains 'RootDC' -and $_.Name -notin $targetMachines.Name -and -not $_.IsDomainJoined }

    if ($machinesNotTargeted)
    {
        Write-ScreenInfo -Message 'The following machines are not updated with Root and Subordinate certificates from the newly installed Root and Subordinate certificate servers. Please update these manually.' -Type Warning
        $machinesNotTargeted | ForEach-Object { Write-ScreenInfo -Message "  $_" -Type Warning }
    }

    foreach ($machine in $targetMachines)
    {
        $machineSession = New-LabPSSession -ComputerName $machine
        foreach ($certfile in (Get-ChildItem -Path "$((Get-Lab).LabPath)\Certificates"))
        {
            Write-PSFMessage -Message "Send file '$($certfile.FullName)' to 'C:\Windows\$($certfile.BaseName).crt'"
            Send-File -SourceFilePath $certfile.FullName -DestinationFolderPath /Windows -Session $machineSession
        }

        $scriptBlock = {
            foreach ($certfile in (Get-ChildItem -Path 'C:\Windows\*.crt'))
            {
                Write-Verbose -Message "Install certificate ($((Get-PfxCertificate $certfile.FullName).Subject)) on machine $(hostname)"
                #If workgroup, publish to local store
                if ((Get-WmiObject -Namespace root\cimv2 -Class Win32_ComputerSystem).DomainRole -eq 2)
                {
                    Write-Verbose -Message '  Machine is not domain joined. Publishing certificate to local store'

                    $Cert = Get-PfxCertificate $certfile.FullName
                    if ($Cert.GetNameInfo('SimpleName', $false) -eq $Cert.GetNameInfo('SimpleName', $true))
                    {
                        $targetStore = 'Root'
                    }
                    else
                    {
                        $targetStore = 'CA'
                    }

                    if (-not (Get-ChildItem -Path "Cert:\LocalMachine\$targetStore" | Where-Object { $_.ThumbPrint -eq (Get-PfxCertificate $($certfile.FullName)).ThumbPrint }))
                    {
                        $result = Invoke-Expression -Command "certutil -addstore -f $targetStore c:\Windows\$($certfile.BaseName).crt"

                        if ($result | Where-Object { $_ -like '*already in store*' })
                        {
                            Write-Verbose -Message "  Certificate ($((Get-PfxCertificate $certfile.FullName).Subject)) is already in local store on $(hostname)"
                        }
                        elseif ($result | Where-Object { $_ -like '*added to store.' })
                        {
                            Write-Verbose -Message "  Certificate ($((Get-PfxCertificate $certfile.FullName).Subject)) added to local store on $(hostname)"
                        }
                        else
                        {
                            Write-Error -Message "Certificate ($((Get-PfxCertificate $certfile.FullName).Subject)) was not added to local store on $(hostname)"
                        }
                    }
                    else
                    {
                        Write-Verbose -Message "  Certificate ($((Get-PfxCertificate $certfile.FullName).Subject)) is already in local store on $(hostname)"
                    }
                }
                else #If domain joined, publish to AD Enterprise store
                {
                    Write-Verbose -Message '  Machine is domain controller. Publishing certificate to AD Enterprise store'

                    if (((Get-PfxCertificate $($certfile.FullName)).Subject) -like '*root*')
                    {
                        $dsPublishStoreName = 'RootCA'
                        $readStoreName = 'Root'
                    }
                    else
                    {
                        $dsPublishStoreName = 'SubCA'
                        $readStoreName = 'CA'
                    }


                    if (-not (Get-ChildItem "Cert:\LocalMachine\$readStoreName" | Where-Object { $_.ThumbPrint -eq (Get-PfxCertificate $($certfile.FullName)).ThumbPrint }))
                    {
                        $result = Invoke-Expression -Command "certutil -f -dspublish c:\Windows\$($certfile.BaseName).crt $dsPublishStoreName"

                        if ($result | Where-Object { $_ -like '*Certificate added to DS store*' })
                        {
                            Write-Verbose -Message "  Certificate ($((Get-PfxCertificate $certfile.FullName).Subject)) added to DS store on $(hostname)"
                        }
                        elseif ($result | Where-Object { $_ -like '*Certificate already in DS store*' })
                        {
                            Write-Verbose -Message "  Certificate ($((Get-PfxCertificate $certfile.FullName).Subject)) is already in DS store on $(hostname)"
                        }
                        else
                        {
                            Write-Error -Message "Certificate ($((Get-PfxCertificate $certfile.FullName).Subject)) was not added to DS store on $(hostname)"
                        }
                    }
                    else
                    {
                        Write-Verbose -Message "  Certificate ($((Get-PfxCertificate $certfile.FullName).Subject)) is already in DS store on $(hostname)"
                    }
                }
            }
        }

        $job = Invoke-LabCommand -ActivityName 'Publish Lab CA(s) and install certificates' -ComputerName $machine -ScriptBlock $scriptBlock -NoDisplay -AsJob -PassThru
        if ($PassThru) { $job }
    }

    Write-LogFunctionExit
}
#endregion Publish-LabCAInstallCertificates

#region Enable-LabCertificateAutoenrollment
function Enable-LabCertificateAutoenrollment
{

    [cmdletBinding()]

    param
    (
        [switch]$Computer,

        [switch]$User,

        [switch]$CodeSigning,

        [string]$CodeSigningTemplateName = 'LabCodeSigning'
    )

    Write-LogFunctionEntry

    $issuingCAs = Get-LabIssuingCA

    Write-PSFMessage -Message "All issuing CAs: '$($issuingCAs -join ', ')'"

    if (-not $issuingCAs)
    {
        Write-ScreenInfo -Message 'No issuing CA(s) found. Skipping operation.'
        return
    }

    Write-ScreenInfo -Message 'Configuring certificate auto enrollment' -TaskStart

    $domainsToProcess = (Get-LabVM -Role RootDC, FirstChildDC, DC | Where-Object DomainName -in $issuingCAs.DomainName | Group-Object DomainName).Name | Sort-Object -Unique
    Write-PSFMessage -Message "Domains to process: '$($domainsToProcess -join ', ')'"

    $issuingCAsToProcess = ($issuingCAs | Where-Object DomainName -in $domainsToProcess).Name
    Write-PSFMessage -Message "Issuing CAs to process: '$($issuingCAsToProcess -join ', ')'"

    $dcsToProcess = @()
    foreach ($domain in $issuingCAs.DomainName)
    {
        $dcsToProcess += Get-LabVM -Role RootDC | Where-Object { $domain -like "*$($_.DomainName)"}
    }
    $dcsToProcess = $dcsToProcess.Name | Sort-Object -Unique

    Write-PSFMessage -Message "DCs to process: '$($dcsToProcess -join ', ')'"


    if ($Computer)
    {
        Write-ScreenInfo -Message 'Configuring permissions for computer certificates' -NoNewLine
        $job = Invoke-LabCommand -ComputerName $dcsToProcess -ActivityName 'Configure permissions on workstation authentication template on CAs' -NoDisplay -AsJob -PassThru -ScriptBlock `
        {
            $domainName = ([adsi]'LDAP://RootDSE').DefaultNamingContext

            dsacls "CN=Workstation,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,$domainName" /G 'Domain Computers:GR'
            dsacls "CN=Workstation,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,$domainName" /G 'Domain Computers:CA;Enroll'
            dsacls "CN=Workstation,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,$domainName" /G 'Domain Computers:CA;AutoEnrollment'
        }
        Wait-LWLabJob -Job $job -ProgressIndicator 20 -Timeout 30 -NoDisplay -NoNewLine


        $job = Invoke-LabCommand -ComputerName $issuingCAsToProcess -ActivityName 'Publish workstation authentication certificate template on CAs' -NoDisplay -AsJob -PassThru -ScriptBlock {
            certutil.exe -SetCAtemplates +Workstation
            #Add-CATemplate -Name 'Workstation' -Confirm:$false
        }
        Wait-LWLabJob -Job $job -ProgressIndicator 20 -Timeout 30 -NoDisplay
    }

    if ($CodeSigning)
    {
        Write-ScreenInfo -Message "Enabling code signing certificate and enabling auto enrollment of these. Code signing certificate template name: '$CodeSigningTemplateName'" -NoNewLine
        $job = Invoke-LabCommand -ComputerName $dcsToProcess -ActivityName 'Create certificate template for Code Signing' -AsJob -PassThru -NoDisplay -ScriptBlock {
            param ($NewCodeSigningTemplateName)

            $ConfigContext = ([adsi]'LDAP://RootDSE').ConfigurationNamingContext
            $adsi = [adsi]"LDAP://CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext"

            if (-not ($adsi.Children | Where-Object {$_.distinguishedName -like "CN=$NewCodeSigningTemplateName,*"}))
            {
                Write-Verbose -Message "Creating certificate template with name: $NewCodeSigningTemplateName"

                $codeSigningOrgiginalTemplate = $adsi.Children | Where-Object {$_.distinguishedName -like 'CN=CodeSigning,*'}


                $newCertTemplate = $adsi.Create('pKICertificateTemplate', "CN=$NewCodeSigningTemplateName")
                $newCertTemplate.put('distinguishedName',"CN=$NewCodeSigningTemplateName,CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext")

                $newCertTemplate.put('flags','32')
                $newCertTemplate.put('displayName',$NewCodeSigningTemplateName)
                $newCertTemplate.put('revision','100')
                $newCertTemplate.put('pKIDefaultKeySpec','2')
                $newCertTemplate.SetInfo()


                $newCertTemplate.put('pKIMaxIssuingDepth','0')
                $newCertTemplate.put('pKICriticalExtensions','2.5.29.15')
                $newCertTemplate.put('pKIExtendedKeyUsage','1.3.6.1.5.5.7.3.3')
                $newCertTemplate.put('pKIDefaultCSPs','2,Microsoft Base Cryptographic Provider v1.0, 1,Microsoft Enhanced Cryptographic Provider v1.0')
                $newCertTemplate.put('msPKI-RA-Signature','0')
                $newCertTemplate.put('msPKI-Enrollment-Flag','32')
                $newCertTemplate.put('msPKI-Private-Key-Flag','16842752')
                $newCertTemplate.put('msPKI-Certificate-Name-Flag','-2113929216')
                $newCertTemplate.put('msPKI-Minimal-Key-Size','2048')
                $newCertTemplate.put('msPKI-Template-Schema-Version','2')
                $newCertTemplate.put('msPKI-Template-Minor-Revision','2')

                $LastTemplateNumber = $adsi.Children | Select-Object @{n='OIDNumber';e={[int]($_.'msPKI-Cert-Template-OID'.split('.')[-1])}} | Sort-Object -Property OIDNumber | Select-Object -ExpandProperty OIDNumber -Last 1
                $LastTemplateNumber++
                $OID = ((($adsi.Children | Select-Object -First 1).'msPKI-Cert-Template-OID'.replace('.', '\') | Split-Path -Parent) + "\$LastTemplateNumber").replace('\', '.')

                $newCertTemplate.put('msPKI-Cert-Template-OID',$OID)
                $newCertTemplate.put('msPKI-Certificate-Application-Policy','1.3.6.1.5.5.7.3.3')

                $newCertTemplate.SetInfo()


                $newCertTemplate.pKIKeyUsage = $codeSigningOrgiginalTemplate.pKIKeyUsage
                #$NewCertTemplate.pKIKeyUsage = "176" (special DSC Template)

                $newCertTemplate.pKIExpirationPeriod = $codeSigningOrgiginalTemplate.pKIExpirationPeriod
                $newCertTemplate.pKIOverlapPeriod = $codeSigningOrgiginalTemplate.pKIOverlapPeriod
                $newCertTemplate.SetInfo()

                $domainName = ([ADSI]'LDAP://RootDSE').DefaultNamingContext


                dsacls "CN=$NewCodeSigningTemplateName,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,$domainName" /G 'Domain Users:GR'
                dsacls "CN=$NewCodeSigningTemplateName,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,$domainName" /G 'Domain Users:CA;Enroll'
                dsacls "CN=$NewCodeSigningTemplateName,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,$domainName" /G 'Domain Users:CA;AutoEnrollment'
            }
            else
            {
                Write-Verbose -Message "Certificate template with name '$NewCodeSigningTemplateName' already exists"
            }
        } -ArgumentList $CodeSigningTemplateName
        Wait-LWLabJob -Job $job -ProgressIndicator 20 -Timeout 30 -NoDisplay


        Write-ScreenInfo -Message 'Publishing Code Signing certificate template on all issuing CAs' -NoNewLine
        $job = Invoke-LabCommand -ComputerName $issuingCAsToProcess -ActivityName 'Publishing code signing certificate template' -NoDisplay -AsJob -PassThru -ScriptBlock {
            param ($NewCodeSigningTemplateName)

            $ConfigContext = ([ADSI]'LDAP://RootDSE').ConfigurationNamingContext
            $adsi = [ADSI]"LDAP://CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext"
            while (-not ($adsi.Children | Where-Object {$_.distinguishedName -like "CN=$NewCodeSigningTemplateName,*"}))
            {
                gpupdate.exe /force
                certutil.exe -pulse

                $adsi = [ADSI]"LDAP://CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext"
                #Start-Sleep -Seconds 2
            }
            Start-Sleep -Seconds 2

            $start = (Get-Date)
            $done = $false
            do
            {
                Write-Verbose -Message "Trying to publish '$NewCodeSigningTemplateName'"
                $result = certutil.exe -SetCAtemplates "+$NewCodeSigningTemplateName"
                if ($result -like '*successfully*')
                {
                    $done = $True
                }
                else
                {
                    gpupdate.exe /force
                    certutil.exe -pulse
                }
            }
            until ($done -or (((Get-Date)-$start)).TotalMinutes -ge 30)
            Write-Verbose -Message 'DONE'


            if (((Get-Date)-$start).TotalMinutes -ge 10)
            {
                Write-Error -Message "Could not publish certificate template '$NewCodeSigningTemplateName' as it was not found after 10 minutes"
            }
        } -ArgumentList $CodeSigningTemplateName
        Wait-LWLabJob -Job $job -ProgressIndicator 20 -Timeout 15 -NoDisplay
    }


    $machines = Get-LabVM | Where-Object {$_.DomainName -in $domainsToProcess}
    if ($Computer -and ($User -or $CodeSigning))
    {
        $out = 'computer and user'
    }
    elseif ($Computer)
    {
        $out = 'computer'
    }
    else
    {
        $out = 'user'
    }

    Write-ScreenInfo -Message "Enabling auto enrollment of $out certificates" -NoNewLine
    $job = Invoke-LabCommand -ComputerName $machines -ActivityName 'Configuring machines for auto enrollment and performing auto enrollment of certificates' -NoDisplay -AsJob -PassThru -ScriptBlock `
    {
        Add-Type -TypeDefinition $gpoType
        Set-Item WSMan:\localhost\Client\TrustedHosts '*' -Force
        Enable-WSManCredSSP -Role Client -DelegateComputer * -Force

        $value = [GPO.Helper]::GetGroupPolicy($true, 'SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentials', '1')
        if ($value -ne '*' -and $value -ne 'WSMAN/*')
        {
            [GPO.Helper]::SetGroupPolicy($true, 'Software\Policies\Microsoft\Windows\CredentialsDelegation', 'AllowFreshCredentials', 1) | Out-Null
            [GPO.Helper]::SetGroupPolicy($true, 'Software\Policies\Microsoft\Windows\CredentialsDelegation', 'ConcatenateDefaults_AllowFresh', 1) | Out-Null
            [GPO.Helper]::SetGroupPolicy($true, 'Software\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentials', '1', 'WSMAN/*') | Out-Null
        }

        Enable-AutoEnrollment -Computer:$Computer -UserOrCodeSigning:($User -or $CodeSigning)

    } -Variable (Get-Variable gpoType, Computer, User, CodeSigning) -Function (Get-Command Enable-AutoEnrollment)
    Wait-LWLabJob -Job $job -ProgressIndicator 20 -Timeout 30 -NoDisplay


    Write-ScreenInfo -Message 'Finished configuring certificate auto enrollment' -TaskEnd

    Write-LogFunctionExit
}
#endregion Enable-LabCertificateAutoenrollment

try
{
    [Pki.Period]$temp = $null
}
catch
{
    Add-Type -TypeDefinition $pkiInternalsTypes
}

try
{
    [System.Security.Cryptography.X509Certificates.Win32]$temp = $null
}
catch
{
    Add-Type -TypeDefinition $certStoreTypes
}
