function Get-LWProductKey {
    <#
    .SYNOPSIS
        Retrieves product key for a specific Windows OS from XML file.

    .DESCRIPTION
        Uses XPath to query an XML file containing Windows product keys.

    .PARAMETER OSName
        The exact Operating System name as it appears in the XML file.

    .PARAMETER XmlPath
        Path to the XML file containing product keys. Defaults to "ProductKeys.xml"

    .EXAMPLE
        .\Get-ProductKey.ps1 -OSName "Windows 10 Pro"

    .EXAMPLE
        .\Get-ProductKey.ps1 -OSName "Windows Server 2019 Standard" -XmlPath "C:\Keys\ProductKeys.xml"

    .EXAMPLE
        # Using partial match with wildcards in XPath
        [xml]$xml = Get-Content "ProductKeys.xml"
        $xml.SelectNodes("//ProductKey[contains(@OperatingSystemName, 'Windows 10')]")
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$OSName,

        [Parameter(Mandatory = $false)]
        [string]$XmlPath = (Get-PSFConfigValue -FullName AutomatedLab.ProductKeyFilePath)
    )

    if (-not (Test-Path $XmlPath)) {
        Write-Error "Product key XML file not found at path: '$XmlPath'"
    }

    [xml]$xml = Get-Content $XmlPath

    $xpath = "//ProductKey[@OperatingSystemName='$OSName']"
    $result = $xml.SelectSingleNode($xpath)

    if ($result) {
        Write-Verbose "Operating System: $($result.OperatingSystemName)"
        Write-Verbose "Product Key: $($result.Key)"
        Write-Verbose "Version: $($result.Version)"
    }
    else {
        Write-Verbose "No product key found for OS: '$OSName'"
    }

    return $result.Key
}
