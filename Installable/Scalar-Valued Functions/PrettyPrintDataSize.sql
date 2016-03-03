/*
	Scalar-Valued function for pretty printing file sizes.
	Will install to master & can then be used like: 
		SELECT [master].[dbo].[PrettyPrintDataSize](7000)
	Authors:
		Josh Keegan 03/03/2016
*/

USE master;

/* Make the Function if it doesn't already exist. Also acts as a work around for SQL Server requiring CREATE FUNCTION to be the first statement in the batch */
IF OBJECT_ID('PrettyPrintDataSize') IS NULL
	EXEC ('CREATE FUNCTION [dbo].[PrettyPrintDataSize] (@bytes bigint) RETURNS varchar(max) AS BEGIN RETURN '''' END');
GO

ALTER FUNCTION [dbo].[PrettyPrintDataSize]
(
	@bytes bigint
)
RETURNS varchar(max)
AS
BEGIN
	DECLARE @fpBytes numeric = @bytes;
	DECLARE @toRet varchar(max);

	SELECT @toRet =
	CASE 
		/* TODO: Round the sizes to 3dp (or whatever is specified through optional param), e.g. CAST(ROUND(124.3654576767, 3) AS decimal(9, 3)) */
		WHEN @bytes > (CAST(1024 AS bigint) * 1024 * 1024 * 1024) THEN CAST((@fpBytes / (CAST(1024 AS bigint) * 1024 * 1024 * 1024)) AS varchar) + ' TiB'
		WHEN @bytes > (1024 * 1024 * 1024) THEN CAST((@fpBytes / (1024 * 1024 * 1024)) AS varchar) + ' GiB'
		WHEN @bytes > (1024 * 1024) THEN CAST((@fpBytes / (1024 * 1024)) AS varchar) + ' MiB'
		WHEN @bytes > 1024 THEN CAST((@fpBytes / (1024)) AS varchar) + ' KiB'
		ELSE CAST(@bytes AS varchar) + ' B'
	END;

	RETURN @toRet;
END
GO