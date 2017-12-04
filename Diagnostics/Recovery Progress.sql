/*
	Database Recovery Progress
	Reads the error log messages to see how much progress has been made on a database that's in recocvery mode
	Authors:
		Josh Keegan 04/12/2017

	Dependencies:
		PrettyPrintTime
*/

DECLARE @databaseName nvarchar(max) = 'CommsManager';

DECLARE @logEntries AS TABLE
(
	LogDate datetime2,
	ProcessInfo nvarchar(max),
	text nvarchar(max)
);

DECLARE @quotedDbName nvarchar(max) = '''' + @databaseName + '''';

INSERT INTO @logEntries
EXEC master..sp_readerrorlog 0, 1, 'Recovery of database', @quotedDbName;

SELECT TOP 10
	LogDate AS 'Log Entry Date',
	SUBSTRING(Text, CHARINDEX(') is ', Text) + 4, CHARINDEX(' complete (', Text) - CHARINDEX(') is ', Text) - 4) AS 'Percent Complete',
	[master].[dbo].[PrettyPrintTime](CAST(SUBSTRING([Text], CHARINDEX('approximately', [Text]) + 13,CHARINDEX(' seconds remain', [Text]) - CHARINDEX('approximately', [Text]) - 13) AS int)) AS 'Estimated Time Remaining',
	Text AS 'Log Entry'
FROM @logEntries
ORDER BY LogDate DESC