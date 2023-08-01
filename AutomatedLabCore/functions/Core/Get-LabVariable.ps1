function Get-LabVariable
{
    $pattern = 'AL_([a-zA-Z0-9]{8})+[-.]+([a-zA-Z0-9]{4})+[-.]+([a-zA-Z0-9]{4})+[-.]+([a-zA-Z0-9]{4})+[-.]+([a-zA-Z0-9]{12})'
    Get-Variable -Scope Global | Where-Object Name -Match $pattern
}
