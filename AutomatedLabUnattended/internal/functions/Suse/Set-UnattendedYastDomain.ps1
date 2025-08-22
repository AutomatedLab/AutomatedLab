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

    <# SSSD configuration JSON - generated on running OpenSUSE client
    According to what docs I found this is also valid for older editions
    #>
    $sssdHash = @{
        "sssd" = @{
            "conf"    = @{
                "sssd"               = @{
                    "config_file_version" = "2"
                    "services"            = @(
                        "nss",
                        "pam"
                    )
                    "domains"             = @(
                        $DomainName
                    )
                }
                "nss"                = @{}
                "pam"                = @{}
                "domain/contoso.com" = @{
                    "id_provider"       = "ad"
                    "auth_provider"     = "ad"
                    "enumerate"         = "false"
                    "cache_credentials" = "false"
                    "case_sensitive"    = "true"
                }
            }
            "pam"     = $true
            "nss"     = @(
                "passwd"
                "group"
            )
            "enabled" = $true
        }
        "ldap" = @{
            "pam" = $false
            "nss" = @()
        }
        "krb"  = @{
            "conf" = @{
                "include"      = @()
                "libdefaults"  = @{
                    "dns_canonicalize_hostname" = "false"
                    "rdns"                      = "false"
                    dns_lookup_kdc              = "true"
                    "verify_ap_req_nofail"      = "true"
                    "default_ccache_name"       = "KEYRING:persistent:%{uid}"
                    "default_realm"             = $DomainName.ToUpper()
                    "clockskew"                 = "300"
                }
                "realms"       = @{
                    $DomainName.ToUpper() = @{
                        "default_domain" = $DomainName
                        "admin_server"   = $DomainName
                    }
                }
                "domain_realm" = @{
                    ".$DomainName" = $DomainName.ToUpper()
                }
                "logging"      = @{
                    "kdc"          = "FILE:/var/log/krb5/krb5kdc.log"
                    "admin_server" = "FILE:/var/log/krb5/kadmind.log"
                    "default"      = "SYSLOG:NOTICE:DAEMON"
                }
                "appdefaults"  = @{
                    "pam" = @{
                        "ticket_lifetime" = "1d"
                        "renew_lifetime"  = "1d"
                        "forwardable"     = "true"
                        "proxiable"       = "false"
                        "minimum_uid"     = "1"
                    }
                }
            }
            "pam"  = $false
        }
        "aux"  = @{
            "autofs"    = $false
            "nscd"      = $false
            "mkhomedir" = $true
        }
        "ad"   = @{
            "domain"             = $DomainName
            "user"               = $Username
            "ou"                 = $OrganizationalUnit
            "pass"               = $Password
            "overwrite_smb_conf" = $false
            "update_dns"         = $true
            "dnshostname"        = ""
        }
    }

    $authClientNode = $script:un.CreateElement('auth-client', $script:nsm.LookupNamespace('un'))
    $mapAttr = $script:un.CreateAttribute('t')
    $mapAttr.InnerText = 'map'
    $null = $authClientNode.Attributes.Append($mapAttr)
    $sssdConf = $script:un.CreateElement('conf_json', $script:nsm.LookupNamespace('un'))
    $sssdConf.InnerText = $sssdHash | ConvertTo-Json -Depth 42 -Compress
    $null = $authClientNode.AppendChild($sssdConf)
    $null = $script:un.DocumentElement.AppendChild($authClientNode)
}