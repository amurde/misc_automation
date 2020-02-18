select * from (select owner,segment_name||'~'||partition_name segment_name,bytes/(1024*1024) size_m
  from dba_segments
  where tablespace_name = 'SYSAUX'
  ORDER BY BLOCKS desc)
  where rownum < 40;
