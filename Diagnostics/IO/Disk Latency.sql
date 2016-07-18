/*
	Disk latency
	From http://www.databasejournal.com/features/mssql/finding-the-source-of-your-sql-server-io.html
*/

SELECT  LEFT(physical_name, 1) AS drive,
        CAST(SUM(io_stall_read_ms) / 
            (1.0 + SUM(num_of_reads)) AS NUMERIC(10,1)) 
                          AS 'avg_read_disk_latency_ms',
        CAST(SUM(io_stall_write_ms) / 
            (1.0 + SUM(num_of_writes) ) AS NUMERIC(10,1)) 
                          AS 'avg_write_disk_latency_ms',
        CAST((SUM(io_stall)) / 
            (1.0 + SUM(num_of_reads + num_of_writes)) AS NUMERIC(10,1)) 
                          AS 'avg_disk_latency_ms'
FROM    sys.dm_io_virtual_file_stats(NULL, NULL) AS divfs
        JOIN sys.master_files AS mf ON mf.database_id = divfs.database_id
                                       AND mf.file_id = divfs.file_id
GROUP BY LEFT(physical_name, 1)