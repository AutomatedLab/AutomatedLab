function Write-UnattendedCloudInitFile
{
    param
    (
        [string]
        $Content,

        [string]
        $DestinationPath,

        [switch]
        $Append
    )
   
    $script:un['autoinstall']['user-data']['write_files'] += @{
        append  = $Append.IsPresent
        path    = $DestinationPath
        content = "{0}`n" -f $Content
    }
}
