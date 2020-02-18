col job_name for A20
col status for A10
SELECT log_id, job_name, status, to_char(log_date,'YYYY.MM.DD HH24:MI') log_date, ERROR# FROM dba_scheduler_job_run_details
WHERE job_name like '%STAT%';
