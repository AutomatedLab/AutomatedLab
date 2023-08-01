function Invoke-Ternary ([scriptblock]$decider, [scriptblock]$ifTrue, [scriptblock]$ifFalse)
{
    if (&$decider)
    {
        &$ifTrue
    }
    else
    {
        &$ifFalse
    }
}