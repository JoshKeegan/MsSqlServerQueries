/*
	Database Backup History
	Based on script from https://www.mssqltips.com/sqlservertip/1747/how-to-find-out-how-long-a-sql-server-backup-took/
		with a fix & a couple of modifications
*/

SELECT bup.user_name AS [User],
 bup.database_name AS [Database],
 bup.server_name AS [Server],
 bup.backup_start_date AS [Backup Started],
 bup.backup_finish_date AS [Backup Finished],
 CAST((CAST(DATEDIFF(s, bup.backup_start_date, bup.backup_finish_date) AS int))/3600 AS varchar) + ' hours, ' 
 + CAST(((CAST(DATEDIFF(s, bup.backup_start_date, bup.backup_finish_date) AS int))%3600)/60 AS varchar)+ ' minutes, '
 + CAST((CAST(DATEDIFF(s, bup.backup_start_date, bup.backup_finish_date) AS int))%60 AS varchar)+ ' seconds'
 AS 'Total Time',
 (
	CASE 
		/* TODO: Round the sizes to 3dp, e.g. CAST(ROUND(124.3654576767, 3) AS decimal(9, 3)) */
		WHEN bup.backup_size > (CAST(1024 AS bigint) * 1024 * 1024 * 1024) THEN CAST((bup.backup_size / (CAST(1024 AS bigint) * 1024 * 1024 * 1024)) AS varchar) + ' TiB'
		WHEN bup.backup_size > (1024 * 1024 * 1024) THEN CAST((bup.backup_size / (1024 * 1024 * 1024)) AS varchar) + ' GiB'
		WHEN bup.backup_size > (1024 * 1024) THEN CAST((bup.backup_size / (1024 * 1024)) AS varchar) + ' MiB'
		WHEN bup.backup_size > 1024 THEN CAST((bup.backup_size / (1024)) AS varchar) + ' KiB'
		ELSE CAST(bup.backup_size AS varchar) + ' B'
	END
 ) AS Size
FROM msdb.dbo.backupset bup
/* COMMENT THE NEXT LINE IF YOU WANT ALL BACKUP HISTORY */
WHERE bup.database_name IN (SELECT name FROM master.dbo.sysdatabases)
/* Limit to the last 7 days */
AND bup.backup_start_date >= DATEADD(dd, -7, GETUTCDATE())
ORDER BY bup.database_name, bup.backup_start_date DESC