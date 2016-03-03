/*
	Database Backup History
	Based on script from https://www.mssqltips.com/sqlservertip/1747/how-to-find-out-how-long-a-sql-server-backup-took/
		with a fix & a couple of modifications
	Requires PrettyPrintDataSize
*/

SELECT bup.user_name AS [User],
 bup.database_name AS [Database],
 bup.server_name AS [Server],
 bup.backup_start_date AS [Backup Started],
 bup.backup_finish_date AS [Backup Finished],
 CAST((CAST(DATEDIFF(s, bup.backup_start_date, bup.backup_finish_date) AS int))/3600 AS varchar) + ' hours, ' 
 + CAST(((CAST(DATEDIFF(s, bup.backup_start_date, bup.backup_finish_date) AS int))%3600)/60 AS varchar) + ' minutes, '
 + CAST((CAST(DATEDIFF(s, bup.backup_start_date, bup.backup_finish_date) AS int))%60 AS varchar) + ' seconds'
 AS 'Total Time',
 [master].[dbo].[PrettyPrintDataSize](bup.backup_size) AS Size
FROM msdb.dbo.backupset bup
/* COMMENT THE NEXT LINE IF YOU WANT ALL BACKUP HISTORY */
WHERE bup.database_name IN (SELECT name FROM master.dbo.sysdatabases)
/* Limit to the last 7 days */
AND bup.backup_start_date >= DATEADD(dd, -7, GETUTCDATE())
ORDER BY bup.database_name, bup.backup_start_date DESC