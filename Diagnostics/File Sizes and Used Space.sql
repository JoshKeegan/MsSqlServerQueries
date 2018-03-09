/*
	File Sizes and Used Space for the current Database
	Authors:
		Josh Keegan 09/03/2018

	Requires PrettyPrintDataSize
*/

SELECT 
	name AS 'File Name',
	master.dbo.PrettyPrintDataSize(CAST(size AS bigint) * 1024 * 1024 / 128) AS 'Current Size',
	master.dbo.PrettyPrintDataSize(CAST(FILEPROPERTY(name, 'SpaceUsed') AS bigint) * 1024 * 1024 / 128) AS 'Current Used Space',
	master.dbo.PrettyPrintDataSize(CAST((size - FILEPROPERTY(name, 'SpaceUsed')) AS bigint) * 1024 * 1024 / 128) AS 'Free Space'
FROM sys.database_files;