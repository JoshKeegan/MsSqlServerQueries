/*
	Database Backup Size History
		Simplified & uses consistent units for size so results can be easily exported, e.g. for graphing 
		DB growth in spreadsheet software or otherwise helping understand DB growth.
		Note: Excludes log files, so values will differ from overall size shown in Properties > Size
	Authors:
		Josh Keegan 04/02/2016
*/

SELECT bup.backup_start_date AS 'Backup Started',
CAST((bup.backup_size / (1024 * 1024 * 1024)) AS varchar) AS 'Size (GiB)',
bup.database_name
FROM msdb.dbo.backupset bup
/* For current database */
WHERE bup.database_name = DB_NAME()
/* Data file backups */
AND bup.type = 'D'
ORDER BY bup.backup_start_date DESC