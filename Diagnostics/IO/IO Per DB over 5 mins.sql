/*
	Snapshot of IO per database over 5 minutes
	From http://www.databasejournal.com/features/mssql/finding-the-source-of-your-sql-server-io.html
		with some modifications
	Requires PrettyPrintDataSize

	Note: Will take 5 mins to run. Since SQL Server stores these stats since restart,
		it must sample the DMV twice, waiting between them
*/

DECLARE @Sample TABLE (
  DBName varchar(128) 
 ,NumberOfReads bigint
 ,NumberOfWrites bigint
 ,BytesRead bigint
 ,BytesWritten bigint)

INSERT INTO @Sample 
SELECT name AS 'DBName'
      ,SUM(num_of_reads) AS 'NumberOfRead'
      ,SUM(num_of_writes) AS 'NumberOfWrites'
      ,SUM(num_of_bytes_read) AS BytesRead
      ,SUM(num_of_bytes_written) AS BytesWritten
FROM sys.dm_io_virtual_file_stats(NULL, NULL) I
  INNER JOIN sys.databases D  
      ON I.database_id = d.database_id
GROUP BY name 

WAITFOR DELAY '00:05:00.000';

SELECT FirstSample.DBName
      ,(SecondSample.NumberOfReads - FirstSample.NumberOfReads) AS 'Num Reads'
      ,(SecondSample.NumberOfWrites - FirstSample.NumberOfWrites) AS 'Num Writes'
      ,master.dbo.PrettyPrintDataSize(SecondSample.BytesRead - FirstSample.BytesRead) AS 'Data Read'
      ,master.dbo.PrettyPrintDataSize(SecondSample.BytesWritten - FirstSample.BytesWritten) AS 'Data Written'
FROM 
(SELECT * FROM @Sample) FirstSample
INNER JOIN
(SELECT name AS 'DBName'
      ,SUM(num_of_reads) AS 'NumberOfReads'
      ,SUM(num_of_writes) AS 'NumberOfWrites' 
      ,SUM(num_of_bytes_read) AS BytesRead
      ,SUM(num_of_bytes_written) AS BytesWritten
FROM sys.dm_io_virtual_file_stats(NULL, NULL) I
  INNER JOIN sys.databases D  
      ON I.database_id = d.database_id
GROUP BY name) AS SecondSample
ON FirstSample.DBName = SecondSample.DBName
ORDER BY 'Num Reads' DESC;