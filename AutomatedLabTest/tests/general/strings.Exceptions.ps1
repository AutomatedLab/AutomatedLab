$exceptions = @{ }

<#
A list of entries that MAY be in the language files, without causing the tests to fail.
This is commonly used in modules that generate localized messages straight from C#.
Specify the full key as it is written in the language files, do not prepend the modulename,
as you would have to in C# code.

Example:
$exceptions['LegalSurplus'] = @(
    'Exception.Streams.FailedCreate'
    'Exception.Streams.FailedDispose'
)
#>
$exceptions['LegalSurplus'] = @(

)

$exceptions