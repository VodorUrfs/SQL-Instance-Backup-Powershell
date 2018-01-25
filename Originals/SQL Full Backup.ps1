$serverName = "localhost\SQLExpress"
$backupDirectory = "D:\backupSQL"
$daysToStoreDailyBackups = 7
$daysToStoreWeeklyBackups = 28
$monthsToStoreMonthlyBackups = 3

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoExtended") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoEnum") | Out-Null
 
$mySrvConn = new-object Microsoft.SqlServer.Management.Common.ServerConnection
$mySrvConn.ServerInstance=$serverName
$mySrvConn.LoginSecure = $false
$mySrvConn.Login = "USERNAME"
$mySrvConn.Password = "PASSWORD"

$server = new-object Microsoft.SqlServer.Management.SMO.Server($mySrvConn)

$dbs = $server.Databases
$startDate = (Get-Date)
"$startDate"

Get-ChildItem "$backupDirectory\*_daily.bak" |? { $_.lastwritetime -le (Get-Date).AddDays(-$daysToStoreDailyBackups)} |% {Remove-Item $_ -force }
"removed all previous daily backups older than $daysToStoreDailyBackups days"

foreach ($database in $dbs | where { $_.IsSystemObject -eq $False})
{
    $dbName = $database.Name      

    $timestamp = Get-Date -format yyyy-MM-dd-HHmmss
    $targetPath = $backupDirectory + "\" + $dbName + "_" + $timestamp + "_daily.bak"

    $smoBackup = New-Object ("Microsoft.SqlServer.Management.Smo.Backup")
    $smoBackup.Action = "Database"
    $smoBackup.BackupSetDescription = "Full Backup of " + $dbName
    $smoBackup.BackupSetName = $dbName + " Backup"
    $smoBackup.Database = $dbName
    $smoBackup.MediaDescription = "Disk"
    $smoBackup.Devices.AddDevice($targetPath, "File")
    $smoBackup.SqlBackup($server) 
    "backed up $dbName ($serverName) to $targetPath"               
}

if([Int] (Get-Date).DayOfWeek -eq 0)
{
    Get-ChildItem "$backupDirectory\*_weekly.bak" |? { $_.lastwritetime -le (Get-Date).AddDays(-$daysToStoreWeeklyBackups)} |% {Remove-Item $_ -force }
    "removed all previous daily backups older than $daysToStoreWeeklyBackups days"

    foreach ($database in $dbs | where { $_.IsSystemObject -eq $False})
    {
        $dbName = $database.Name      

        $timestamp = Get-Date -format yyyy-MM-dd-HHmmss
        $targetPath = $backupDirectory + "\" + $dbName + "_" + $timestamp + "_weekly.bak"

        $smoBackup = New-Object ("Microsoft.SqlServer.Management.Smo.Backup")
        $smoBackup.Action = "Database"
        $smoBackup.BackupSetDescription = "Full Backup of " + $dbName
        $smoBackup.BackupSetName = $dbName + " Backup"
        $smoBackup.Database = $dbName
        $smoBackup.MediaDescription = "Disk"
        $smoBackup.Devices.AddDevice($targetPath, "File")
        $smoBackup.SqlBackup($server) 
        "backed up $dbName ($serverName) to $targetPath"                 
    }
}

if([Int] (Get-Date).Day -eq 1)
{
    Get-ChildItem "$backupDirectory\*_monthly.bak" |? { $_.lastwritetime -le (Get-Date).AddMonths(-$monthsToStoreMonthlyBackups)} |% {Remove-Item $_ -force }
    "removed all previous monthly backups older than $monthsToStoreMonthlyBackups days"

    foreach ($database in $dbs | where { $_.IsSystemObject -eq $False})
    {
        $dbName = $database.Name      

        $timestamp = Get-Date -format yyyy-MM-dd-HHmmss
        $targetPath = $backupDirectory + "\" + $dbName + "_" + $timestamp + "_monthly.bak"

        $smoBackup = New-Object ("Microsoft.SqlServer.Management.Smo.Backup")
        $smoBackup.Action = "Database"
        $smoBackup.BackupSetDescription = "Full Backup of " + $dbName
        $smoBackup.BackupSetName = $dbName + " Backup"
        $smoBackup.Database = $dbName
        $smoBackup.MediaDescription = "Disk"
        $smoBackup.Devices.AddDevice($targetPath, "File")
        $smoBackup.SqlBackup($server) 
        "backed up $dbName ($serverName) to $targetPath"                 
    }
}