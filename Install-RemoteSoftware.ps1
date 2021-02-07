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
function Install-RemoteSoftware {
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
        [ValidateScript( {
                Test-Connection -ComputerName $_ -Count 1 -Quiet
            })]
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
        [ValidateSet('Install', 'List')]
        [Alias("a")]
        [String] $Action,

        # Param4 help description
        [Parameter(Mandatory = $false,
            Position = 4,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false)]
        [ValidateScript( {
                Test-Path ( Split-Path $_ ) 
            })]
        [Alias("f")]
        [string] $FilePath
    )
    Begin { 
        $saveErrActPref = $ErrorActionPreference
        $ErrorActionPreference = 'SilentlyContinue'
        $ping = Test-WSMan -ComputerName $ComputerName
        $sourceFileInfo = (Get-Item $FilePath | Select *)
        $FullFileName = $sourceFileInfo.Name
        $f1 = "Name like '%"
        $f2 = "$SoftwareName%'"
        $filter = $f1 + $f2
        $msiProductCode = Get-MsiDetailedInfo -Path $FilePath -Property ProductCode
        $msiProductName = Get-MsiDetailedInfo -Path $FilePath -Property ProductName
        $msiProductVersion = Get-MsiDetailedInfo -Path $FilePath -Property ProductVersion
    }
    Process {
        If ( $ping ) {
            # Listing all installed software from the system.
            If ( ( $Action -eq "List" ) -and ( [string]::IsNullOrEmpty($SoftwareName) ) ) {
                $app = Get-WmiObject -ComputerName $ComputerName -Class Win32_Product
                If ( $app ) {
                    $app | Select-Object Name, Version, PSComputerName
                } 
                Else { 
                    Write-Host "I couldn't find this software name on this system! $SoftwareName"
                }
            }
            # Listing only installed software from the system with the given SoftwareName value.
            If ( ( $Action -eq "List" ) -and ( ![string]::IsNullOrEmpty($SoftwareName) ) ) {
                $app = Get-WmiObject -ComputerName $ComputerName -Class Win32_Product -Filter "$filter"
                If ( $app ) { 
                    $app | Select-Object Name, Version, PSComputerName
                } 
                Else { 
                    Write-Host "I couldn't find this software name on this system! $SoftwareName"
                }
            }
            # Installing the software provided by the FilePath value.
            If ( $Action -eq "Install" ) {
                Try {
                    # Try to find a safe & temporary place to load the necessary files.
                    $rootTempDir = ( Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                            Resolve-path $ENV:ProgramData
                        } ).Path.Replace(":", "$")
                    $rootTempDir = "\\" + $ComputerName + "\" + $rootTempDir
                    $destFileName = $rootTempDir + "\" + $FullFileName
                    $destLogFileName = $rootTempDir + "\" + $FullFileName + ".txt"
                    $arguments = "msiexec.exe /i $destFileName /l*v $destLogFileName /qn /norestart"

                    Copy-Item -Path $FilePath -Destination $rootTempDir -Force -Confirm:$false

                    # Confirm that the copy was successful!
                    $sourceItemLength = $sourceFileInfo.Length
                    $targetItemLength = ( Get-Item $rootTempDir\$FullFileName | Select-Object * ).Length
                    If ( $sourceItemLength -like $targetItemLength ) {
                        $proc = Invoke-WmiMethod -ComputerName $ComputerName -Class Win32_Process -Name Create -ArgumentList $arguments
                        do {
                            Clear-Host
                            Write-Host "Installing $FullFileName on $ComputerName .... Please wait" -ForegroundColor Yellow
                            Start-Sleep -Milliseconds 100
                            Write-Host "While your program is installing, here some info about your MSI's details ;" -ForegroundColor Blue
                            Start-Sleep -Milliseconds 100
                            Write-Host "Product Name : " -ForegroundColor Green
                            $msiProductName
                            Start-Sleep -Milliseconds 100
                            Write-Host "Product version : " -ForegroundColor Green
                            $msiProductVersion
                            Start-Sleep -Milliseconds 100
                            Write-Host "Product code : " -ForegroundColor Green
                            $msiProductCode
                            Start-Sleep -Seconds 5
                        }
                        Until ( ! ( Get-Process -ComputerName $ComputerName -Id $proc.ProcessID -ErrorAction Ignore ) )
                    }
                    Else {
                        Write-Host "The length of your source file does not match with the length of your target file!
                            It's not safe to continue! Try again later!" -ForegroundColor Red
                    }
                }
                Catch {
                    $_.Exception.Message = $catchError
                    Write-Host "An fatal error has occured!" -ForegroundColor Red
                    Write-Host $catchError
                }
                Finally {
                    # Clean up the working directory on the remote host.
                    Remove-Item $destFileName -Force
                    Write-Host "The remote setup file has been deleted from the remote computer" -ForegroundColor Yellow
                    $confirm = (Get-WmiObject -ComputerName $ComputerName -Class Win32_Product | Select-Object IdentifyingNumber).IdentifyingNumber
                    If ( $msiProductCode -eq $confirm.IdentifyingNumber ) {
                        Write-Host "ALL GOOD! I was able to verify your setup! It looks like your software is now installed on $ComputerName properly!"
                    }
                    Else {
                        Write-Host "I couldn't verify if your software is properly installed!"
                        Write-Host "Please verify in the following list;"
                        ( Get-WmiObject -ComputerName $ComputerName -Class Win32_Product | Select-Object Name ).Name
                    }
                }
            }
            If ( ! ($ping) ) {
                write-host "WSMAN is not enabled on this host!"
            }
        } 
        Else { 
            Write-Host "This host seems to be offline! $ComputerName" -ForegroundColor Red
        }
    }
    End {
        $ErrorActionPreference = $saveErrActPref
    }
}
