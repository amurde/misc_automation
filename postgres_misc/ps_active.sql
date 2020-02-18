select datname,pid,usename,application_name,client_addr,client_hostname,query_start,state,query from pg_stat_activity where state='active';
