/*
	Data Stored per Index
	Authors:
		Josh Keegan 09/12/2016

	Requires PrettyPrintDataSize
*/

DECLARE @tableName nvarchar(max) = 'TwitterStatuses';
DECLARE @pageBytes AS int = 8 * 1024;

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
	[master].[dbo].[PrettyPrintDataSize](au.used_pages * @pageBytes) AS 'Used Space', 
	[master].[dbo].[PrettyPrintDataSize]((au.total_pages - au.used_pages) * @pageBytes) AS 'Unused Space'
FROM sys.tables t
INNER JOIN sys.indexes i ON i.object_id = t.object_id
INNER JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id = i.index_id
INNER JOIN sys.allocation_units au ON au.container_id = p.partition_id
WHERE t.is_ms_shipped = 0
AND t.name = @tableName
AND au.type = 1 /* In row data, so excludes things like LOB data */
ORDER BY au.total_pages DESC