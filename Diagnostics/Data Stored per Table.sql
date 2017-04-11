/*
	Data Stored per Table
	Originally from http://stackoverflow.com/a/15896658/5401981
	Requires PrettyPrintDataSize
	Modified by Josh Keegan 03/03/2016
*/

DECLARE @pageBytes AS int = 8 * 1024;

WITH CompressionsInUse AS
(
	SELECT
		i.object_id,
		data_compression_desc,
		COUNT(*) AS count
	FROM sys.indexes i
	INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
	GROUP BY i.object_id, data_compression_desc
),
CompressionPerTable AS
(
	SELECT 
		t.object_id,
		(
			/* If not all indexes on this table have the same compression level */
			SELECT CASE WHEN 
				(
					SELECT COUNT(*) 
					FROM CompressionsInUse 
					WHERE CompressionsInUse.object_id = t.object_id
				) > 1 
				/* Display a summary of the compression methods in use */
				THEN 'MIXED:' +
				(
					SELECT SUBSTRING
					(
						(
							SELECT ',' + data_compression_desc + '(' + CAST(count AS nvarchar(max)) + ')'
							FROM CompressionsInUse
							WHERE CompressionsInUse.object_id = t.object_id
							ORDER BY count DESC, data_compression_desc ASC
							FOR XML PATH('')
						), 2, 200000
					) AS csv
				)
			/* Otherwise, all indexes have the same compression method, just display its description */
			ELSE 
				(
					SELECT TOP 1 data_compression_desc 
					FROM CompressionsInUse 
					WHERE CompressionsInUse.object_id = t.object_id
				) 
			END
		) AS compressionsInUse
	FROM sys.tables t
),
RowsPerTable AS
(
	SELECT i.object_id, p.rows
	FROM sys.indexes i
	INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
	/* Where this is the clustered index or heap type, and will therefore have all the rows */
	WHERE i.type IN (0, 1)
)
SELECT 
	s.name AS 'Schema',
	t.name AS 'Table',
	RowsPerTable.rows AS 'Num Rows',
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
INNER JOIN RowsPerTable ON RowsPerTable.object_id = t.object_id
INNER JOIN CompressionPerTable ON CompressionPerTable.object_id = t.object_id
WHERE t.name NOT LIKE 'dt%' -- filter out system tables for diagramming
AND t.is_ms_shipped = 0
AND i.object_id > 255
GROUP BY t.name, s.name, RowsPerTable.rows, CompressionPerTable.compressionsInUse
--ORDER BY s.Name, t.Name
ORDER BY SUM(a.total_pages) DESC