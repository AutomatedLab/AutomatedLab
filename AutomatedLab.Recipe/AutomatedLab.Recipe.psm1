$importFolders = Get-ChildItem $PSScriptRoot -Include Import, Public, Private, Snippets -Recurse -Directory -ErrorAction SilentlyContinue
$imports = @()
$private = @()
$public = @()
$snippets = @()

Write-PSFMessage -Message "Importing from $($importFolders.Count) folders"
foreach ($folder in $importFolders)
{
    switch ( $folder.Name)
    {
        'Import'
        {
            $imports += Get-ChildItem -Path $folder.FullName -Filter *.ps1 -Recurse -File
        }
        'Public'
        {
            $public += Get-ChildItem -Path  $folder.FullName -Filter *.ps1 -Recurse -File
        }
        'Private'
        {
            $private += Get-ChildItem -Path  $folder.FullName -Filter *.ps1 -Recurse -File
        }
        'Snippets'
        {
            $snippets += Get-ChildItem -Path  $folder.FullName -Filter *.ps1 -Recurse -File
        }
    }
}

# Dot source the files
foreach ($import in @($public + $private))
{
    Try
    {
        . $import.FullName
    }
    Catch
    {
        Write-Error -Message "Failed to import function $($import.FullName): $_"
    }
}

# Import config
foreach ( $importScript in $imports)
{
    . $importScript.FullName
}


foreach ($import in $snippets)
{
    Try
    {
        . $import.FullName
    }
    Catch
    {
        Write-Error -Message "Failed to import snippet $($import.FullName): $_"
    }
}

Export-ModuleMember -Function $public.Basename
