﻿function Get-LabAzureAvailableSku
{
    [CmdletBinding(DefaultParameterSetName = 'DisplayName')]
    param
    (
        [Parameter(Mandatory, ParameterSetName = 'DisplayName')]
        [Alias('Location')]
        [string]
        $DisplayName,

        [Parameter(Mandatory, ParameterSetName = 'Name')]
        [string]
        $LocationName
    )

    Test-LabHostConnected -Throw -Quiet

    # Server
    $azLocation = Get-AzLocation | Where-Object { $_.DisplayName -eq $DisplayName -or $_.Location -eq $LocationName }
    if (-not $azLocation)
    {
        Write-ScreenInfo -Type Error -Message "No location found matching DisplayName '$DisplayName' or Name '$LocationName'"
    }
    $publishers = Get-AzVMImagePublisher -Location $azLocation.Location
    
    # For each publisher, get latest image AND REQUEST THAT SPECIFIC IMAGE to be able to see the Hyper-V generation. Marvelous.
    $publishers |
    Where-Object PublisherName -eq 'MicrosoftWindowsServer' |
    Get-AzVMImageOffer |
    Get-AzVMImageSku |
    Get-AzVMImage |
    Group-Object -Property Skus, Offer |
    ForEach-Object { $_.Group | Sort-Object -Property PublishedDate -Descending | Select-Object -First 1 | Get-AzVmImage } |
    Where-Object PurchasePlan -eq $null

    # Linux
    # Ubuntu - official
    $publishers |
    Where-Object PublisherName -eq 'Canonical' |
    Get-AzVMImageOffer |
    Where-Object Offer -match '0001-com-ubuntu-server-\w+$' |
    Get-AzVMImageSku |
    Where-Object Skus -notmatch 'arm64' |
    Get-AzVMImage |
    Group-Object -Property Skus, Offer |
    ForEach-Object { $_.Group | Sort-Object -Property PublishedDate -Descending | Select-Object -First 1 | Get-AzVmImage } |
    Where-Object PurchasePlan -eq $null

    # RedHat - official
    $publishers |
    Where-Object PublisherName -eq 'RedHat' |
    Get-AzVMImageOffer |
    Where-Object Offer -eq 'RHEL' |
    Get-AzVMImageSku |
    Where-Object Skus -notmatch '(RAW|LVM|CI)' |
    Get-AzVMImage |
    Group-Object -Property Skus, Offer |
    ForEach-Object { $_.Group | Sort-Object -Property PublishedDate -Descending | Select-Object -First 1 | Get-AzVmImage } |
    Where-Object PurchasePlan -eq $null

    # CentOS - Roguewave, sounds slightly suspicious
    $publishers |
    Where-Object PublisherName -eq 'OpenLogic' |
    Get-AzVMImageOffer |
    Where-Object Offer -eq CentOS |
    Get-AzVMImageSku |
    Get-AzVMImage |
    Group-Object -Property Skus, Offer |
    ForEach-Object { $_.Group | Sort-Object -Property PublishedDate -Descending | Select-Object -First 1 | Get-AzVmImage } |
    Where-Object PurchasePlan -eq $null

    # Kali
    $publishers |
    Where-Object PublisherName -eq 'Kali-Linux' |
    Get-AzVMImageOffer |
    Get-AzVMImageSku |
    Get-AzVMImage |
    Group-Object -Property Skus, Offer |
    ForEach-Object { $_.Group | Sort-Object -Property PublishedDate -Descending | Select-Object -First 1 | Get-AzVmImage } |
    Where-Object PurchasePlan -eq $null

    # Desktop
    $publishers |
    Where-Object PublisherName -eq 'MicrosoftWindowsDesktop' |
    Get-AzVMImageOffer |
    Get-AzVMImageSku |
    Get-AzVMImage |
    Group-Object -Property Skus, Offer |
    ForEach-Object { $_.Group | Sort-Object -Property PublishedDate -Descending | Select-Object -First 1 | Get-AzVmImage } |
    Where-Object PurchasePlan -eq $null

    # SQL
    $publishers |
    Where-Object PublisherName -eq 'MicrosoftSQLServer' |
    Get-AzVMImageOffer |
    Get-AzVMImageSku |
    Get-AzVMImage |
    Where-Object Skus -in 'Standard','Enterprise' |
    Group-Object -Property Skus, Offer |
    ForEach-Object { $_.Group | Sort-Object -Property PublishedDate -Descending | Select-Object -First 1 | Get-AzVmImage } |
    Where-Object PurchasePlan -eq $null

    # VisualStudio
    $publishers |
    Where-Object PublisherName -eq 'MicrosoftVisualStudio' |
    Get-AzVMImageOffer |
    Get-AzVMImageSku |
    Get-AzVMImage |
    Where-Object Offer -eq 'VisualStudio' |
    Group-Object -Property Skus, Offer |
    ForEach-Object { $_.Group | Sort-Object -Property PublishedDate -Descending | Select-Object -First 1 | Get-AzVmImage } |
    Where-Object PurchasePlan -eq $null

    # Client OS
    $publishers |
    Where-Object PublisherName -eq 'MicrosoftVisualStudio' |
    Get-AzVMImageOffer |
    Get-AzVMImageSku |
    Get-AzVMImage |
    Where-Object Offer -eq 'Windows' |
    Group-Object -Property Skus, Offer |
    ForEach-Object { $_.Group | Sort-Object -Property PublishedDate -Descending | Select-Object -First 1 | Get-AzVmImage } |
    Where-Object PurchasePlan -eq $null

    # Sharepoint 2013 and 2016
    $publishers |
    Where-Object PublisherName -eq 'MicrosoftSharePoint' |
    Get-AzVMImageOffer |
    Get-AzVMImageSku |
    Get-AzVMImage |
    Where-Object Offer -eq 'MicrosoftSharePointServer' |
    Group-Object -Property Skus, Offer |
    ForEach-Object { $_.Group | Sort-Object -Property PublishedDate -Descending | Select-Object -First 1 | Get-AzVmImage } |
    Where-Object PurchasePlan -eq $null
}
