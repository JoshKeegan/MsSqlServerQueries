/*
	Compression savings report
		Details space savings that could be achieved per table if their compression level was altered
	Authors:
		Josh Keegan 10/01/2017

	Requires PrettyPrintDataSize
*/

/* Compression method to use. Can be PAGE or ROW */
DECLARE @compression varchar(4) = 'PAGE';

/* Threshold for warning of low benefits from compression (Compression Ratio less than this) */
DECLARE @lowBenefitThreshold float = 1.1;

/* Whether to show the (detailed) per index breakdown */
DECLARE @showPerIndexBreakdown bit = 1;

/* Constants */
DECLARE @crLf nvarchar(max) = CHAR(13) + CHAR(10);
DECLARE @xmlPrefix nvarchar(max) = '<?ClickToOpen ' + @crLf + @crLf;
DECLARE @xmlSuffix nvarchar(max) = @crLf + ' ?>';

/* Temp table to store tables to be processed in */
IF OBJECT_ID('tempdb..#tables') IS NOT NULL
	DROP TABLE #tables;

CREATE TABLE #tables
(
	schemaName sysname,
	tableName sysname,
	tableId int
);

/* Populate #tables */
INSERT INTO #tables
SELECT /* Use TOP N for development, to speed it up */
	s.name AS schemaName, 
	t.name AS tableName, 
	t.object_id AS tableId
FROM sys.tables t
INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE t.is_ms_shipped = 0
AND t.name NOT LIKE 'dt%'; /* filter out system tables for diagramming */

/* Count tables to be processed to be used as a progress indicator */
DECLARE @numTables int;
SELECT @numTables = COUNT(*)
FROM #tables;

/* Temp table to store index compression results for */
IF OBJECT_ID('tempdb..#indexEstimates') IS NOT NULL
	DROP TABLE #indexEstimates;

CREATE TABLE #indexEstimates
(
	objectName sysname,
	schemaName sysname,
	indexId int,
	partitionNum int,
	totalSizeCurr bigint,
	totalSizeProjected bigint,
	sampleSizeCurr bigint,
	sampleSizeProjected bigint,
	tableId int,
	alreadyCompressed bit /* Whether the index is already compressed to the target level */
);

/* 
	Temp table to store index compression results coming straight out of the 
	stored procedure, before table ID gets added
*/
IF OBJECT_ID('tempdb..#indexEstimatesSpResults') IS NOT NULL
	DROP TABLE #indexEstimatesSpResults;

CREATE TABLE #indexEstimatesSpResults
(
	objectName sysname,
	schemaName sysname,
	indexId int,
	partitionNum int,
	totalSizeCurr bigint,
	totalSizeProjected bigint,
	sampleSizeCurr bigint,
	sampleSizeProjected bigint
);

/* Iterate over tables, estimating compression savings for each */
DECLARE tablesCursor CURSOR FOR
SELECT *
FROM #tables;

DECLARE @schemaName sysname, @tableName sysname, @tableId int;
OPEN tablesCursor;
FETCH NEXT FROM tablesCursor INTO @schemaName, @tableName, @tableId;

DECLARE @i int = 1;
WHILE @@FETCH_STATUS = 0
BEGIN
	/* Progress Report */
	RAISERROR ('Estimating compression savings for table %i/%i', 0, 1, @i, @numTables) WITH NOWAIT;

	/* Run SP, storing results in intermediate table */
	INSERT INTO #indexEstimatesSpResults
	EXEC sp_estimate_data_compression_savings
		@schema_name = @schemaName,
		@object_name = @tableName,
		@index_id = NULL,
		@partition_number = NULL,
		@data_compression = @compression;

	/* Move results into #indexEstimates, adding table ID and whether the index is already compressed to the target level */
	INSERT INTO #indexEstimates (objectName, schemaName, indexId, partitionNum, totalSizeCurr, 
			totalSizeProjected, sampleSizeCurr, sampleSizeProjected, tableId, alreadyCompressed)
		SELECT 
			#indexEstimatesSpResults.*, 
			@tableId AS tableId, 
			CASE WHEN 
				(p.data_compression_desc = @compression) 
				THEN CAST(1 AS bit) 
				ELSE CAST(0 AS bit) 
			END AS alreadyCompressed
		FROM #indexEstimatesSpResults
		INNER JOIN sys.indexes i ON i.object_id = @tableId AND i.index_id = #indexEstimatesSpResults.indexId
		INNER JOIN sys.partitions p ON p.object_id = i.object_id AND p.index_id = i.index_id;

	TRUNCATE TABLE #indexEstimatesSpResults;

	FETCH NEXT FROM tablesCursor INTO @schemaName, @tableName, @tableId;
	SET @i += 1;
END

/* Clean up */
CLOSE tablesCursor;
DEALLOCATE tablesCursor;

/* Correct estimates for any index that is already compressed using the specified compression level */
UPDATE #indexEstimates
SET totalSizeProjected = totalSizeCurr
WHERE alreadyCompressed = 1;

/* Build warnings */
IF OBJECT_ID('tempdb..#tablesWarnings') IS NOT NULL
	DROP TABLE #tablesWarnings;

CREATE TABLE #tablesWarnings
(
	tableId int,
	warnings nvarchar(max)
);

DECLARE warningsCursor CURSOR FOR
SELECT tableId
FROM #tables;

OPEN warningsCursor;
FETCH NEXT FROM warningsCursor INTO @tableId;

WHILE @@FETCH_STATUS = 0
BEGIN
	DECLARE @warning varchar(max) = '', 
		@numIndexesAlreadyCompressed int = null, 
		@tableCompressionRatio float = null, 
		@numIndexesNoBenefit int = null, 
		@numIndexesLowBenefit int = null;

	/* Does the table have any rows */
	IF (SELECT TOP 1 row_count FROM sys.dm_db_partition_stats WHERE object_id = @tableId) = 0
	BEGIN
		SET @warning += 'Table has no rows, and therefore cannot benefit from compression';
	END

	/* Is the specified compression level already used on indexes in this table */
	SELECT @numIndexesAlreadyCompressed = COUNT(*)
	FROM #indexEstimates
	WHERE tableId = @tableId
	AND alreadyCompressed = 1;

	IF @numIndexesAlreadyCompressed > 0
	BEGIN
		IF @warning <> ''
			SET @warning += @crLf;

		SET @warning += CAST(@numIndexesAlreadyCompressed AS nvarchar(max)) + ' indexes are already ' + @compression + ' compressed';
	END

	/* Does the table overall benefit from compression. */
	SELECT @tableCompressionRatio = COALESCE(CAST(SUM(totalSizeCurr) AS float) / NULLIF(SUM(totalSizeProjected), 0), 1)
	FROM #indexEstimates
	WHERE tableId = @tableId;

	IF @tableCompressionRatio <= 1
	BEGIN
		IF @warning <> ''
			SET @warning += @crLf;
		
		SET @warning += 'Table does not benefit from compression overall';

		/* TODO: Could calculate whether just the non-compressed indexes would benefit & add that to the warning */
	END
	ELSE IF @tableCompressionRatio < @lowBenefitThreshold
	BEGIN
		IF @warning <> ''
			SET @warning += @crLf;

		SET @warning += 'Table has a low benefit from compression overall';

		/* TODO: Could calculate whether just the non-compressed indexes would benefit & add that to the warning */
	END

	/* Indexes that won't benefit from compression */
	SELECT @numIndexesNoBenefit = COUNT(*)
	FROM #indexEstimates
	WHERE tableId = @tableId
	/* Don't consider ones that are already compressed to the target level */
	AND alreadyCompressed = 0
	HAVING SUM(totalSizeCurr) - SUM(totalSizeProjected) <= 0;

	IF @numIndexesNoBenefit > 0
	BEGIN
		IF @warning <> ''
			SET @warning += @crLf;

		SET @warning += CAST(@numIndexesNoBenefit AS nvarchar) + ' indexes do not benefit from compression';
	END

	/* Indexes that have a low benefit from compression */
	SELECT @numIndexesLowBenefit = COUNT(*)
	FROM #indexEstimates
	WHERE tableId = @tableId
	/* Don't consider ones that are already compressed to the target level */
	AND alreadyCompressed = 0
	/* Do benefit from compression */
	HAVING SUM(totalSizeCurr) - SUM(totalSizeProjected) > 0
	/* Just not by much */
	AND COALESCE(CAST(SUM(totalSizeCurr) AS float) / NULLIF(SUM(totalSizeProjected), 0), 1) < @lowBenefitThreshold;

	IF @numIndexesLowBenefit > 0
	BEGIN
		IF @warning <> ''
			SET @warning += @crLf;

		SET @warning += CAST(@numIndexesLowBenefit AS nvarchar) + ' indexes have a low benefit from compression';
	END

	/* Store warnings string in table */
	INSERT INTO #tablesWarnings (tableId, warnings)
		VALUES (@tableId, @warning);

	FETCH NEXT FROM warningsCursor INTO @tableId;
END

/* Clean Up */
CLOSE warningsCursor;
DEALLOCATE warningsCursor;

/* Select the results */
SELECT 
	schemaName AS 'Schema',
	objectName AS 'Table',
	master.dbo.PrettyPrintDataSize(SUM(totalSizeCurr) * 1024) AS 'Current Size',
	master.dbo.PrettyPrintDataSize(SUM(totalSizeProjected) * 1024) AS 'Projected Size',
	master.dbo.PrettyPrintDataSize((SUM(totalSizeCurr) - SUM(totalSizeProjected)) * 1024) AS 'Size Decrease',
	COALESCE(CAST(SUM(totalSizeCurr) AS float) / NULLIF(SUM(totalSizeProjected), 0), 1) AS 'Compression Ratio (n:1)',
	CAST(@xmlPrefix + tw.warnings + @xmlSuffix AS xml) AS 'Warnings',
	'EXEC sp_estimate_data_compression_savings @schema_name = ''' + schemaName + ''', @object_name = ''' + objectName + 
		''', @index_id = NULL, @partition_number = NULL, @data_compression = ''' + @compression + '''' AS 'Detailed Query'
FROM #indexEstimates ie
INNER JOIN #tablesWarnings tw ON tw.tableId = ie.tableId
GROUP BY ie.tableId, schemaName, objectName, tw.warnings
ORDER BY SUM(totalSizeCurr) - SUM(totalSizeProjected) DESC;

/* (Detailed) Per Index Breakdown */
IF @showPerIndexBreakdown = 1
BEGIN
	SELECT 
		#indexEstimates.schemaName AS 'Schema',
		#indexEstimates.objectName AS 'Table',
		i.name AS 'Index',
		#indexEstimates.partitionNum AS 'Partition Num',
		i.type_desc AS 'Index Type',
		p.data_compression_desc AS 'Current Compression',
		master.dbo.PrettyPrintDataSize(totalSizeCurr * 1024) AS 'Current Size',
		master.dbo.PrettyPrintDataSize(totalSizeProjected * 1024) AS 'Projected Size',
		master.dbo.PrettyPrintDataSize((totalSizeCurr - totalSizeProjected) * 1024) AS 'Size Decrease',
		COALESCE(CAST(totalSizeCurr AS float) / NULLIF(totalSizeProjected, 0), 1) AS 'Compression Ratio (n:1)',
		CAST(@xmlPrefix + 
'ALTER INDEX ' + i.name + ' ON ' + #indexEstimates.objectName + '
REBUILD PARTITION = ALL  
WITH 
(
	DATA_COMPRESSION = ' + @compression + ',
	/* Rebuild online - remove for an offline rebuild (faster if index can be locked, and online isn''t supported by all editions */
	ONLINE = ON
);' + @xmlSuffix AS xml) AS 'Set Compression'
	FROM #indexEstimates
	INNER JOIN sys.indexes i ON i.object_id = #indexEstimates.tableId AND i.index_id = #indexEstimates.indexId
	INNER JOIN sys.partitions p ON p.object_id = i.object_id AND p.index_id = i.index_id
	/* Don't display indexes that are already compressed to the target level */
	WHERE #indexEstimates.alreadyCompressed = 0
	ORDER BY totalSizeCurr - totalSizeProjected DESC;
END

/* Drop temp tables */
DROP TABLE #indexEstimatesSpResults;
DROP TABLE #indexEstimates;
DROP TABLE #tables;
DROP TABLE #tablesWarnings;