/*
	Database Backup Size History
		Simplified & uses consistent units for size so results can be easily exported, e.g. for graphing 
		DB growth in spreadsheet software or otherwise helping understand DB growth.
		Note: Excludes log files, so values will differ from overall size shown in Properties > Size
	Authors:
		Josh Keegan 04/02/2016
*/

/* set this to be whatever dbname you want */
DECLARE @dbname sysname = '';

SELECT 
 bup.backup_start_date AS 'Backup Started',
CAST((bup.backup_size / (1024 * 1024 * 1024)) AS varchar) AS 'Size (GiB)'
FROM msdb.dbo.backupset bup
WHERE bup.database_name IN (SELECT name FROM master.dbo.sysdatabases)
AND bup.database_name LIKE @dbname
ORDER BY bup.backup_start_date DESC