# Use this script with caution!
# This script will remove all UNUSED roles/features (inluding Remote Management Tools) and the source files
# for these features from a Windows Server



function Remove-UnusedWinFeatures
    {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string] $ComputerName)

    $cred = Get-Credential
    
    $features = get-windowsfeature -ComputerName $ComputerName -Credential $cred | where {$_.Installed -eq $False}

    Uninstall-WindowsFeature -name $features -Remove -Confirm -IncludeManagementTools -LogPath $env:temp\remove-unusedwindowsfeatures.log -ComputerName $ComputerName -Credential $cred
}