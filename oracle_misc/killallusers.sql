select 'ALTER SYSTEM KILL SESSION '''||sid||','||serial#||''' IMMEDIATE;'
from v$session where machine like '%WORKGROUP%' or machine like '%SOME_MACHINE_NAME%';
