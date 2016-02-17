/*
	Enable Read Committed Snapshot Isolation

	Note: RCSI can only be enabled when it's the only command running against the DB.
		To force that, this will switch the DB to single user mode.
		To make this process as painless as possible, run at a low load time
		and stop as many services accessing the DB as possible.
		If it's the only database on the server, could restart the server after running this
		since it appears that the data already in the cache becomes invalid, clearing it
		may help performance get back to normal quicker.
*/

DECLARE @sql varchar(8000);
SELECT  @sql = '
ALTER DATABASE ' + QUOTENAME(DB_NAME()) + ' SET SINGLE_USER WITH ROLLBACK IMMEDIATE ;
ALTER DATABASE ' + QUOTENAME(DB_NAME()) + ' SET READ_COMMITTED_SNAPSHOT ON;
ALTER DATABASE ' + QUOTENAME(DB_NAME()) + ' SET MULTI_USER;';

exec(@sql);