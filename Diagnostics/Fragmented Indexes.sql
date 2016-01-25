SELECT
B.name AS TableName
, C.name AS IndexName
, C.type_desc
, C.fill_factor AS IndexFillFactor
, D.rows AS RowsCount
, A.avg_fragmentation_in_percent
, A.page_count
, A.fragment_count
FROM sys.dm_db_index_physical_stats(DB_ID(),NULL,NULL,NULL,NULL) A
INNER JOIN sys.objects B
ON A.object_id = B.object_id
INNER JOIN sys.indexes C
ON B.object_id = C.object_id AND A.index_id = C.index_id
INNER JOIN sys.partitions D
ON B.object_id = D.object_id AND A.index_id = D.index_id
WHERE C.index_id > 0
/* Don't worry about very small indexes - mimics default of Ola Halengreen's IndexOptimize script, which selects this value based on the reccomendadtion of a MS whitepaper */
AND A.page_count >= 1000
/* How much fragmentation are we bothered about on this DB */
AND A.avg_fragmentation_in_percent > 5

-- Limit to a specific table
--AND B.name = 'TwitterStatuses'

ORDER BY A.fragment_count DESC