/*
	Scalar-Valued function for pretty printing times from a given number of seconds
	Will install to master & can then be used like:
		SELECT [master].[dbo].[PrettyPrintTime](100)
	Authors:
		Josh Keegan 04/12/2017
*/

USE master;

/* Make the function if it doesn't already exist. Also acts as a work around for SQL Server requiring CREATE FUNCTION to be the first statement in the batch */
IF OBJECT_ID('PrettyPrintTime') IS NULL
	EXEC ('CREATE FUNCTION [dbo].[PrettyPrintTime](@secs bigint) RETURNS varchar(max) AS BEGIN RETURN '''' END');
GO

ALTER FUNCTION [dbo].[PrettyPrintTime]
(
	@secs bigint
)
RETURNS varchar(max)
AS
BEGIN
	DECLARE @s varchar(2), @mi varchar(2), @h varchar(2), @d varchar(max);

	/* Seconds */
	SET @s = @secs % 60;
	SET @s = RIGHT('0' + @s, 2);
	SET @secs = @secs / 60;

	/* Minutes */
	SET @mi = @secs % 60;
	SET @mi = RIGHT('0' + @mi, 2);
	SET @secs = @secs / 60;

	/* Hours */
	SET @h = @secs % 24;
	SET @h = RIGHT('0' + @h, 2);
	SET @secs = @secs / 24;

	/* Days */
	SET @d = @secs;

	DECLARE @toRet varchar(max) = '';

	/* Only include days if necessary */
	IF @d > 0
	BEGIN
		SET @toRet = @toRet + @d + 'd ';
	END
	 
	/* Always show hours:minutes:seconds, so it;'s not ambiguous */
	SET @toRet = @toRet + @h + ':' + @mi + ':' + @s;

	RETURN @toRet;
END