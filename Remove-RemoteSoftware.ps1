Function Get-MsiDetailedInfo {
    param(
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.IO.FileInfo]$Path,
 
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("ProductCode", "ProductVersion", "ProductName", "Manufacturer", "ProductLanguage", "FullVersion")]
        [string]$Property
    )
    Process {
        Try {
            # Read property from MSI database
            $WindowsInstaller = New-Object -ComObject WindowsInstaller.Installer
            $MSIDatabase = $WindowsInstaller.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $null, $WindowsInstaller, @($Path.FullName, 0))
            $Query = "SELECT Value FROM Property WHERE Property = '$($Property)'"
            $View = $MSIDatabase.GetType().InvokeMember("OpenView", "InvokeMethod", $null, $MSIDatabase, ($Query))
            $View.GetType().InvokeMember("Execute", "InvokeMethod", $null, $View, $null)
            $Record = $View.GetType().InvokeMember("Fetch", "InvokeMethod", $null, $View, $null)
            $Value = $Record.GetType().InvokeMember("StringData", "GetProperty", $null, $Record, 1)
 
            # Commit database and close view
            $MSIDatabase.GetType().InvokeMember("Commit", "InvokeMethod", $null, $MSIDatabase, $null)
            $View.GetType().InvokeMember("Close", "InvokeMethod", $null, $View, $null)           
            $MSIDatabase = $null
            $View = $null
 
            # Return the value
            Return $Value
        } 
        Catch {
            Write-Warning -Message $_.Exception.Message ; Break
        }
    }
    End {
        # Run garbage collection and release ComObject
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($WindowsInstaller) | Out-Null
        [System.GC]::Collect()
    }
}

<#
.SYNOPSIS
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
    Example of how to use this cmdlet
.EXAMPLE
    Another example of how to use this cmdlet
.INPUTS
    Inputs to this cmdlet (if any)
.OUTPUTS
    Output from this cmdlet (if any)
.NOTES
    General notes
.COMPONENT
    The component this cmdlet belongs to
.ROLE
    The role this cmdlet belongs to
.FUNCTIONALITY
    The functionality that best describes this cmdlet
#>
function Remove-RemoteSoftware {
    [CmdletBinding(PositionalBinding = $false,
        HelpUri = "",
        ConfirmImpact = 'Medium')]
    [Alias()]
    [OutputType([String])]
    Param (
        # Param1 help description
        [Parameter(Mandatory = $true,
            Position = 1,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("c")]
        [string] $ComputerName,
        
        # Param2 help description
        [Parameter(Mandatory = $false,
            Position = 2,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false)]
        [Alias("s")]
        [string] $SoftwareName,
        
        # Param3 help description
        [Parameter(Mandatory = $true,
            Position = 3,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false)]
        [ValidateSet('Remove', 'List')]
        [Alias("a")]
        [String] $Action
    )
    $saveErrActPref = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    $f1 = "Name like '%"
    $f2 = "$SoftwareName%'"
    $filter = $f1 + $f2

    ForEach ( $computer in $ComputerName ) {
        If ( Test-Connection -ComputerName $computer -Quiet -Count 1 ) {
            If ( $Action -eq "List" ) {
                $app = Get-WmiObject -ComputerName $computer -Class Win32_Product -Filter "$filter"
                If ( $app ) { 
                    $app | Select-Object Name, Version
                } 
                Else { 
                    Write-Host "I couldn't find this software name on this system! $SoftwareName" 
                }
            }  
            If ( $Action -eq "Remove" ) {
                $app = Get-WmiObject -ComputerName $computer -Class Win32_Product -Filter "$filter"
                If ( $app ) { 
                    Write-Host "Are you sure that you want to remove $SoftwareName from $computer ? " -ForegroundColor Yellow
                    $app
                    Write-Host "Press ctrl+c to cancel or..."
                    Pause
                    $app.Uninstall()
                    Write-host "$softwarename has been removed from $computer!" -ForegroundColor Yellow
                }
                Else { 
                    Write-Host "I couldn't find this software name on this system! $SoftwareName" -ForegroundColor Red
                }
            } 
        } 
        Else { 
            Write-Host "This host seems to be offline! $computer" -ForegroundColor Red
        }
        $ErrorActionPreference = $saveErrActPref 
    } 
}
