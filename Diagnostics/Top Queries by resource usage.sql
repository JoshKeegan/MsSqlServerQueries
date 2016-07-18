/*
	Top Queries by resource usage
	Based on query from http://www.databasejournal.com/features/mssql/finding-the-source-of-your-sql-server-io.html

	TODO: Use the XML trick for the statement
*/

SELECT TOP 25 
	cp.usecounts AS 'Execution Count',
	qs.total_worker_time AS CPU,
	qs.total_elapsed_time AS 'Elapsed Time (microseconds)',
	qs.total_logical_reads AS 'Logical Reads',
	qs.total_logical_writes AS 'Logical Writes',
	qs.total_physical_reads AS 'Physical Reads',
	SUBSTRING(text, 
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
                            THEN 1  
                            ELSE statement_start_offset/2  END + 1 
                )  AS [Statement],
	dbs.name AS 'Database'
FROM sys.dm_exec_query_stats qs
INNER JOIN sys.dm_exec_cached_plans cp on qs.plan_handle = cp.plan_handle
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) st
LEFT OUTER JOIN sys.databases dbs ON dbs.database_id = st.dbid
/* Change order by for CPU, logical writes etc... */
ORDER BY qs.total_logical_reads DESC;