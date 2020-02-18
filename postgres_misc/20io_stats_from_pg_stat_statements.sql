SELECT rolname,
    calls,
    round(total_time::numeric, 2) AS total,
    round((total_time / calls)::numeric, 2) AS per_call, -- millisec
    rows, -- fetched rows
    round(blk_read_time::numeric, 2) AS block_read_time, -- read time without shared caches
    regexp_replace(query, '[ \t\n]+', ' ', 'g') AS query_text
FROM pg_stat_statements
JOIN pg_roles r ON r.oid = userid
WHERE calls > 100
   AND rolname NOT LIKE '%replica%'
   AND rolname NOT LIKE '%rewind%'
-- ORDER BY total_time / calls DESC
order by block_read_time desc
LIMIT 20;
