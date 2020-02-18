SELECT * FROM (select username,opname,sid,serial#,context,sofar,totalwork,round(sofar/totalwork*100,2) "% Complete" from v$session_longops)
WHERE "% Complete" != 100;
