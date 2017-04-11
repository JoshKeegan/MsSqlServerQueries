/*
	Data Stored per Table
	Originally from http://stackoverflow.com/a/15896658/5401981
	Requires PrettyPrintDataSize
	Modified by Josh Keegan 03/03/2016
*/

DECLARE @pageBytes AS int = 8 * 1024;

WITH CompressionsInUse AS
(
	SELECT DISTINCT
		i.object_id,
		data_compression_desc
	FROM sys.indexes i
	INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
),
CompressionPerTable AS
(
	SELECT 
		t.object_id,
		(
			SELECT CASE WHEN 
			(
				SELECT COUNT(*) 
				FROM CompressionsInUse 
				WHERE CompressionsInUse.object_id = t.object_id
			) > 1 
			THEN 'MIXED' 
			ELSE 
			(
				SELECT TOP 1 data_compression_desc 
				FROM CompressionsInUse 
				WHERE CompressionsInUse.object_id = t.object_id
			) END
		) AS compressionsInUse
	FROM sys.tables t
)
SELECT 
	s.name AS 'Schema',
	t.name AS 'Table',
	p.rows AS 'Num Rows',
	[master].[dbo].[PrettyPrintDataSize](SUM(a.total_pages) * @pageBytes) AS 'Total Space', 
	[master].[dbo].[PrettyPrintDataSize](SUM(a.used_pages) * @pageBytes) AS 'Used Space', 
	[master].[dbo].[PrettyPrintDataSize]((SUM(a.total_pages) - SUM(a.used_pages)) * @pageBytes) AS 'Unused Space',
	[master].[dbo].[PrettyPrintDataSize](SUM(CASE WHEN i.type IN (0, 1) THEN a.total_pages ELSE NULL END) * @pageBytes) AS 'Total Data Size',
	[master].[dbo].[PrettyPrintDataSize](COALESCE(SUM(CASE WHEN i.type NOT IN (0, 1) THEN a.total_pages ELSE NULL END) * @pageBytes, 0)) AS 'Total NC Indexes Size',
	CompressionPerTable.compressionsInUse AS 'Compression'
FROM sys.tables t
INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
INNER JOIN CompressionPerTable ON CompressionPerTable.object_id = t.object_id
WHERE t.name NOT LIKE 'dt%' -- filter out system tables for diagramming
AND t.is_ms_shipped = 0
AND i.object_id > 255
GROUP BY t.name, s.name, p.rows, CompressionPerTable.compressionsInUse
--ORDER BY s.Name, t.Name
ORDER BY SUM(a.total_pages) DESC