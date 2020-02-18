select sid,serial#,username,status,machine,action,program from v$session where username like '%&&1%';
