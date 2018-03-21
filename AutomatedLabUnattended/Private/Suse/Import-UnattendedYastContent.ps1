function Import-UnattendedYastContent
{
    param
    (
        [Parameter(Mandatory = $true)]
        [xml]
        $Content
    )

    $script:un = $Content
    $script:ns = @{
        un          = "http://www.suse.com/1.0/yast2ns"
        'un:config' = "http://www.suse.com/1.0/configns"
    }
    $script:nsm =   [System.Xml.XmlNamespaceManager]::new($script:un.NameTable)
    $script:nsm.AddNamespace('un',"http://www.suse.com/1.0/yast2ns")
    $script:nsm.AddNamespace('un:config',"http://www.suse.com/1.0/configns" )
}
