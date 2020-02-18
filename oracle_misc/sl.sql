column oracle_username format a15
column os_user_name format a15
column object_name format a37
column object_type format a37
select a.session_id,a.oracle_username, a.os_user_name, b.owner "OBJECT OWNER", b.object_name,b.object_type,a.locked_mode from
(select object_id, SESSION_ID, ORACLE_USERNAME, OS_USER_NAME, LOCKED_MODE from v$locked_object) a,
(select object_id, owner, object_name,object_type from dba_objects) b
where a.object_id=b.object_id;
