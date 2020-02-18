-- This should accurately capture replication lag in bytes applied
SELECT pg_xlog_location_diff(pg_last_xlog_receive_location(), pg_last_xlog_replay_location())
    AS replication_delay_bytes;
