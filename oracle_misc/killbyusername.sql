select 'ALTER SYSTEM KILL SESSION '''||sid||','||serial#||''' IMMEDIATE;'
from v$session where username like '%&&1%';
