select application_name as server, state, sync_priority as priority, sync_state from pg_stat_replication;
