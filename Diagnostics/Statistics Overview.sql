/*
	Statistics Overview
	Get a look at the statistics for a DB.
		Doesn't filter anything out or try and highlight problems but gives you a starting point to 
		filter yourself and try and spot issues.
		This could have a lot more time spent on it at some point to do that.
	Note: Compatible with SQL Server 2008 R2 SP2 or 2012 SP1+ (see comment in query)
	Authors:
		Josh Keegan 03/02/2016
*/

SELECT 
t.name  AS 'Table Name', 
s.name  AS 'Stat Name', 
STATS_DATE(t.object_id, s.stats_id) AS 'Last Updated' ,
s.auto_created AS 'Auto Created',
s.no_recompute AS 'No Recompute',
statsProperties.modification_counter AS 'Num Modifications',
statsProperties.rows AS 'Stats Num Rows',
statsProperties.rows_sampled AS 'Stats Num Rows Sampled',
CAST((CAST(statsProperties.rows_sampled as float) / statsProperties.rows) * 100 AS varchar) + '%' AS 'Percentage Rows Sampled'
FROM sys.stats AS s
INNER JOIN sys.tables AS t ON s.object_id = t.object_id
/* 
	SQL Server 2008 R2 SP2 or 2012 SP1+. Older versions must use rowmodctr in sys.sysindexes 
	(see how Ola Halengree's IndexOptimize does this), but only provide
	rows modified, not other values used
*/
CROSS APPLY sys.dm_db_stats_properties (s.object_id, s.stats_id) AS statsProperties
WHERE t.type = 'u'
AND statsProperties.rows <> statsProperties.rows_sampled
ORDER BY 
/* Options for ordering. What are we interested in? */
/* Row Sample Percentage - flags up stats being generated from a small sample size, or if there have been a lot of modifications since it was last updated */
CAST(statsProperties.rows_sampled as float) / statsProperties.rows ASC
/* Num Modifications - flags up stats that are probably now outdated */
/* TODO: Could perhaps skew this by table size. Large table with 1mil updates will have less of an impact than a very small table with 1 mil updates */
--statsProperties.modification_counter DESC