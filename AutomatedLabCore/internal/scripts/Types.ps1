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
    [GPO.Helper]$temp = $null
}
catch
{
    Add-Type -TypeDefinition $gpoType -IgnoreWarnings 3>&1
}

try
{
    [System.Security.Cryptography.X509Certificates.Win32]$temp = $null
}
catch
{
    Add-Type -TypeDefinition $certStoreTypes
}
