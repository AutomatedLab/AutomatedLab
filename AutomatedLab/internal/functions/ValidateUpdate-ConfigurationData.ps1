function ValidateUpdate-ConfigurationData
{
    param (
        [Parameter(Mandatory)]
        [hashtable]$ConfigurationData
    )

    if( -not $ConfigurationData.ContainsKey('AllNodes'))
    {
        $errorMessage = 'ConfigurationData parameter need to have property AllNodes.'
        $exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $errorMessage
        Write-Error -Exception $exception -Message $errorMessage -Category InvalidOperation -ErrorId ConfiguratonDataNeedAllNodes
        return $false
    }

    if($ConfigurationData.AllNodes -isnot [array])
    {
        $errorMessage = 'ConfigurationData parameter property AllNodes needs to be a collection.'
        $exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $errorMessage
        Write-Error -Exception $exception -Message $errorMessage -Category InvalidOperation -ErrorId ConfiguratonDataAllNodesNeedHashtable
        return $false
    }

    $nodeNames = New-Object -TypeName 'System.Collections.Generic.HashSet[string]' -ArgumentList ([System.StringComparer]::OrdinalIgnoreCase)
    foreach($Node in $ConfigurationData.AllNodes)
    {
        if($Node -isnot [hashtable] -or -not $Node.NodeName)
        {
            $errorMessage = "all elements of AllNodes need to be hashtable and has a property 'NodeName'."
            $exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $errorMessage
            Write-Error -Exception $exception -Message $errorMessage -Category InvalidOperation -ErrorId ConfiguratonDataAllNodesNeedHashtable
            return $false
        }

        if($nodeNames.Contains($Node.NodeName))
        {
            $errorMessage = "There are duplicated NodeNames '{0}' in the configurationData passed in." -f $Node.NodeName
            $exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $errorMessage
            Write-Error -Exception $exception -Message $errorMessage -Category InvalidOperation -ErrorId DuplicatedNodeInConfigurationData
            return $false
        }

        if($Node.NodeName -eq '*')
        {
            $AllNodeSettings = $Node
        }
        [void] $nodeNames.Add($Node.NodeName)
    }

    if($AllNodeSettings)
    {
        foreach($Node in $ConfigurationData.AllNodes)
        {
            if($Node.NodeName -ne '*')
            {
                foreach($nodeKey in $AllNodeSettings.Keys)
                {
                    if(-not $Node.ContainsKey($nodeKey))
                    {
                        $Node.Add($nodeKey, $AllNodeSettings[$nodeKey])
                    }
                }
            }
        }

        $ConfigurationData.AllNodes = @($ConfigurationData.AllNodes | Where-Object -FilterScript {
                $_.NodeName -ne '*'
            }
        )
    }

    return $true
}
