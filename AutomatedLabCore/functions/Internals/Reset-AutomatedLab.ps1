function Reset-AutomatedLab
{
    Remove-Lab -Confirm:$false
    Remove-Module *
}
