/*
	IO per Database since server restart
	From http://www.databasejournal.com/features/mssql/finding-the-source-of-your-sql-server-io.html
		with modifications
	Requires PrettyPrintDataSize
*/

SELECT 
name AS 'Database Name',
SUM(num_of_reads) AS 'Num Reads',
SUM(num_of_writes) AS 'Num Writes',
master.dbo.PrettyPrintDataSize(SUM(num_of_bytes_read)) AS 'Data Read',
master.dbo.PrettyPrintDataSize(SUM(num_of_bytes_written)) AS 'Data Written'
FROM sys.dm_io_virtual_file_stats(NULL, NULL) I
INNER JOIN sys.databases D ON I.database_id = d.database_id
GROUP BY name 
ORDER BY 'Num Reads' DESC;