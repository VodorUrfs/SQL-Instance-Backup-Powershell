#script to backup all found sql databases over all instances on the local computer only.
#take into consideration the backup location, size of databases vs copies kept.
#NTAUTHORITY\SYSTEM requires sysadmin rights on each SQL instance to work or entire script may fail.
#script needs to be manually run once to make sure it works and any configuration issues resolved before run on schedule

#Set an execution policy to allow script to run
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# sets vars, $ENV are generally defined in AEM site vars for site specific work, only backup path and retention days need to be defined at time of writing
$scriptversion = "v1.0"
#$Path = $ENV:SQLBackupPath
$Path = "d:\sql\backups"
#$sqlinstance = $ENV:SQLInstance
#$Daysback = $ENV:SQLDaysToKeep
$Daysback = "-7"
$CurrentDate = Get-Date
$DatetoDelete = $CurrentDate.AddDays($Daysback)

#Clear any errors before we start
$error.Clear()

#Check for existing event log source and create one if needed
$sqlbackuplogtype = [system.diagnostics.eventlog]::SourceExists("Compat SQL Backup Script")
if ($sqlbackuplogtype) { $sqlscriptoutput = "SQL Backup script event type already added `n" }
    else { New-EventLog -LogName Application -Source "Compat SQL Backup Script"
            $sqlscriptoutput = "Added SQL Backup Script Event Log Source to computer `n"
            }

# Build Event Log Message
$finalmessage = "Compatibility SQL Backup Script appears to have run correctly output and errors are shown below. "
$finalmessage += "( Script version  " 
$finalmessage += $scriptversion
$finalmessage += " )`n `n"
$finalmessage += $sqlscriptoutput
$finalmessage += " `n"

$finalmessage += $error[0]
$finalmessage += " `n"
$finalmessage += $error[1]
$finalmessage += " `n"

# ------------ current section to edit to make work

#identify all server instances and put in array.
$service_name = (Get-Service -computername $env:computername -name MSSQL$*).Name    

foreach ($instance in $service_name) {

$instancestrip1=($instance -replace 'MSSQL','')
$instancestrip2=($instancestrip1 -replace '[$]','\')
$instancefolder=($instancestrip1 -replace '[$]','')
$instancestring = $env:computername + $instancestrip2

$instancedir = "$path\$instancefolder"
if(!(Test-Path -Path $instancedir )){
    New-Item -ItemType directory -Path $instancedir
}

Get-SqlDatabase -ServerInstance $instancestring | Where { $_.Name -ne 'tempdb' } | foreach{Backup-SqlDatabase -DatabaseObject $_ -BackupFile "$path\$instancefolder\$($_.NAME)_db_$(Get-Date -UFormat %Y%m%d%H%M).bak"}
#[System.Windows.MessageBox]::Show($instancefolder)

}

# ------------- end of section to edit

#backup all databases and append date - not used while editing the above
#Get-SqlDatabase -ServerInstance $sqlinstance | Where { $_.Name -ne 'tempdb' } | foreach{Backup-SqlDatabase -DatabaseObject $_ -BackupFile "$path\$($_.NAME)_db_$(Get-Date -UFormat %Y%m%d%H%M).bak"}

#removes old files in $path over x days defined by $daysback
#Get-ChildItem $Path | Where-Object { $_.LastWriteTime -lt $DatetoDelete } | Remove-Item

# Write to Event Log
if ($error[0] -ne $null)
    { Write-EventLog -LogName Application -Source "Compat SQL Backup Script" -EntryType Warning -EventID 2 -Message $finalmessage }
        else { $finalmessage += "`n `n No Errors Detected - All databases defined should be backed up"
                Write-EventLog -LogName Application -Source "Compat SQL Backup Script" -EntryType Information -EventID 1 -Message $finalmessage }