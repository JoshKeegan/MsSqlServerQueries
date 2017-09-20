/*
	SQL Server Cached Pages (Buffer Pool) broken down by index
	Authors:
		Josh Keegan 20/09/2017

	TODO:
	 - Sometimes more pages are apparently cached than exist in the index... Perhaps not checking something on sys.dm_os_buffer_descriptors?
	 - Could have a second query that shows the cached LOB data
*/

DECLARE @pageBytes AS int = 8 * 1024;

/* Get the total buffer pool size */
DECLARE @totalBufferPoolPages bigint;
SELECT @totalBufferPoolPages = cntr_value
FROM sys.dm_os_performance_counters 
WHERE RTRIM(object_name) LIKE '%Buffer Manager'
AND counter_name = 'Database Pages';

DECLARE @strTotalBufferPoolSize varchar(max);
SET @strTotalBufferPoolSize = [master].[dbo].[PrettyPrintDataSize](@totalBufferPoolPages * @pageBytes);
RAISERROR ('Total Cache Size: %s', 0, 1, @strTotalBufferPoolSize) WITH NOWAIT;

WITH NumCachedPages AS
(
	SELECT 
		bd.allocation_unit_id,
		COUNT_BIG(*) AS count
	FROM sys.dm_os_buffer_descriptors bd
	WHERE bd.database_id = DB_ID()
	GROUP BY bd.allocation_unit_id
)
SELECT 
	i.name AS 'Name',
	i.type_desc AS 'Type',
	i.is_unique AS 'Is Unique',
	i.is_primary_key AS 'PK',
	i.fill_factor AS 'Fill Factor',
	i.has_filter AS 'Is Filtered',
	p.rows AS 'Num Rows',
	p.data_compression_desc AS 'Compression',
	[master].[dbo].[PrettyPrintDataSize](au.total_pages * @pageBytes) AS 'Total Space', 
	[master].[dbo].[PrettyPrintDataSize](NumCachedPages.count * @pageBytes) AS 'Cached',
	CAST(CAST((NumCachedPages.count / CAST(au.total_pages AS decimal)) * 100 AS decimal(10, 2)) AS varchar(max)) + '%' AS '% Cached',
	CAST(CAST((NumCachedPages.count / CAST(@totalBufferPoolPages AS decimal)) * 100 AS decimal(10, 2)) AS varchar(max)) + '%' AS '% Total Cache'
FROM sys.tables t
INNER JOIN sys.indexes i ON i.object_id = t.object_id
INNER JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id = i.index_id
INNER JOIN sys.allocation_units au ON au.container_id = p.partition_id
INNER JOIN NumCachedPages ON NumCachedPages.allocation_unit_id = au.allocation_unit_id
WHERE t.is_ms_shipped = 0
AND au.type = 1 /* In row data, so excludes things like LOB data */
ORDER BY NumCachedPages.count DESC;