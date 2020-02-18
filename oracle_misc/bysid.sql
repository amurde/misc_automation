select sid,serial#,username,status,machine,action,program from v$session where sid='&&1';
