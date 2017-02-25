/*
	Remap an existing User and Login

	Usage:
		Select the database with the user in you want to map to, set the
		user name in the query & run.
	Useful for after a DB has been restored to a server, but the logins have had to be recreated
*/

EXEC sp_change_users_login 'AUTO_FIX', 'CommsManagerUser'