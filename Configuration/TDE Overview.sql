/*
	TDE Overview
	Of the databases using TDE, what algorithm & key length is each using?
	Authors:
		Josh Keegan 25/01/2018
*/

SELECT 
	dbs.name,
	dbs.database_id,
	enc.key_algorithm,
	enc.key_length
FROM sys.dm_database_encryption_keys enc
INNER JOIN sys.databases dbs ON dbs.database_id = enc.database_id