/*
	Scalar-Valued function for converting camelCase or TitleCase to UNDERSCORE_CASE (in upper)
	Will install to master & can then be used like:
		SELECT master.dbo.ToUnderscoreCaseUpper('testString')
	Authors:
		Josh Keegan 20/10/2016
*/

USE master;

/* Make the Function if it doesn't already exist. Also acts as a work around for SQL Server requiring CREATE FUNCTION to be the first statement in the batch */
IF OBJECT_ID('ToUnderscoreCaseUpper') IS NULL
	EXEC ('CREATE FUNCTION [dbo].[ToUnderscoreCaseUpper] (@in nvarchar(max)) RETURNS nvarchar(max) AS BEGIN RETURN '''' END');
GO

ALTER FUNCTION [dbo].[ToUnderscoreCaseUpper]
(
	@in nvarchar(max)
)
RETURNS nvarchar(max)
AS
BEGIN
	DECLARE @out nvarchar(max) = '';
	DECLARE @i int = 1;
	DECLARE @len int = LEN(@in);
	DECLARE @lastUpper bit = 1;

	/* Iterate over characters in the string */
	WHILE(@i <= @len)
	BEGIN
		DECLARE @c nchar(1) = SUBSTRING(@in, @i, 1);
		DECLARE @cUp nchar(1) = UPPER(@c);

		/* If char is upper case */
		IF @c = @cUp COLLATE Latin1_General_CS_AS 
		BEGIN
			/* If we aren't already in an upper case section, we've just entered one. This signifies a new word so separate with underscore */
			IF @lastUpper = 0
			BEGIN
				SET @out += '_';
			END

			SET @lastUpper = 1;
		END
		ELSE /* Otherwise, must be lower case */
		BEGIN
			SET @lastUpper = 0;
		END

		SET @out += @cUp;

		SET @i += 1;
	END

	RETURN @out;
END