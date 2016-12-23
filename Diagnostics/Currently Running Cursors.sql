/*
	Currently Running Cursors
	Based on http://www.sqlskills.com/blogs/joe/hunting-down-the-origins-of-fetch-api_cursor-and-sp_cursorfetch/
*/

DECLARE @sessionId int = 0; /* 0 => all */

SELECT 
	c.session_id, 
	es.program_name, 
	es.login_name, 
	es.host_name, 
	c.properties, 
	c.creation_time, 
	c.is_open, 
	t.text
FROM sys.dm_exec_cursors (@sessionId) c
LEFT JOIN sys.dm_exec_sessions AS es ON c.session_id = es.session_id
CROSS APPLY sys.dm_exec_sql_text (c.sql_handle) t