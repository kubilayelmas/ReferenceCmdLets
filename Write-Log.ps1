<# 
.Synopsis 
   Write-Log writes a message to a specified log file with the current time stamp. 
.DESCRIPTION 
   The Write-Log function is designed to add logging capability to other scripts. 
   In addition to writing output and/or verbose you can write to a log file for 
   later debugging. 
.PARAMETER Level 
   Specify the criticality of the log information being written to the log (i.e. Error, Warning, Informational)  
.PARAMETER LogMessage 
   This is the message/comment you want to log. Add a detailed message for your actions.  
.PARAMETER LogFilePath
   The path to the log file to which you would like to write. By default the function will  
   create file if it does not exist but if the directory doesn't exist. A directory won't 
   be created and this script will end with an exception.
.EXAMPLE 
   Write-Log -Level "Info" -LogMessage "System is going down!" -LogFilePath "C:\mylogs\system.log"
   Writes the message to c:\mylogs\system.log. 
.EXAMPLE 
   $mypaths = get-content C:\mypaths.txt | ForEach ($path in $mypaths) {copy-item C:\myfile -destination $path ; write-log -level "info" -LogMessage "copying files" -LogFilePath ("C:\mylogs\$path" + ".log")} 
   Writes a new file for each object. Might be useful when using with other scripts.  
#> 

function Write-Log { 
    [CmdletBinding()]
    Param ( 
        [parameter(Mandatory = $true, Position = 1)]
        [string] $Level,

        [Parameter(Mandatory = $true, Position = 2)]
        [string] $LogMessage,

        [Parameter(Mandatory = $true, Position = 3,
            ValueFromPipelineByPropertyName = $true)]
        [string] $LogFilePath
    ) 
    
    Try { 
        $formattedDate = Get-Date -Format "dd-MM-yyyy hh:mm:ss"
        $formattedDate + " ; " + $Level + " ; " + $LogMessage | Out-File -FilePath $LogFilePath -Append 
    }
    Catch {
        Write-Host "Something went wrong with Write-Log." -ForegroundColor Red -BackgroundColor Black
        Write-Host "Make sure your LogFilePath is valid!" -ForegroundColor Red -BackgroundColor Black 
    } 
}