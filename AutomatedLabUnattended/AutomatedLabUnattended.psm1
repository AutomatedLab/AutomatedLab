# Get public and private function definition files.
$importFolders = Get-ChildItem $PSScriptRoot -Include Types, Public, Private -Recurse -Directory -ErrorAction SilentlyContinue
$private = @()
$public = @()

Write-PSFMessage -Message "Importing from $($importFolders.Count) folders"
foreach ($folder in $importFolders)
{
    switch ( $folder.Name)
    {
        'Public'
        {
            $public += Get-ChildItem -Path $folder.FullName
        }
        'Private'
        {
            $private += Get-ChildItem -Path $folder.FullName -Recurse -Filter *.ps1
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

Export-ModuleMember -Function $public.Basename
