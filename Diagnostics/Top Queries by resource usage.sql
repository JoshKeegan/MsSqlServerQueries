/*
	Top Queries by resource usage
	Based on query from http://www.databasejournal.com/features/mssql/finding-the-source-of-your-sql-server-io.html
*/

DECLARE @crLf char(2) = CHAR(13) + CHAR(10);
DECLARE @xmlPrefix nvarchar(max) = '<?ClickToOpen ' + @crLf;
DECLARE @xmlSuffix nvarchar(max) = @crLf + ' ?>';

SELECT TOP 25
	dbs.name AS 'Database',
	cp.objtype AS 'Query Type',
	cp.usecounts AS 'Execution Count',
	qs.total_worker_time AS CPU,
	qs.total_elapsed_time AS 'Elapsed Time (μs)', /* Microseconds (millionths of a second) */
	qs.total_logical_reads AS 'Logical Reads',
	qs.total_logical_writes AS 'Logical Writes',
	qs.total_logical_reads + qs.total_logical_writes AS 'Logical Reads + Writes',
	qs.total_physical_reads AS 'Physical Reads',
	CAST((@xmlPrefix + SUBSTRING(text, 
                CASE WHEN statement_start_offset = 0 
                        OR statement_start_offset IS NULL  
                        THEN 1  
                        ELSE statement_start_offset/2 + 1 END, 
                CASE WHEN statement_end_offset = 0 
                        OR statement_end_offset = -1  
                        OR statement_end_offset IS NULL  
                        THEN LEN(text)  
                        ELSE statement_end_offset/2 END - 
                    CASE WHEN statement_start_offset = 0 
                        OR statement_start_offset IS NULL 
                            THEN 2
                            ELSE statement_start_offset/2  END + 1 
                ) + @xmlSuffix) AS xml) AS 'Statement',
	text AS 'Full Query' /* Useful to track down where an individual statement actually is so you can update it (e.g. if in stored procedure, which one?) */
FROM sys.dm_exec_query_stats qs
INNER JOIN sys.dm_exec_cached_plans cp on qs.plan_handle = cp.plan_handle
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) st
LEFT OUTER JOIN sys.databases dbs ON dbs.database_id = st.dbid
/* Change order by for CPU, logical reads, writes etc... */
ORDER BY qs.total_logical_reads + qs.total_logical_writes DESC;