/*
	Update Statistics using Ola HalenGreen's IndexOptimize Maintenance Script
	Documentation & Download: https://ola.hallengren.com/sql-server-index-and-statistics-maintenance.html
*/

USE master;

EXEC dbo.IndexOptimize
/* Do all system & User Databases */
@Databases = 'ALL_DATABASES',

/* Don't do Index Maintenance here - that's handled separately */
@FragmentationLow = NULL,
@FragmentationMedium = NULL,
@FragmentationHigh = NULL,

/* Update Stats - Consider all stats for updating */
@UpdateStatistics = 'ALL',

/* Fullscan everything - will take longer, but bad stats can kill performance on Very Large Tables so worth it if can be done within the maintenance window */
@StatisticsSample = 100,

/* Log each command run to dbo.CommandLog */
@LogToTable = 'Y'