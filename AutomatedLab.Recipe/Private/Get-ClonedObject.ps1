# Idea from http://stackoverflow.com/questions/7468707/deep-copy-a-dictionary-hashtable-in-powershell 
function Get-ClonedObject
{
    [CmdletBinding()]
    param
    (
        [object]
        $DeepCopyObject
    )
    $memStream = New-Object -TypeName IO.MemoryStream
    $formatter = New-Object -TypeName Runtime.Serialization.Formatters.Binary.BinaryFormatter
    $formatter.Serialize($memStream, $DeepCopyObject)
    $memStream.Position = 0
    $formatter.Deserialize($memStream)
}
