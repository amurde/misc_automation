COLUMN object_name FORMAT A30
SELECT owner,
       object_type,
       object_name,
       created,
       timestamp,
       generated,
       status
FROM   dba_objects
WHERE  status = 'INVALID'
ORDER BY owner, object_type, object_name;
