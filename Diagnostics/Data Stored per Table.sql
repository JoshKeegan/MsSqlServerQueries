/*
	Data Stored per Table
	Originally from http://stackoverflow.com/a/15896658/5401981
	Requires PrettyPrintDataSize
	Modified by Josh Keegan 03/03/2016
*/

DECLARE @pageBytes AS int = 8 * 1024;

SELECT 
	s.Name AS 'Schema',
	t.NAME AS 'Table',
	p.rows AS 'Num Rows',
	[master].[dbo].[PrettyPrintDataSize](SUM(a.total_pages) * @pageBytes) AS 'Total Space', 
	[master].[dbo].[PrettyPrintDataSize](SUM(a.used_pages) * @pageBytes) AS 'Used Space', 
	[master].[dbo].[PrettyPrintDataSize]((SUM(a.total_pages) - SUM(a.used_pages)) * @pageBytes) AS 'Unused Space',
	[master].[dbo].[PrettyPrintDataSize](SUM(CASE WHEN i.index_id IN (0, 1) THEN a.total_pages ELSE NULL END) * @pageBytes) AS 'Total Data Size',
	[master].[dbo].[PrettyPrintDataSize](COALESCE(SUM(CASE WHEN i.index_id NOT IN (0, 1) THEN a.total_pages ELSE NULL END) * @pageBytes, 0)) AS 'Total NC Indexes Size',
	p.data_compression_desc AS 'Compression'
FROM sys.tables t
INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
INNER JOIN sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE t.NAME NOT LIKE 'dt%' -- filter out system tables for diagramming
AND t.is_ms_shipped = 0
AND i.OBJECT_ID > 255 
GROUP BY t.Name, s.Name, p.Rows, p.data_compression_desc
--ORDER BY s.Name, t.Name
ORDER BY SUM(a.total_pages) DESC