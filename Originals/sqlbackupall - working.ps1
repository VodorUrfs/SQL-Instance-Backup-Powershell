# remove files older than 7 days
# Delete all Files in C:\temp older than 30 day(s)
$Path = "D:\SQL\Backups"
$Daysback = "-30"
$CurrentDate = Get-Date
$DatetoDelete = $CurrentDate.AddDays($Daysback)

#backup all databases and append date
Get-SqlDatabase -ServerInstance localhost\sqlexpress | Where { $_.Name -ne 'tempdb' } | foreach{Backup-SqlDatabase -DatabaseObject $_ -BackupFile "$path\$($_.NAME)_db_$(Get-Date -UFormat %Y%m%d%H%M).bak"}

#Get-ChildItem $Path | Where-Object { $_.LastWriteTime -lt $DatetoDelete } | Remove-Item