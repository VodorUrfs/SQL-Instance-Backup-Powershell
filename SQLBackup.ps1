#script to backup all found sql databases over all instances on the local computer only.
#test banana man
#take into consideration the backup location, size of databases vs copies kept.
#NTAUTHORITY\SYSTEM requires sysadmin rights on each SQL instance to work or entire script may fail.
#script needs to be manually run once to make sure it works and any configuration issues resolved before run on schedule

#Set an execution policy to allow script to run
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# sets vars, $ENV are generally defined in AEM site vars for site specific work, only backup path and retention days need to be defined at time of writing
$scriptversion = "v1.0"
#$Path = $ENV:SQLBackupPath
$Path = "c:\sql"
#$sqlinstance = $ENV:SQLInstance
#$Daysback = $ENV:SQLDaysToKeep
$Daysback = "-7"
$CurrentDate = Get-Date
$DatetoDelete = $CurrentDate.AddDays($Daysback)

#Clear any errors before we start
$error.Clear()

#Check for existing event log source and create one if needed
$sqlbackuplogtype = [system.diagnostics.eventlog]::SourceExists("Compat SQL Backup Script")
if ($sqlbackuplogtype) { $sqlscriptoutput = "" }
else { New-EventLog -LogName Application -Source "Compat SQL Backup Script"
       $sqlscriptoutput = "Added SQL Backup Script Event Log Source to computer `n"  }



# ------------ current section to edit to make work

#identify all server instances and put in array.
$service_name = (Get-Service -computername $env:computername -name MSSQL$*).Name    


# Loops the array $service_name and runs the below commands for each instance 
foreach ($instance in $service_name) 
{
 
    # Define Variables for backup loop
    $errorval = 0 # 
    $errorstocap = 0 # How many errors we expect to capture for event log build loop later on
    $numberofdatabases = 0 # How many databases are we backing up, used for event log
     
    $error.Clear() # Clears any Previous Errors from last loop
    #$errortime.Clear()

    # $instance is supplied as MSSQL$INSTANCENAME
    $instancestrip1=($instance -replace 'MSSQL','') # Removes MSSQL from $instance and puts into $instancestrip
    $instancestrip2=($instancestrip1 -replace '[$]','\') # Swaps the $ in $instancestrip1 for a backslash and stores in $instancestrip2 - Used when we build the instance path.
    $instancefolder=($instancestrip1 -replace '[$]','') # Removes the $ $instancestrip1 so we have an instance only name used for the backup folder name
    $instancestring = $env:computername + $instancestrip2 # Builds the string used to connect to the database e.g. LOCALHOST\INSTANCE

    # Builds full path from Backup Folder $path and $instance folder then checks if the directory exists, if it doesnt exist then creates that folder ready for use
    $instancedir = "$path\$instancefolder"
    if(!(Test-Path -Path $instancedir )){ New-Item -ItemType directory -Path $instancedir }
        
    # Counts the number of databases 
    Get-SqlDatabase -ServerInstance $instancestring | Where { $_.Name -ne 'tempdb' } | foreach { $numberofdatabases++ }

    # Backups up the database and increments $errorstocap so we know how many errors we may get
    Get-SqlDatabase -ServerInstance $instancestring | Where { $_.Name -ne 'tempdb' } | foreach{Backup-SqlDatabase -DatabaseObject $_ -BackupFile "$path\$instancefolder\$($_.NAME)_db_$(Get-Date -UFormat %Y%m%d%H%M).bak" 
    $errorstocap++;}


    # Start build of event log message for this loop.
    $finalmessage =""
    $finalmessage = "Compatibility SQL Backup Script Executed any output and errors are shown below. "
    $finalmessage += "( Script version  " 
    $finalmessage += $scriptversion
    $finalmessage += " )`n `n"
    $finalmessage += $sqlscriptoutput
    $finalmessage += " `n"
    
    $errortime=(Get-Date -UFormat %H:%M:%S) # Gets time when loop was executed for error tracking purposes

    #If we get an error add the first error to $finalmessage with timestamp
    if ($error[0] -ne $null)
        { 
            $finalmessage += $instancefolder + ":`n"
            $finalmessage += $errortime + " - " + $error[0]
            $finalmessage += " `n"
    
            # If there is more than one error write to $finalmessage and loop until we reach the number of errors expected to catch from $errorstocap with a timestamp
            while($errorval -ne $errorstocap)
                {
                    $finalmessage += $errortime + " - " + $error[$errorval]
                    $finalmessage += " `n"
                    $errorval++
                }
   
            $finalmessage += " `n"
        
        }

    #If no error just sat how many databases were backuped up with Timestamp
    else { 
        $finalmessage += $instancefolder + ":`n"
        $finalmessage += $errortime + " - Backed up " + $numberofdatabases + " sucsessfully `n"
     }



    # IF STATEMENT PUT DELETE STATEMENT IN ELSE IN IF MOST RECENT FILE IS WITHIN 7 DAYS OLDER THAN 7 DAYS WILL BE DELETED OTHERWISE NOTHING

    #Finds the most recent backup file time
    $Item = Get-ChildItem -Path $path\$instancefolder | Sort CreationTime | select -Last 1  


    if ($item.CreationTime -lt (date).adddays($Daysback)) { } # Makes sure our most recent backup isnt more than $daysback old if it is nothing gets done.
    else { 
            # Counts files being deleted deleted that are older than $daysback
            $filestodelete=(Get-ChildItem $path\$instancefolder | Where-Object { $_.LastWriteTime -lt (date).adddays($Daysback) })
            $filesdeleted = $filestodelete.Count
    
            # Deletes the files that are older than $daysback
            Get-ChildItem $path\$instancefolder | Where-Object { $_.LastWriteTime -lt (date).adddays($Daysback) } | Remove-Item 
    
            # Updates our event log message
            $finalmessage += $filesdeleted 
            $finalmessage += " Backups over retention period cleaned up"
    
         }


    # Writes our event log with a Info or Warning Depending on Succsess or failure
    if ($error[0] -ne $null)
    { Write-EventLog -LogName Application -Source "Compat SQL Backup Script" -EntryType Warning -EventID 2 -Message $finalmessage }
        else { <# $finalmessage += "`n `n No Errors Detected - All databases defined should be backed up" #>
                Write-EventLog -LogName Application -Source "Compat SQL Backup Script" -EntryType Information -EventID 1 -Message $finalmessage }
    
    #Clears Variable Read for next loop
    Clear-Variable finalmessage

}

#### OLD STUFF REMOVE BELOW?

# ------------- end of section to edit

#backup all databases and append date - not used while editing the above
#Get-SqlDatabase -ServerInstance $sqlinstance | Where { $_.Name -ne 'tempdb' } | foreach{Backup-SqlDatabase -DatabaseObject $_ -BackupFile "$path\$($_.NAME)_db_$(Get-Date -UFormat %Y%m%d%H%M).bak"}

#removes old files in $path over x days defined by $daysback
#Get-ChildItem $Path | Where-Object { $_.LastWriteTime -lt $DatetoDelete } | Remove-Item

# Write to Event Log
#if ($error[0] -ne $null)
 #   { Write-EventLog -LogName Application -Source "Compat SQL Backup Script" -EntryType Warning -EventID 2 -Message $finalmessage }
  #      else { $finalmessage += "`n `n No Errors Detected - All databases defined should be backed up"
   #             Write-EventLog -LogName Application -Source "Compat SQL Backup Script" -EntryType Information -EventID 1 -Message $finalmessage }
