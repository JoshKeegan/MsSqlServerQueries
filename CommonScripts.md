## Commonly Used Scripts
Links to popular scripts that I've found useful.  
They are generally well maintained by their respective authors, so it doesn't make sense to include the code in this repo.

### Brent Ozar First Aid Pack
Contains:
- sp_Blitz (quickly flag up common problems, as well as suggesting some potential fixes)
- sp_BlitzIndex (index tuning - are any of the current indexes unused, too wide, redundant..?)
- sp_AskBrent (slow server - why is the server running slow right now? Points out obvious slow-downs happenning right now)

Plus others that I haven't used.  
  
Download: http://www.brentozar.com/first-aid/sql-server-downloads/  
Direct link: https://downloads.brentozar.com/FirstResponderKit.zip

### sp_WhoIsActive
What queries are running right now? What are they waiting on? And lots more info.  
When the Activity Monitor shows a huge spike in Waiting Tasks & you don't know what's causing it, this will tell you.

Download: http://sqlblog.com/files/default.aspx

### IndexOptimize
Ola Halengreen has a few scripts for DB maintenance, and the others may be worth looking at but the IndexOptimize makes
index maintenance quick and easy to set up.  
- Install stored procedures IndexOptimize & its dependency CommandExecute.  
- Create the CommandLog table.
- Use (from this repo) Maintenance/Index Maintenance.sql as a scheduled job (usually weekly in the early hours of Sunday morning, just after the daily backup finishes).
Note that offline index rebuilds are disabled. If you are comfortable with some indexes becoming unavailable whilst being rebuilt, or are not running Enterprise Edition on this server (in which case you don't have any choice) then turn on Offline Index rebuilds in Index Maintenance.sql.

Download: https://ola.hallengren.com/downloads.html

### Microsoft Tiger team Toolbox
The script toolbox for Microsoft's Tiger team.  
Of note:
- Fixing-VLFs/Fix_VLFs.sql

Github: https://github.com/Microsoft/tigertoolbox