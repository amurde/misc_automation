-- *************************************************
-- Copyright © 2003 by Rampant TechPress
-- This script is free for non-commercial purposes
-- with no warranties.  Use at your own risk.
--
-- To license this script for a commercial purpose,
-- contact info@rampant.cc
-- *************************************************
-- A 100% score indicates no fragmentation at all. Lesser scores verify the presence of fragmentation.

select
   tablespace_name,       
   count(*) free_chunks,
   decode(
    round((max(bytes) / 1024000),2),
    null,0,
    round((max(bytes) / 1024000),2)) largest_chunk,
   nvl(round(sqrt(max(blocks)/sum(blocks))*(100/sqrt(sqrt(count(blocks)) )),2),
    0) fragmentation_index
from
   sys.dba_free_space 
group by 
   tablespace_name
order by 
    2 desc, 1;
