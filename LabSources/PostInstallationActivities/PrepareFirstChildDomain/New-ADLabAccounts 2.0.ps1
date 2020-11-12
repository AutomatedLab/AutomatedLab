#The file that contains the user information was created using [Spawner Data Generator http://spawner.sourceforge.net].
#The column definition used is saved in the file 'SpawnerTableDefinition.txt'.

#To add a new column to the output file containing the user name again (Name -> SamAccountName) the following PowerShell command line was used:
#	Get-Content .\datagen.txt | ForEach-Object { $_ + ',' + ($_ -split ',')[0] } | Out-File .\datagen2.txt

#The company names were taken from: http://www.click2inc.com/sample_names.htm and the the job titles were taken from
#http://quest.arc.nasa.gov/people/titles.html. The following PowerShell command were used to add quotes and remove comma
#	((Get-Content .\Companies.txt) | ForEach-Object { "`"$_`"" } | ForEach-Object { $_ -replace ",","" }) -join "|" | clip
#	((Get-Content .\JobTitles.txt) | ForEach-Object { "`"$_`"" } | ForEach-Object { $_ -replace ",","" }) -join "|" | clip

Import-Module -Name ActiveDirectory

if (-not(Test-Path -Path "$((Split-Path -Path $MyInvocation.MyCommand.Path -Parent))\LabUsers.txt"))
{
    Write-Error 'The input file 'LabUsers.txt' is missing.'
    return
}
if ((Get-ADOrganizationalUnit -Filter "Name -eq 'Lab Accounts'"))
{
    Write-Error "The OU 'Lab Accounts' does already exist"
    return
}

$start = Get-Date

#First we have to create a test OU in the current domain. We store the newly created OU...
$ou = New-ADOrganizationalUnit -Name 'Lab Accounts' -ProtectedFromAccidentalDeletion $false -PassThru
Write-Host "OU '$ou' created"
#to be able to create a new group right in there
$group = New-ADGroup -Name AllTestUsers -Path $ou -GroupScope Global -PassThru
Write-Host "Group '$group' created"

#We then import the TestUsers.txt file and pipe the imported data to New-ADUser.
#The cmdlet New-ADUSer creates the users in test OU (OU=Test,<DomainNamingContext>).
Write-Host 'Importing users from CSV file...' -NoNewline
Import-Csv -Path "$((Split-Path -Path $MyInvocation.MyCommand.Path -Parent))\LabUsers.txt" `
	-Header Name,GivenName,Surname,EmailAddress,OfficePhone,StreetAddress,PostalCode,City,Country,Title,Company,Department,Description,EmployeeID,SamAccountName |
	New-ADUser -Path $ou -ErrorAction SilentlyContinue
Write-Host 'done'

#Now the users should be in separate OUs, so we want to create one OU per country. In each OU is a group with the same name that all users of the OU are member of
#AD uses ISO 3166 two-character country/region codes. We create a hash table that contains the two-character country code as key and the full name as value.
#We read all test users and get the unique coutries. The RegionInfo class is use to convert the two-character coutry code into the full name
Write-Host 'Getting countries of all newly added accounts...' -NoNewline
$countries = @{}
Get-ADUser -Filter "Description -eq 'Testing'" -Properties Country |
	Sort-Object -Property Country -Unique |
	ForEach-Object {
		$region = New-Object System.Globalization.RegionInfo($_.Country)
		$countries.Add($region.Name, $region.EnglishName.Replace('.',''))
	}
Write-Host "done, identified '$($countries.Count)' countries"
Write-Host

#We now take the countries' full name and create the OUs and groups.
Write-Host 'Creating OUs and groups for countries and moving users...'
foreach ($country in $countries.GetEnumerator())
{
    Write-Host "Working on country '$($country.Value)'..." -NoNewline
	$countryOu = New-ADOrganizationalUnit -Name $country.Value -Path $ou -ProtectedFromAccidentalDeletion $false -PassThru
    Write-Host 'OU, ' -NoNewline
	$group = New-ADGroup -Name $country.Value -Path $countryOu -GroupScope Global -PassThru
	Add-ADGroupMember -Identity AllTestUsers -Members $group
    Write-Host 'Group, ' -NoNewline

    #Then we move the user to the respective OUs and add them to the corresponding group
    $countryUsers = Get-ADUser -Filter "Description -eq 'Testing' -and Country -eq '$($country.Key)'" -Properties Country
    $managers = @()
    1..4 | ForEach-Object { $managers += $countryUsers | Get-Random }

    $countryUsers | ForEach-Object { $_ | Set-ADUser -Manager ($managers | Get-Random) }
    Write-Host 'Managers, ' -NoNewline

    $password = 'Password5' | ConvertTo-SecureString -AsPlainText -Force
    $countryUsers | Set-ADAccountPassword -NewPassword $password
    Write-Host 'Password, ' -NoNewline

    $countryUsers | Enable-ADAccount
    Write-Host 'Enabled, ' -NoNewline

    Add-ADGroupMember -Identity $country.Value -Members $countryUsers
    $countryUsers | Move-ADObject -TargetPath $countryOu
    Write-Host 'Users moved'
}

$end = Get-Date
Write-Host
Write-Host "Script finished in $($end - $start)"