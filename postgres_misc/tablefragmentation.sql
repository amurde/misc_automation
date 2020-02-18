SELECT nspname || '.' || relname AS "relation",
pg_size_pretty(pg_relation_size(C.oid)) AS "size"
,pg_size_pretty(pg_total_relation_size(C.oid)) AS "sizeWithIndexes"
,pg_stat_get_live_tuples(c.oid) AS LiveTuples
,pg_stat_get_dead_tuples(c.oid) AS DeadTuples
FROM pg_class C
LEFT JOIN pg_namespace N ON (N.oid = C.relnamespace)
WHERE nspname NOT IN ('pg_catalog', 'information_schema')
ORDER BY pg_relation_size(C.oid) DESC
LIMIT 50;
