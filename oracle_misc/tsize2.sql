SELECT  free.tablespace_name TABLESPACE, 
   ROUND(files.bytes / 1048576, 2) mb_total,
   ROUND((files.bytes - free.bytes)  / 1048576, 2) mb_used,      
   ROUND(free.bytes  / files.bytes * 100) || '%' "%FREE" 
   FROM
     (
   SELECT tablespace_name, SUM(bytes) bytes FROM dba_free_space
   GROUP BY tablespace_name
        ) free,
  (
    SELECT tablespace_name, SUM(bytes) bytes FROM dba_data_files 
    GROUP BY tablespace_name
    ) files
WHERE 
free.tablespace_name = files.tablespace_name;
