function Set-UnattendedYastDomain {
    param (
        [Parameter(Mandatory = $true)]
        [string]$DomainName,

        [Parameter(Mandatory = $true)]
        [string]$Username,

        [Parameter(Mandatory = $true)]
        [string]$Password,

        [Parameter()]
        [string]$OrganizationalUnit
    )

    $smbClientNode = $script:un.CreateElement('samba-client', $script:nsm.LookupNamespace('un'))
    $boolAttrib = $script:un.CreateAttribute('config', 'type', $script:nsm.LookupNamespace('config'))
    $boolAttrib.InnerText = 'boolean'
    $adNode = $script:un.CreateElement('active_directory', $script:nsm.LookupNamespace('un'))
    $kdc = $script:un.CreateElement('kdc', $script:nsm.LookupNamespace('un'))
    $disableDhcp = $script:un.CreateElement('disable_dhcp_hostname', $script:nsm.LookupNamespace('un'))
    $globalNode = $script:un.CreateElement('global', $script:nsm.LookupNamespace('un'))
    $securityNode = $script:un.CreateElement('security', $script:nsm.LookupNamespace('un'))
    $shellNode = $script:un.CreateElement('template_shell', $script:nsm.LookupNamespace('un'))
    $guestNode = $script:un.CreateElement('usershare_allow_guests', $script:nsm.LookupNamespace('un'))
    $domainNode = $script:un.CreateElement('workgroup', $script:nsm.LookupNamespace('un'))
    $joinNode = $script:un.CreateElement('join', $script:nsm.LookupNamespace('un'))
    $joinUserNode = $script:un.CreateElement('user', $script:nsm.LookupNamespace('un'))
    $joinPasswordNode = $script:un.CreateElement('password', $script:nsm.LookupNamespace('un'))
    $homedirNode = $script:un.CreateElement('mkhomedir', $script:nsm.LookupNamespace('un'))
    $winbindNode = $script:un.CreateElement('winbind', $script:nsm.LookupNamespace('un'))
    $mapAttr = $script:un.CreateAttribute('t')
    $mapAttr.InnerText = 'map'

    $null = $disableDhcp.Attributes.Append($boolAttrib)
    $null = $homedirNode.Attributes.Append($boolAttrib)
    $null = $winbindNode.Attributes.Append($boolAttrib)
    $null = $smbClientNode.Attributes.Append($mapAttr)
    $null = $adNode.Attributes.Append($mapAttr)

    $kdc.InnerText = $DomainName

    $disableDhcp.InnerText = 'true'
    $securityNode.InnerText = 'ADS'
    $shellNode.InnerText = '/bin/bash'
    $guestNode.InnerText = 'no'
    $domainNode.InnerText = $DomainName
    $joinUserNode.InnerText = $Username
    $joinPasswordNode.InnerText = $Password
    $homedirNode.InnerText = 'true'
    $winbindNode.InnerText = 'false'

    $null = $adNode.AppendChild($kdc)
    $null = $globalNode.AppendChild($securityNode)
    $null = $globalNode.AppendChild($shellNode)
    $null = $globalNode.AppendChild($guestNode)
    $null = $globalNode.AppendChild($domainNode)
    $null = $joinNode.AppendChild($joinUserNode)
    $null = $joinNode.AppendChild($joinPasswordNode)
    $null = $smbClientNode.AppendChild($disableDhcp)
    $null = $smbClientNode.AppendChild($globalNode)
    $null = $smbClientNode.AppendChild($adNode)
    $null = $smbClientNode.AppendChild($joinNode)
    $null = $smbClientNode.AppendChild($homedirNode)
    $null = $smbClientNode.AppendChild($winbindNode)

    $null = $script:un.DocumentElement.AppendChild($smbClientNode)

    <# SSSD configuration JSON - generated on running OpenSUSE client
    According to what docs I found this is also valid for older editions
    #>
    $sssdHash = @{
        "sssd" = @{
            "conf"               = @{
                "sssd" = @{
                    "config_file_version" = "2"
                    "services"            = @(
                        "pam"
                        "nss"
                    )
                    "domains"             = @(
                        $DomainName
                    )
                }
                "pam"  = @{}
                "nss"  = @{}
            }
            "domain/$DomainName" = @{
                "id_provider"          = "ldap"
                "auth_provider"        = "ldap"
                "ldap_schema"          = "rfc2307bis"
                "enumerate"            = "false"
                "cache_credentials"    = "false"
                "case_sensitive"       = "true"
                "ldap_use_tokengroups" = "true"
                "ldap_uri"             = "ldap://$DomainName"
                "ldap_tls_reqcert"     = "allow"
            }
            "pam"                = $true
            "nss"                = @(
                "passwd"
                "group"
            )
            "enabled"            = $true
        }
        "ldap" = @{
            "pam" = $false
            "nss" = @()
        }
        "krb"  = @{
            "conf" = @{
                "include"      = @()
                "libdefaults"  = @{}
                "realms"       = @{}
                "domain_realm" = @{}
                "logging"      = @{}
            }
            "pam"  = $false
        }
        "aux"  = @{
            "autofs"    = $false
            "nscd"      = $false
            "mkhomedir" = $true
        }
        "ad"   = @{
            "domain"             = ""
            "user"               = ""
            "ou"                 = ""
            "pass"               = ""
            "overwrite_smb_conf" = $false
            "update_dns"         = $true
            "dnshostname"        = ""
        }
    }

    $authClientNode = $script:un.CreateElement('auth-client', $script:nsm.LookupNamespace('un'))
    $null = $authClientNode.Attributes.Append($mapAttr)
    $sssdConf = $script:un.CreateElement('conf_json', $script:nsm.LookupNamespace('un'))
    $sssdConf.InnerText = $sssdHash | ConvertTo-Json -Depth 42 -Compress
    $null = $authClientNode.AppendChild($sssdConf)
    $script:un.DocumentElement.AppendChild($authClientNode)
}