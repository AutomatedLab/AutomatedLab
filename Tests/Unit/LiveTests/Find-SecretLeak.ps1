function Find-SecretLeak
{
    <#
    .SYNOPSIS
        Lists every place in an object graph that holds a secret.

    .DESCRIPTION
        A SecureString or PSCredential anywhere in the graph counts as a leak, and so does a string, a dictionary key or a
        property value that contains one of the given texts. ConvertTo-Json cannot serve for this check, because it renders a
        SecureString as {"Length":n}. A graph that is nested deeper than the limit, for example because it contains itself, is
        reported as not inspected instead of being skipped. The output never contains the secret text.

    .PARAMETER InputObject
        The object graph to search: hashtables, arrays, custom objects or any mix of them.

    .PARAMETER SecretText
        Plain-text secrets that must not occur in any string of the graph.

    .PARAMETER Path
        Where the walk currently is. Used by the recursion only.

    .PARAMETER Depth
        How deep the walk currently is. Used by the recursion only.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param
    (
        [Parameter()]
        $InputObject,

        [Parameter()]
        [string[]]$SecretText = @(),

        [Parameter()]
        [string]$Path = '$',

        [Parameter()]
        [int]$Depth = 0
    )

    $maximumDepth = 8
    $holdsSecretText = {
        param ([string]$Text)

        foreach ($secret in $SecretText)
        {
            if ($secret -and $Text.Contains($secret))
            {
                return $true
            }
        }
        $false
    }

    # Nothing that is $null, 0, $false, an empty string or an empty array can hold a secret.
    if (-not $InputObject)
    {
        return
    }

    if ($Depth -gt $maximumDepth)
    {
        "${Path}: nested deeper than $maximumDepth levels, not inspected"
        return
    }

    if ($InputObject -is [securestring] -or $InputObject -is [pscredential])
    {
        "$Path is a $($InputObject.GetType().Name)"
        return
    }

    if ($InputObject -is [string])
    {
        if (& $holdsSecretText $InputObject)
        {
            "$Path contains secret text"
        }
        return
    }

    if ($InputObject -is [ValueType])
    {
        return
    }

    $next = $Depth + 1
    if ($InputObject -is [System.Collections.IDictionary])
    {
        foreach ($key in @($InputObject.Keys))
        {
            $label = [string]$key
            if (& $holdsSecretText $label)
            {
                "$Path.<key> contains secret text"
                $label = '<redacted key>'
            }
            Find-SecretLeak -InputObject $InputObject[$key] -SecretText $SecretText -Path "$Path.$label" -Depth $next
        }
        return
    }

    if ($InputObject -is [System.Collections.IEnumerable])
    {
        $index = 0
        foreach ($item in $InputObject)
        {
            Find-SecretLeak -InputObject $item -SecretText $SecretText -Path "$Path[$index]" -Depth $next
            $index++
        }
        return
    }

    foreach ($property in $InputObject.PSObject.Properties)
    {
        Find-SecretLeak -InputObject $property.Value -SecretText $SecretText -Path "$Path.$($property.Name)" -Depth $next
    }
}
