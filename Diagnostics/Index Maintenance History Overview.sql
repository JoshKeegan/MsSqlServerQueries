/*
	Index Maintenance History Overview.
	Gives a look at what indexes are being rebuild or reorganised frequently.
	You can then look at these indexes in more detail to see if there's anything that 
		could be done to reduce the maintenance it requires (e.g. lowering Fill Factor)
	Requires index maintenance to be being done using Ola Halengreen's 'IndexOptimize' script
		with the @LogToTable param set to 'Y'.
	Authors:
		Josh Keegan 02/03/2016
*/

/* 
	Consider Commands since. 
	Should be set to the last time Index definitions or Fillfactors were modified.
	If left at 0 & work has been done since the commands started to be recorded then 
		it might flag up indexes to look at where the reason they were constantly being 
		re(organised/built) has already been addressed.
*/
DECLARE @sinceDate datetime = 0;

USE master;

/* Use a CTE to clean the Index and Object names from the Command (in case they contain key words REORGANIZE/REBUILD) */
WITH Cleaned AS
(
	SELECT 
	IndexName, 
	ObjectName, 
	CommandType,
	StartTime,
	EndTime,
	REPLACE(REPLACE(Command, IndexName, ''), ObjectName, '') AS CleanedCommand
	FROM CommandLog
)
SELECT 
COUNT(*) AS 'Re(Build/Org)s',
COUNT(CASE WHEN CleanedCommand LIKE '%REORGANIZE WITH%' THEN 1 ELSE NULL END) AS 'Reorganises',
COUNT(CASE WHEN CleanedCommand LIKE '%REBUILD WITH%' THEN 1 ELSE NULL END) AS 'Rebuilds',
COUNT(CASE WHEN CleanedCommand LIKE '%REBUILD WITH%ONLINE = ON%' THEN 1 ELSE NULL END) AS 'Rebuilds (Online)',
COUNT(CASE WHEN CleanedCommand LIKE '%REBUILD WITH%ONLINE = OFF%' THEN 1 ELSE NULL END) AS 'Rebuilds (Offline)',
IndexName AS 'Index Name',
ObjectName AS ObjectName,
MAX(StartTime) AS 'Last Op. Date',
CONVERT(varchar, DATEADD(ss, AVG(DATEDIFF(ss, StartTime, EndTime)), 0), 8) AS 'Avg Op. Time',
CONVERT(varchar, DATEADD(ss, MAX(DATEDIFF(ss, StartTime, EndTime)), 0), 8) AS 'Max Op. Time'
FROM Cleaned
WHERE CommandType = 'ALTER_INDEX'
AND StartTime > @sinceDate
GROUP BY ObjectName, IndexName
ORDER BY COUNT(*) DESC