# Initialize settings
Set-PSFConfig -Module AutomatedLab.Recipe -Name SnippetStore -Value (Join-Path -Path $HOME -ChildPath 'automatedlab/snippets') -Validation string -Initialize -Description 'Snippet and recipe storage location'
Set-PSFConfig -Module AutomatedLab.Recipe -Name UseAzureBlobStorage -Value $false -Validation bool -Description 'Use Azure instead of local store. Required directories in container: Snippet, Sample. Custom roles currently not supported' -Initialize
Set-PSFConfig -Module AutomatedLab.Recipe -Name AzureBlobStorage.AccountName -Value "" -Validation string -Description "Storage account name to use" -Initialize
Set-PSFConfig -Module AutomatedLab.Recipe -Name AzureBlobStorage.ResourceGroupName -Value "" -Validation string -Description "ResourceGroupName to use" -Initialize
Set-PSFConfig -Module AutomatedLab.Recipe -Name AzureBlobStorage.ContainerName -Value "" -Validation string -Description "Storage container to use" -Initialize

Update-LabSnippet