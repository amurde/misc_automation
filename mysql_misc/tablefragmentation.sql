select table_name,
round(data_length/1024/1024) as data_length_mb, 
round(data_free/1024/1024) as data_free_mb 
 from information_schema.tables 
 where round(data_free/1024/1024) > 500 
 order by data_free_mb;
