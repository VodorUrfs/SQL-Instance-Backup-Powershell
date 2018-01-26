# SQL Instance Backup (Powershell)
Powershell script to hunt down and backup all MS SQL instances on a windows machine.

Searches services for instance names with a one time "blank instance" at the bottom defined by computername.
Adds a new event log category and logs under event codes 1 and 2
