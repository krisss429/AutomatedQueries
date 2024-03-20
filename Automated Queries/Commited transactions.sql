SELECT   r1.session_id,
              r4.status,
              r6.status,
              CASE 
                      WHEN CAST(r6.blocking_session_id AS VARCHAR(6)) IS NULL OR CAST(r6.blocking_session_id AS VARCHAR(6)) = 0 THEN ' .'
                     ELSE CAST(r6.blocking_session_id AS VARCHAR(6))
              END BlockedBy,
         r4.login_name,
         r4.nt_domain,
         r4.nt_user_name,
         r5.TEXT,
         r1.internal_objects_alloc_page_count + r2.task_internal_objects_alloc_page_count     AS internal_objects_alloc_page_count,
         r1.internal_objects_dealloc_page_count + r2.task_internal_objects_dealloc_page_count AS internal_objects_dealloc_page_count,
         r1.user_objects_alloc_page_count + r2.task_user_objects_alloc_page_count             AS user_objects_alloc_page_count,
         r1.user_objects_dealloc_page_count + r2.task_user_objects_dealloc_page_count         AS user_objects_dealloc_page_count,
         r3.client_net_address,
         r4.host_name,
         r4.program_name,
         r4.last_request_start_time,
         r4.last_request_end_time,
         r4.login_time,
         r4.cpu_time,
         r4.memory_usage,
         r4.reads,
         r4.writes,
         r4.logical_reads,
         (SELECT Count(1)
          FROM   sys.dm_tran_session_transactions t1
          WHERE  t1.session_id = r1.session_id) AS open_transactions
FROM      sys.dm_db_session_space_usage AS r1
     JOIN (SELECT  session_id,
                   Sum(internal_objects_alloc_page_count)   AS task_internal_objects_alloc_page_count,
                   Sum(internal_objects_dealloc_page_count) AS task_internal_objects_dealloc_page_count,
                   Sum(user_objects_alloc_page_count)       AS task_user_objects_alloc_page_count,
                   Sum(user_objects_dealloc_page_count)     AS task_user_objects_dealloc_page_count
           FROM     sys.dm_db_task_space_usage
           WHERE    session_id > 50
           GROUP BY session_id) AS r2 ON r1.session_id = r2.session_id
     JOIN sys.dm_exec_connections r3 ON r3.most_recent_session_id = r2.session_id
       JOIN sys.dm_exec_sessions r4 ON r3.most_recent_session_id = r4.session_id
     OUTER APPLY sys.Dm_exec_sql_text(most_recent_sql_handle) r5
       LEFT JOIN sys.dm_exec_requests r6 ON r6.session_id = r4.session_id
WHERE     r1.session_id > 50
          AND r1.session_id <> @@SPID
              --AND r4.status NOT IN ('sleeping')
              --AND r6.status NOT IN ('sleeping')
              AND r4.login_name NOT LIKE '%alves%'
              AND text LIKE '%backup%'
              --AND program_name LIKE 'SAS%'
ORDER BY r1.session_id


