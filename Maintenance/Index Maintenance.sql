/*
	Reorganise or rebuild Indexes using Ola HallenGreen's IndexOptimise Maintenance Script
	Documentation & Download: https://ola.hallengren.com/sql-server-index-and-statistics-maintenance.html
*/

USE master;

EXEC dbo.IndexOptimize 
/* Do all system & User Databases */
@Databases = 'ALL_DATABASES',

/* Currently same as the defaults, might want to increase if they're too aggressive */
@FragmentationLevel1 = 5,
@FragmentationLevel2 = 30,

/* Never automatically perform Offline Index Rebuilds, leave that for me to do if REALLY necessary */
@FragmentationLow = NULL,
@FragmentationMedium = 'INDEX_REORGANIZE,INDEX_REBUILD_ONLINE',
@FragmentationHigh = 'INDEX_REBUILD_ONLINE',

/* Don't start any more index maintenance operations after 1hr */
@TimeLimit = 3600,

/* Leave 30s between index maintenance commands. 
	Probably unnecessary but will give the server a little breathing room to get through a backlog */
@Delay = 30,

/* Log each command run to dbo.CommandLog */
@LogToTable = 'Y'

/*
	Parameters to consider:
	- FillFactor
	- MaxDOP
	- UpdateStatistics (stats are currently left untouched)
		* OnlyModifiedStatistics
		* StatisticsSample
		* StatisticsResample
	- PageCountLevel (1000 default seems reasonable though & is based on a MS whitepaper)
*/