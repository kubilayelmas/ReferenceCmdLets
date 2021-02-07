# LAST ACCESS TIME
Function Set-FileLastAccessTime {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, Position = 1)]
        [string[]] $FilePath,

        [Parameter(Mandatory = $true, Position = 2)]
        [string[]] $Days
    )

    $desiredDate = (Get-Date).AddDays("$Days")

    ForEach ($file in $FilePath) { 
        ( Get-Item -path $file | Select-Object FullName, CreationTime, LastWriteTime, LastAccessTime, Attributes ) | Format-Table
    }

    $confirm = Read-Host "Are you sure, you want to change the LastAccessTime for these file(s) / folder(s) ? (Y or N)"

    While ( "y", "n" -notcontains $confirm ) {
        Write-host "Make a valid choice please!"
        $confirm = Read-Host "Are you sure, you want to change the LastAccessTime for these file(s) / folder(s) ? (Y or N)"
    }

    If ( $confirm -eq "Y" ) {
        Try {
            ForEach ($file in $filepath) { 
                ( Get-Item -Path $file -ErrorAction Stop).LastAccessTime=("$desiredDate")
                ( Get-Item -path $file | Select-Object FullName, CreationTime, LastWriteTime, LastAccessTime, Attributes ) | Format-Table
            }
        }
        Catch {}
    }    
}

# LAST WRITE TIME
Function Set-FileLastWriteTime {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, Position = 1)]
        [string[]] $FilePath,

        [Parameter(Mandatory = $true, Position = 2)]
        [string[]] $Days
    )

    $desiredDate = (Get-Date).AddDays("$Days")

    ForEach ($file in $FilePath) { 
        ( Get-Item -path $file | Select-Object FullName, CreationTime, LastWriteTime, LastAccessTime, Attributes ) | Format-Table
    }

    $confirm = Read-Host "Are you sure, you want to change the LastWriteTime for these file(s) / folder(s) ? (Y or N)"

    While ( "y", "n" -notcontains $confirm ) {
        Write-host "Make a valid choice please!"
        $confirm = Read-Host "Are you sure, you want to change the LastWriteTime for these file(s) / folder(s) ? (Y or N)"
    }

    If ( $confirm -eq "Y" ) {
        Try {
            ForEach ($file in $filepath) { 
                ( Get-Item -Path $file -ErrorAction Stop).LastWriteTime = ("$desiredDate")
                ( Get-Item -path $file | Select-Object FullName, CreationTime, LastWriteTime, LastAccessTime, Attributes ) | Format-Table
            }
        }
        Catch {}
    }    
}

# CREATION TIME
Function Set-FileCreationTime {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, Position = 1)]
        [string[]] $FilePath,

        [Parameter(Mandatory = $true, Position = 2)]
        [string[]] $Days
    )

    $desiredDate = (Get-Date).AddDays("$Days")
    
    ForEach ($file in $FilePath) { 
        ( Get-Item -path $file | Select-Object FullName, CreationTime, LastWriteTime, LastAccessTime, Attributes ) | Format-Table
    }

    $confirm = Read-Host "Are you sure, you want to change the CreationTime for these file(s) / folder(s) ? (Y or N)"

    While ( "y", "n" -notcontains $confirm ) {
        Write-host "Make a valid choice please!"
        $confirm = Read-Host "Are you sure, you want to change the CreationTime for these file(s) / folder(s) ? (Y or N)"
    }

    If ( $confirm -eq "Y" ) {
        Try {
            ForEach ($file in $filepath) { 
                ( Get-Item -Path $file -ErrorAction Stop).CreationTime = ( "$desiredDate" )
                ( Get-Item -path $file | Select-Object FullName, CreationTime, LastWriteTime, LastAccessTime, Attributes ) | Format-Table
            }
        }
        Catch {}
    }    
}
